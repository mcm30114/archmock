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

- (id)init {
    if (self = [super init]) {
        self.loadedDocumentByContainerID = [NSMutableDictionary dictionary];
        operationQueue = [NSOperationQueue new];
        NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
        //    NSLog(@"DEBUG: Application name: '%@'", applicationName);
        NSFileManager *fileManager = [NSFileManager defaultManager];
        self.applicationSupportFolderPath = [[NSString stringWithFormat:@"~/Library/Application Support/%@", applicationName] stringByExpandingTildeInPath];
        BOOL isDirectory;
        if (![fileManager fileExistsAtPath:applicationSupportFolderPath 
                               isDirectory:&isDirectory] || !isDirectory) {
            [fileManager createDirectoryAtPath:applicationSupportFolderPath attributes:nil];
        }
        
        self.bookmarksFilePath = [NSString stringWithFormat:@"%@/bookmarks.data", applicationSupportFolderPath];
    }
    
    return self;
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
    NSLog(@"DEBUG: Loaded bookmarks: %@", bookmarks);
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

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
    SEL action = [item action];
    if (@selector(editBookmarks:) == action) {
        return [bookmarks count] > 0;
    }
    
    return [super validateUserInterfaceItem:item];
}

- (void)dealloc {
    self.loadedDocumentByContainerID = nil;
    self.operationQueue = nil;
    
    self.bookmarksFilePath = nil;
    self.bookmarks = nil;
    
    [super dealloc];
}

@end
