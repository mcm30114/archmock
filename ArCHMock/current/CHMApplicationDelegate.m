#import "CHMApplicationDelegate.h"
#import "CHMURLProtocol.h"

@implementation CHMApplicationDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [NSURLProtocol registerClass:[CHMURLProtocol class]];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [NSURLProtocol unregisterClass:[CHMURLProtocol class]];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

@end
