#import "CHMApplicationDelegate.h"
#import "CHMURLProtocol.h"
#import "CHMDocumentController.h"

@implementation CHMApplicationDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {
    return YES;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [NSURLProtocol registerClass:[CHMURLProtocol class]];

    [[CHMDocumentController sharedCHMDocumentController] loadBookmarks:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [NSURLProtocol unregisterClass:[CHMURLProtocol class]];
    
    [[CHMDocumentController sharedCHMDocumentController] saveBookmarks:self];
}

@end
