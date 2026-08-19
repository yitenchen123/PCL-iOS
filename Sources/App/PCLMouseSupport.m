#import "PCLMouseSupport.h"
#import <GameController/GameController.h>

NSNotificationName const
PCLMouseAvailabilityDidChangeNotification =
    @"PCLMouseAvailabilityDidChangeNotification";

BOOL PCLExternalMouseConnected(void) {
    return [GCMouse mice].count > 0;
}

void PCLStartMouseMonitoring(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSNotificationCenter *c =
            NSNotificationCenter.defaultCenter;

        for (NSNotificationName name in @[
            GCMouseDidConnectNotification,
            GCMouseDidDisconnectNotification
        ]) {
            [c addObserverForName:name
                           object:nil
                            queue:NSOperationQueue.mainQueue
                       usingBlock:^(NSNotification *note) {
                [c postNotificationName:
                    PCLMouseAvailabilityDidChangeNotification
                                  object:nil];
            }];
        }
    });
}
