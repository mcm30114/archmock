#import "CHMApplicationDelegate.h"
#import "CHMURLProtocol.h"
#import "CHMDocumentController.h"

@implementation CHMApplicationDelegate

@synthesize settings;

+ (CHMApplicationSettings *)settings {
    CHMApplicationDelegate *delegate = (CHMApplicationDelegate *)[NSApp delegate];
    return delegate.settings;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {
    return YES;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [NSURLProtocol registerClass:[CHMURLProtocol class]];
    
    self.settings = [[CHMApplicationSettings new] autorelease];
    [settings load];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [NSURLProtocol unregisterClass:[CHMURLProtocol class]];
    
    [[CHMDocumentController sharedCHMDocumentController] saveSettingsForCurrentDocuments:self];
    [settings save];
}

- (void)dealloc {
    self.settings = nil;
    
    [super dealloc];
}

@end
