#import "PCLZipExtractor.h"
#include <compression.h>

// ZIP文件格式常量
static const uint32_t kZipLocalFileHeaderSignature = 0x04034b50;
static const uint32_t kZipCentralDirectorySignature = 0x02014b50;
static const uint32_t kZipEOCDSignature = 0x06054b50;
static const uint16_t kZipCompressionStored = 0;
static const uint16_t kZipCompressionDeflate = 8;

@implementation PCLZipExtractor

+ (BOOL)extractZipAtPath:(NSString *)zipPath toPath:(NSString *)destinationPath error:(NSError **)error {
    return [self extractZipAtPath:zipPath toPath:destinationPath progress:nil error:error];
}

+ (BOOL)extractZipAtPath:(NSString *)zipPath
                 toPath:(NSString *)destinationPath
               progress:(void (^)(NSString *, NSInteger, NSInteger))progressBlock
                  error:(NSError **)error {
    
    NSData *zipData = [NSData dataWithContentsOfFile:zipPath options:0 error:error];
    if (!zipData) {
        return NO;
    }
    
    const uint8_t *bytes = zipData.bytes;
    NSUInteger length = zipData.length;
    
    if (length < 22) {
        if (error) *error = [NSError errorWithDomain:@"PCLZipExtractor" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"文件太小，不是有效的ZIP"}];
        return NO;
    }
    
    // 查找中央目录结束标记 (EOCD)
    NSInteger eocdOffset = -1;
    for (NSInteger i = (NSInteger)length - 22; i >= 0 && i >= (NSInteger)length - 65557; i--) {
        if (i < 0) break;
        uint32_t sig;
        memcpy(&sig, bytes + i, 4);
        if (sig == kZipEOCDSignature) {
            eocdOffset = i;
            break;
        }
    }
    
    if (eocdOffset < 0) {
        if (error) *error = [NSError errorWithDomain:@"PCLZipExtractor" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"未找到ZIP中央目录结束标记"}];
        return NO;
    }
    
    // 解析EOCD
    uint32_t cdOffset, cdSize;
    uint16_t cdCount;
    memcpy(&cdCount, bytes + eocdOffset + 8, 2);
    memcpy(&cdSize, bytes + eocdOffset + 12, 4);
    memcpy(&cdOffset, bytes + eocdOffset + 16, 4);
    
    // 创建目标目录
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:destinationPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    // 遍历中央目录，列出所有文件
    NSInteger current = 0;
    NSInteger cdPos = (NSInteger)cdOffset;
    
    // 第一遍：收集文件信息
    NSMutableArray<NSDictionary *> *fileInfos = [NSMutableArray array];
    
    for (uint16_t i = 0; i < cdCount; i++) {
        if (cdPos + 46 > (NSInteger)length) break;
        
        uint32_t sig;
        memcpy(&sig, bytes + cdPos, 4);
        if (sig != kZipCentralDirectorySignature) break;
        
        uint16_t compression, fileNameLen, extraLen, commentLen;
        uint32_t localHeaderOffset, compressedSize, uncompressedSize;
        
        memcpy(&compression, bytes + cdPos + 10, 2);
        memcpy(&compressedSize, bytes + cdPos + 20, 4);
        memcpy(&uncompressedSize, bytes + cdPos + 24, 4);
        memcpy(&fileNameLen, bytes + cdPos + 28, 2);
        memcpy(&extraLen, bytes + cdPos + 30, 2);
        memcpy(&commentLen, bytes + cdPos + 32, 2);
        memcpy(&localHeaderOffset, bytes + cdPos + 42, 4);
        
        if (cdPos + 46 + fileNameLen > (NSInteger)length) break;
        
        NSString *fileName = [[NSString alloc] initWithBytes:bytes + cdPos + 46
                                                      length:fileNameLen
                                                    encoding:NSUTF8StringEncoding];
        
        [fileInfos addObject:@{
            @"fileName": fileName ?: @"",
            @"compression": @(compression),
            @"localHeaderOffset": @(localHeaderOffset),
            @"compressedSize": @(compressedSize),
            @"uncompressedSize": @(uncompressedSize)
        }];
        
        cdPos += 46 + fileNameLen + extraLen + commentLen;
    }
    
    // 第二遍：解压每个文件
    for (NSDictionary *info in fileInfos) {
        current++;
        
        NSString *fileName = info[@"fileName"];
        if (fileName.length == 0) continue;
        
        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressBlock(fileName, current, (NSInteger)fileInfos.count);
            });
        }
        
        uint16_t compression = [info[@"compression"] unsignedShortValue];
        uint32_t localHeaderOffset = [info[@"localHeaderOffset"] unsignedIntValue];
        uint32_t compressedSize = [info[@"compressedSize"] unsignedIntValue];
        uint32_t uncompressedSize = [info[@"uncompressedSize"] unsignedIntValue];
        
        // 检查是否是目录
        if ([fileName hasSuffix:@"/"]) {
            NSString *dirPath = [destinationPath stringByAppendingPathComponent:fileName];
            [fm createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
            continue;
        }
        
        // 读取Local File Header
        if ((NSInteger)localHeaderOffset + 30 > (NSInteger)length) continue;
        
        uint16_t lfhFileNameLen, lfhExtraLen;
        memcpy(&lfhFileNameLen, bytes + localHeaderOffset + 26, 2);
        memcpy(&lfhExtraLen, bytes + localHeaderOffset + 28, 2);
        
        uint32_t fileDataOffset = localHeaderOffset + 30 + lfhFileNameLen + lfhExtraLen;
        
        if ((NSInteger)(fileDataOffset + compressedSize) > (NSInteger)length) continue;
        
        // 提取文件
        NSString *destFilePath = [destinationPath stringByAppendingPathComponent:fileName];
        NSString *destDirPath = [destFilePath stringByDeletingLastPathComponent];
        [fm createDirectoryAtPath:destDirPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSData *fileData = nil;
        
        if (compression == kZipCompressionStored) {
            // 未压缩
            fileData = [NSData dataWithBytes:bytes + fileDataOffset length:compressedSize];
        } else if (compression == kZipCompressionDeflate && uncompressedSize > 0) {
            // deflate压缩，使用compression框架
            fileData = [self decompressDeflate:bytes + fileDataOffset
                                 compressedSize:compressedSize
                               uncompressedSize:uncompressedSize];
            if (!fileData && compressedSize > 0) {
                // 解压失败，尝试跳过
                NSLog(@"[PCLZipExtractor] 解压失败: %@", fileName);
                continue;
            }
        }
        
        if (fileData) {
            [fileData writeToFile:destFilePath atomically:YES];
        }
    }
    
    return YES;
}

// 使用Compression框架解压deflate数据
+ (NSData *)decompressDeflate:(const uint8_t *)compressedBytes
                compressedSize:(size_t)compressedSize
              uncompressedSize:(size_t)uncompressedSize {
    
    if (compressedSize == 0) {
        return [NSData data];
    }
    
    // 分配解压缓冲区
    size_t bufferSize = uncompressedSize > 0 ? uncompressedSize + 1 : compressedSize * 10;
    uint8_t *outBuffer = malloc(bufferSize);
    if (!outBuffer) return nil;
    
    // 使用compression_decode_buffer解压 (zlib/deflate格式)
    size_t decodedSize = compression_decode_buffer(
        outBuffer, bufferSize,
        compressedBytes, compressedSize,
        NULL,
        COMPRESSION_ZLIB
    );
    
    NSData *result = nil;
    if (decodedSize > 0) {
        result = [NSData dataWithBytes:outBuffer length:decodedSize];
    }
    
    free(outBuffer);
    return result;
}

@end
