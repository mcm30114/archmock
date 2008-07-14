#import "CHMApplicationSettings.h"


@implementation CHMApplicationSettings

@synthesize applicationSupportFolderPath, bookmarksFilePath, recentDocumentsSettingsFilePath;
@synthesize bookmarks, recentDocumentsSettings;

- (id)init {
    if (self = [super init]) {
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
        self.recentDocumentsSettingsFilePath = [NSString stringWithFormat:@"%@/recent documents settings.binary",
                                                applicationSupportFolderPath];
    }
    
    return self;
}

- (void)load {
    [self loadBookmarks];
    [self loadRecentDocumentsSettings];
}

- (void)save {
    [self saveBookmarks];
    [self saveRecentDocumentsSettings];
}

- (void)loadBookmarks {
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

- (void)addBookmark:(CHMBookmark *)bookmark {
    [[self mutableArrayValueForKey:@"bookmarks"] addObject:bookmark];
}

- (void)saveBookmarks {
    if (![NSKeyedArchiver archiveRootObject:bookmarks 
                                     toFile:bookmarksFilePath]) {
        NSLog(@"ERROR: Can't save bookmarks into file '%@'", bookmarksFilePath);
    }
}

- (void)loadRecentDocumentsSettings {
    @try {
        self.recentDocumentsSettings = [NSKeyedUnarchiver unarchiveObjectWithFile:recentDocumentsSettingsFilePath];
    }
    @catch (NSException *e) {
        NSLog(@"ERROR: Can't open recent documents settings file '%@': %@", recentDocumentsSettingsFilePath, e);
    }
    @finally {
        if (nil == recentDocumentsSettings) {
            self.recentDocumentsSettings = [NSMutableDictionary dictionary];
        }
    }
}

- (void)addRecentSettingsForDocument:(CHMDocument *)document {
    CHMDocumentSettings *settings = [CHMDocumentSettings settingsWithCurrentSectionPath:document.currentSectionPath];
    [recentDocumentsSettings setObject:settings forKey:document.containerID];
}

- (void)saveRecentDocumentsSettings {
    if (![NSKeyedArchiver archiveRootObject:recentDocumentsSettings 
                                     toFile:recentDocumentsSettingsFilePath]) {
        NSLog(@"ERROR: Can't save recent documents settings into file '%@'", 
              recentDocumentsSettingsFilePath);
    }
}

- (void)dealloc {
    self.applicationSupportFolderPath = nil;
    self.bookmarksFilePath = nil;
    self.recentDocumentsSettingsFilePath = nil;
    
    self.bookmarks = nil;
    self.recentDocumentsSettings = nil;
    
    [super dealloc];
}

@end
