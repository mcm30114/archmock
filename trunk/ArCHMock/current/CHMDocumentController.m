#import "CHMDocumentController.h"
#import "CHMDocumentSettings.h"
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
    if (@selector(editBookmarks:) == action) {
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
    CHMDocument *document = (CHMDocument *)[super openDocumentWithContentsOfURL:fileURL
                                                                        display:YES
                                                                          error:&error];
    if (nil == document) {
        NSString *errorMessage = [NSString stringWithFormat:@"The bookmark “%@” could not be opened.", bookmark.label];
//        NSLog(@"ERROR: %@", errorMessage);
        NSRunCriticalAlertPanel(errorMessage, @"", @"OK", nil, nil);
    }
    else {
        document.currentSectionPath = bookmark.sectionPath;
//        NSLog(@"DEBUG: Window controllers: %@", [document windowControllers]);
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
    CHMDocument *document = (CHMDocument *)[super openDocumentWithContentsOfURL:absoluteURL 
                                                                        display:displayDocument 
                                                                          error:outError];
    if (nil != document) {
        CHMDocumentSettings *settings = [[CHMApplicationDelegate settings].recentDocumentsSettings objectForKey:document.containerID];
        if (nil != settings) {
            document.currentSectionPath = settings.currentSectionPath;
        }
        else {
            document.currentSectionPath = document.homeSectionPath;
        }
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
        self.bookmarksWindowController = [[[NSWindowController alloc] initWithWindowNibName:@"Bookmarks"] autorelease];
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
