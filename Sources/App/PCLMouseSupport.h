#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSNotificationName const
PCLMouseAvailabilityDidChangeNotification;

BOOL PCLExternalMouseConnected(void);
void PCLStartMouseMonitoring(void);
