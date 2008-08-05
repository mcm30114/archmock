#import "CHMDocumentController.h"
#import "CHMDocumentSettings.h"
#import "CHMDocumentWindowSettings.h"
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
            [loadedDocumentByContainerID setObject:document 
                                            forKey:containerID];
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
        NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:bookmark.label 
                                                       action:@selector(openBookmark:) 
                                                keyEquivalent:@""] autorelease];
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

- (IBAction)openBookmark:(id)sender {
    CHMBookmark *bookmark = (CHMBookmark *)[sender representedObject];
//    NSLog(@"DEBUG: Open Bookmark: %@", bookmark);
    
    NSString *filePath = [bookmark locateFile];
    NSString *fileURLString = [NSString stringWithFormat:@"file://%@", 
                               [filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *fileURL = [NSURL URLWithString:fileURLString];
    
    NSError *error;
    if (nil != [self documentForURL:fileURL]) {
        CHMDocument *document = (CHMDocument *)[super openDocumentWithContentsOfURL:fileURL
                                                                            display:YES 
                                                                              error:&error];
        document.currentSectionScrollOffset = bookmark.documentSettings.currentSectionScrollOffset;
        if ([document.currentSectionPath isEqualToString:bookmark.documentSettings.currentSectionPath]) {
            [NSApp sendAction:@selector(scrollContentWithOffset:) to:nil from:self];
        }
        else {
            document.dontClearContentOffsetOnUnload = YES;
            document.currentSectionPath = bookmark.documentSettings.currentSectionPath;
        }
        
        return;
    }
    
    CHMDocument *document = (CHMDocument *)[super openDocumentWithContentsOfURL:fileURL
                                                                        display:NO
                                                                          error:&error];
    if (nil == document) {
        NSString *errorMessage = [NSString stringWithFormat:@"The bookmark “%@” could not be opened.", 
                                  bookmark.label];
//        NSLog(@"ERROR: %@", errorMessage);
        NSRunCriticalAlertPanel(errorMessage, @"", @"OK", nil, nil);
    }
    else {
        document.windowSettings = bookmark.documentSettings.windowSettings;
        [document makeWindowControllers];
        [document showWindows];
        document.textSizeMultiplierToSet = bookmark.documentSettings.textSizeMultiplier;
        document.currentSectionScrollOffset = bookmark.documentSettings.currentSectionScrollOffset;
        document.currentSectionPath = bookmark.documentSettings.currentSectionPath;
    }
}

- (id)init {
    if (self = [super init]) {
        operationQueue = [NSOperationQueue new];
        self.loadedDocumentByContainerID = [NSMutableDictionary dictionary];
        
    }
    
    return self;
}

- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL 
                            display:(BOOL)displayDocument 
                              error:(NSError **)outError {
    if (nil != [self documentForURL:absoluteURL]) {
        return [super openDocumentWithContentsOfURL:absoluteURL 
                                            display:displayDocument
                                              error:outError];
    }
    
    CHMDocument *document = (CHMDocument *)[super openDocumentWithContentsOfURL:absoluteURL 
                                                                        display:NO 
                                                                          error:outError];
    
    if (nil != document) {
        CHMDocumentSettings *settings = [[CHMApplicationDelegate settings].recentDocumentsSettings
                                         objectForKey:document.containerID];
        if (nil == settings) {
            settings = [CHMDocumentSettings settingsWithCurrentSectionPath:document.homeSectionPath
                                                       sectionScrollOffset:nil
                                                            windowSettings:[CHMApplicationDelegate settings].lastDocumentWindowSettings];
//            NSLog(@"DEBUG: Can not find document settings document with title '%@'. \
//Will use last document settings: %@", [document title], settings);
            
        }
        
        document.windowSettings = settings.windowSettings;
        
//        NSLog(@"DEBUG: Opening document '%@' with settings: %@", document.title, settings);
        if (displayDocument) {
            [document makeWindowControllers];
            [document showWindows];
        }
        
        document.textSizeMultiplierToSet = settings.textSizeMultiplier;
        document.currentSectionScrollOffset = settings.currentSectionScrollOffset;
        document.currentSectionPath = settings.currentSectionPath;
    }
    
    return document;
}

- (void)addDocument:(NSDocument *)document {
    CHMDocument *chmDocument = (CHMDocument *)document;
    [loadedDocumentByContainerID setObject:document 
                                    forKey:chmDocument.containerID];
    
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
        self.bookmarksWindowController = [[[NSWindowController alloc] 
                                           initWithWindowNibName:@"BookmarksEditor"] autorelease];
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
