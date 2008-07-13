#import "CHMDocumentController.h"
#import "CHMDocument.h"
#import "CHMBookmark.h"


@implementation CHMDocumentController

@synthesize loadedDocumentByContainerID, operationQueue;
@synthesize applicationSupportFolderPath;
@synthesize bookmarksFilePath, bookmarks;

+ (CHMDocumentController *)sharedCHMDocumentController {
    return (CHMDocumentController *)[self sharedDocumentController];
}

- (NSUInteger)maximumRecentDocumentCount {
    return 20;
}

#define BOOKMARKS_MENU_SEPARATOR 2

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSMenuItem *separator = [menu itemWithTag:BOOKMARKS_MENU_SEPARATOR];
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
        return [bookmarks count] > 0;
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
    }
}

- (id)init {
    if (self = [super init]) {
        self.loadedDocumentByContainerID = [NSMutableDictionary dictionary];
        operationQueue = [NSOperationQueue new];
        
        NSDictionary *mainInfoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *applicationName = [mainInfoDictionary objectForKey:@"CFBundleName"];
        NSString *applicationVersion = [mainInfoDictionary objectForKey:@"CFBundleVersion"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        self.applicationSupportFolderPath = [[NSString stringWithFormat:@"~/Library/Application Support/%@ %@", 
                                              applicationName, 
                                              applicationVersion] stringByExpandingTildeInPath];
        BOOL isDirectory;
        if (![fileManager fileExistsAtPath:applicationSupportFolderPath 
                               isDirectory:&isDirectory] || !isDirectory) {
            [fileManager createDirectoryAtPath:applicationSupportFolderPath
                                    attributes:nil];
        }
        
        self.bookmarksFilePath = [NSString stringWithFormat:@"%@/bookmarks.binary", 
                                  applicationSupportFolderPath];
    }
    
    return self;
}

- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL 
                            display:(BOOL)displayDocument 
                              error:(NSError **)outError {
    CHMDocument *document = (CHMDocument *)[super openDocumentWithContentsOfURL:absoluteURL 
                                                                        display:displayDocument 
                                                                          error:outError];
    document.currentSectionPath = document.homeSectionPath;
    return document;
}

- (void)addDocument:(NSDocument *)document {
    CHMDocument *chmDocument = (CHMDocument *)document;
    [loadedDocumentByContainerID setObject:document 
                                    forKey:chmDocument.containerID];
    
    [super addDocument:document];
}

- (void)removeDocument:(NSDocument *)document {
    CHMDocument *chmDocument = (CHMDocument *)document;
    
    [loadedDocumentByContainerID removeObjectForKey:chmDocument.containerID];
    
    [super removeDocument:document];
}

- (IBAction)loadBookmarks:(id)sender {
    @try {
        self.bookmarks = [NSKeyedUnarchiver unarchiveObjectWithFile:bookmarksFilePath];
    }
    @catch (NSException *e) {
        NSLog(@"ERROR: Can't open bookmarks file '%@': %@", bookmarksFilePath, e);
    }
    @finally {
        if (nil == bookmarks) {
            self.bookmarks = [NSMutableArray array];
        }
    }
//    NSLog(@"DEBUG: Loaded bookmarks: %@", bookmarks);
}

- (IBAction)editBookmarks:(id)sender {
    [bookmarksWindow makeKeyAndOrderFront:sender];
}

- (IBAction)saveBookmarks:(id)sender {
    if (![NSKeyedArchiver archiveRootObject:bookmarks 
                                     toFile:bookmarksFilePath]) {
        NSLog(@"ERROR: Can't save bookmarks into file '%@'", bookmarksFilePath);
    }
}

- (void)addBookmark:(CHMBookmark *)bookmark {
    [[self mutableArrayValueForKey:@"bookmarks"] addObject:bookmark];
}

- (void)dealloc {
    self.loadedDocumentByContainerID = nil;
    self.operationQueue = nil;
    
    self.bookmarksFilePath = nil;
    self.bookmarks = nil;
    
    [super dealloc];
}

@end
