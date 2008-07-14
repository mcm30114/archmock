#import <Cocoa/Cocoa.h>
#import "CHMApplicationSettings.h"

@interface CHMApplicationDelegate : NSObject {
    CHMApplicationSettings *settings;
}

@property (retain) CHMApplicationSettings *settings;

+ (CHMApplicationSettings *)settings;

@end
