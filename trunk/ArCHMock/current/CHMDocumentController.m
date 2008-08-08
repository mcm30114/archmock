#import "CHMDocumentController.h"
#import "CHMDocumentSettings.h"
#import "CHMBookmark.h"
#import "CHMDocumentWindowSettings.h"
#import "CHMContentViewSettings.h"
#import "CHMApplicationDelegate.h"

@implementation CHMDocumentController

@synthesize loadedDocumentByContainerID;
@synthesize operationQueue;

@synthesize bookmarksWindowController;

- (CHMDocument *)locateDocumentByContainerID:(NSString *)containerID {
    CHMDocument *document = [loadedDocumentByContainerID objectForKey:containerID];
    if (nil != document) {
        return document;
    }
    
    for (CHMDocument *document in [self documents]) {
        if ([document.containerID isEqualToString:containerID]) {
            [loadedDocumentByContainerID setObject:document forKey:containerID];
            return document;
        }
    }
    return nil;
}

+ (CHMDocumentController *)sharedCHMDocumentController {
    return (CHMDocumentController *)[self sharedDocumentController];
}

- (NSUInteger)maximumRecentDocumentCount {
    return 20;
}

#define BOOKMARKS_MENU_SEPARATOR 2

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSMenuItem *separator = [menu itemWithTag:BOOKMARKS_MENU_SEPARATOR];
    NSArray *bookmarks = [CHMApplicationDelegate settings].bookmarks;
    
    [separator setHidden:0 == [bookmarks count]];
    while ([menu numberOfItems] > 3) {
        [menu removeItemAtIndex:3];
    }
    for (CHMBookmark *bookmark in bookmarks) {
        NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:bookmark.label action:@selector(openBookmark:) keyEquivalent:@""] autorelease];
        [item setEnabled:[bookmark isValid]];
        [item setRepresentedObject:bookmark];
        
        [menu addItem:item];
    }
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
    SEL action = [item action];
    if (@selector(openBookmarksEditor:) == action) {
        return [[CHMApplicationDelegate settings].bookmarks count] > 0;
    }
    
    return [super validateUserInterfaceItem:item];
}

- (id)init {
    if (self = [super init]) {
        operationQueue = [NSOperationQueue new];
        self.loadedDocumentByContainerID = [NSMutableDictionary dictionary];
        
    }
    
    return self;
}

- (IBAction)openBookmark:(id)sender {
    CHMBookmark *bookmark = (CHMBookmark *)[sender representedObject];
//    NSLog(@"DEBUG: Open Bookmark: %@", bookmark);
    
    NSString *filePath = [bookmark locateFile];
    NSString *fileURLString = [NSString stringWithFormat:@"file://%@", [filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *fileURL = [NSURL URLWithString:fileURLString];
    
    NSError *error = nil;
    CHMDocument *document = (CHMDocument *)[self documentForURL:fileURL];
    // Dcoument is already loaded
    if (nil != document) {
        document.contentViewSettingsToApply = bookmark.documentSettings.contentViewSettings;
        [super openDocumentWithContentsOfURL:fileURL display:YES error:&error];
        
        if ([document.currentSectionPath isEqualToString:bookmark.documentSettings.currentSectionPath]) {
            [NSApp sendAction:@selector(scrollContentWithSuppliedOffset:) to:nil from:self];
        }
        else {
            document.currentSectionPath = bookmark.documentSettings.currentSectionPath;
        }
        
        return;
    }
    
    document = (CHMDocument *)[super openDocumentWithContentsOfURL:fileURL display:NO error:&error];
    if (nil == document) {
        NSString *errorMessage = [NSString stringWithFormat:@"The bookmark “%@” could not be opened.", bookmark.label];
        //        NSLog(@"ERROR: %@", errorMessage);
        NSRunCriticalAlertPanel(errorMessage, @"", @"OK", nil, nil);
    }
    else {
        document.contentViewSettingsToApply = bookmark.documentSettings.contentViewSettings;
        document.windowInitialSettings = bookmark.documentSettings.windowSettings;
        
        [document makeWindowControllers];
        [document showWindows];
        
        document.currentSectionPath = bookmark.documentSettings.currentSectionPath;
    }
}

- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument error:(NSError **)outError {
    if (nil != [self documentForURL:absoluteURL]) {
        return [super openDocumentWithContentsOfURL:absoluteURL display:displayDocument error:outError];
    }
    
    CHMDocument *document = (CHMDocument *)[super openDocumentWithContentsOfURL:absoluteURL display:NO error:outError];
    
    if (nil != document) {
        CHMDocumentWindowSettings *initialWindowSettings = nil;
        CHMContentViewSettings *initialContentViewSettings = nil;
        NSString *currentSectionPath = nil;

        CHMDocumentSettings *documentRecentSettings = [[CHMApplicationDelegate settings].recentDocumentsSettings objectForKey:document.containerID];
        if (nil == documentRecentSettings) {
            currentSectionPath = document.homeSectionPath;
            initialWindowSettings = [CHMApplicationDelegate settings].lastDocumentWindowSettings;
//            NSLog(@"DEBUG: Could not find recent settings for document with title '%@'. Will use last document window settings: %@ and will open it with home section with path: '%@'", [document title], initialWindowSettings, currentSectionPath);
        }
        else {
            currentSectionPath = documentRecentSettings.currentSectionPath;
            initialWindowSettings = documentRecentSettings.windowSettings;
            initialContentViewSettings = documentRecentSettings.contentViewSettings;
        }
        
        document.windowInitialSettings = initialWindowSettings;
        document.contentViewSettingsToApply = initialContentViewSettings;
        
        if (displayDocument) {
            [document makeWindowControllers];
            [document showWindows];
        }

        document.currentSectionPath = currentSectionPath;
    }
    
    return document;
}

- (void)addDocument:(NSDocument *)document {
    CHMDocument *chmDocument = (CHMDocument *)document;
    [loadedDocumentByContainerID setObject:document forKey:chmDocument.containerID];
    
    [super addDocument:document];
}

- (void)saveSettingsForDocument:(NSDocument *)document {
    [[CHMApplicationDelegate settings] addRecentSettingsForDocument:(CHMDocument *)document];
}

- (void)removeDocument:(NSDocument *)document {
    CHMDocument *chmDocument = (CHMDocument *)document;
    [self saveSettingsForDocument:document];
    [loadedDocumentByContainerID removeObjectForKey:chmDocument.containerID];
    
    [super removeDocument:document];
}

- (IBAction)saveSettingsForCurrentDocuments:(id)sender {
    for (NSDocument *document in [self documents]) {
        [self saveSettingsForDocument:document];
    }
}

- (IBAction)openBookmarksEditor:(id)sender {
    if (nil == self.bookmarksWindowController) {
        self.bookmarksWindowController = [[[NSWindowController alloc] initWithWindowNibName:@"BookmarksEditor"] autorelease];
    }
    [self.bookmarksWindowController showWindow:self];
    [[self.bookmarksWindowController window] makeKeyWindow];
}

- (void)dealloc {
    self.loadedDocumentByContainerID = nil;
    self.operationQueue = nil;
    
    [super dealloc];
}

@end
