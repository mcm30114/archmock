#import "CHMApplicationSettings.h"


@implementation CHMApplicationSettings

@synthesize lastDocumentWindowSettings;
@synthesize bookmarks;
@synthesize recentDocumentsSettings;

#define APPLICATIONS_SUPPORT_FOLDER @"~/Library/Application Support"

- (NSString *)applicationName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

- (NSString *)applicationVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (NSString *)applicationSupportFolderPathForVersion:(NSString *)version {
    if (nil == version) {
        version = [self applicationVersion];
    }
    return [[NSString stringWithFormat:@"%@/%@ %@", APPLICATIONS_SUPPORT_FOLDER, [self applicationName], version] stringByExpandingTildeInPath];
}

- (NSString *)bookmarksFilePathForVersion:(NSString *)version {
    return [NSString stringWithFormat:@"%@/bookmarks.binary", [self applicationSupportFolderPathForVersion:version]];
}

- (NSString *)recentDocumentsSettingsFilePathForVersion:(NSString *)version {
    return [NSString stringWithFormat:@"%@/recent documents settings.binary", [self applicationSupportFolderPathForVersion:version]];
}

static inline void migrateDocumentSettingsFromVersion1_1to1_2(CHMDocumentSettings *settings) {
    CHMContentViewSettings *contentViewSettings = [[CHMContentViewSettings new] autorelease];
    if (nil != settings.currentSectionScrollOffset) {
        contentViewSettings.scrollOffset = settings.currentSectionScrollOffset;
    }
    settings.contentViewSettings = contentViewSettings;
}

- (BOOL)migrate {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    NSString *previousVersion = @"1.1";
    if ([fileManager fileExistsAtPath:[self applicationSupportFolderPathForVersion:previousVersion] isDirectory:&isDirectory]
        && isDirectory) {
        NSLog(@"INFO: Migrating from version %@", previousVersion);
        [self loadBookmarksForVersion:previousVersion];
        [self loadRecentDocumentsSettingsForVersion:previousVersion];
        
        for (CHMBookmark *bookmark in bookmarks) {
            migrateDocumentSettingsFromVersion1_1to1_2(bookmark.documentSettings);
        }
        for (CHMDocumentSettings *settings in [recentDocumentsSettings allValues]) {
            migrateDocumentSettingsFromVersion1_1to1_2(settings);
        }
        
        NSError *error = nil;
        if (![fileManager moveItemAtPath:[self applicationSupportFolderPathForVersion:previousVersion] 
                             toPath:[self applicationSupportFolderPathForVersion:nil] 
                                   error:&error]) {
            self.bookmarks = nil;
            self.recentDocumentsSettings = nil;
            NSLog(@"ERROR: Couldn't migrate application from version %@. Please contact developer", previousVersion);
            return NO;
        }
        else {
            NSLog(@"INFO: Migration from version %@ has succeeded", previousVersion);
        }
        return YES;
    }
    
    return NO;
}

- (id)init {
    if (self = [super init]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirectory;
        if (![fileManager fileExistsAtPath:[self applicationSupportFolderPathForVersion:nil] isDirectory:&isDirectory] 
            || !isDirectory) {
            if (![self migrate]) {
                [fileManager createDirectoryAtPath:[self applicationSupportFolderPathForVersion:nil] attributes:nil];
            }
        }
    }
    
    return self;
}

- (void)load {
    [self loadBookmarksForVersion:nil];
    [self loadRecentDocumentsSettingsForVersion:nil];
    
    if (nil != lastDocumentWindowSettings) {
        return;
    }
    
    self.lastDocumentWindowSettings = [CHMDocumentWindowSettings settingsWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"lastDocumentWindowSettings"]];
    if (nil == lastDocumentWindowSettings) {
        lastDocumentWindowSettings = [CHMDocumentWindowSettings new];
    }
    
//    NSLog(@"DEBUG: Last document window settings: %@", lastDocumentWindowSettings);
}

- (void)save {
    [self saveBookmarks];
    [self saveRecentDocumentsSettings];
    
    [[NSUserDefaults standardUserDefaults] setObject:[self.lastDocumentWindowSettings data]
                                              forKey:@"lastDocumentWindowSettings"];
}

- (void)loadBookmarksForVersion:(NSString *)version {
    if (self.bookmarks) {
        return;
    }
    
    @try {
        self.bookmarks = [NSKeyedUnarchiver unarchiveObjectWithFile:[self bookmarksFilePathForVersion:version]];
    }
    @catch (NSException *e) {
        NSLog(@"ERROR: Can't open bookmarks file '%@' for app version '%@': %@", 
              [self bookmarksFilePathForVersion:version], version, e);
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
    if (![NSKeyedArchiver archiveRootObject:bookmarks toFile:[self bookmarksFilePathForVersion:nil]]) {
        NSLog(@"ERROR: Can't save bookmarks into file '%@'", [self bookmarksFilePathForVersion:nil]);
    }
}

- (void)loadRecentDocumentsSettingsForVersion:(NSString *)version {
    if (self.recentDocumentsSettings) {
        return;
    }
    
    @try {
        self.recentDocumentsSettings = [NSKeyedUnarchiver unarchiveObjectWithFile:[self recentDocumentsSettingsFilePathForVersion:nil]];
    }
    @catch (NSException *e) {
        NSLog(@"ERROR: Can't open recent documents settings file '%@' for app version '%@': %@", 
              [self recentDocumentsSettingsFilePathForVersion:nil], version, e);
    }
    @finally {
        if (nil == recentDocumentsSettings) {
            self.recentDocumentsSettings = [NSMutableDictionary dictionary];
        }
    }
}

- (void)addRecentSettingsForDocument:(CHMDocument *)document {
    CHMDocumentSettings *settings = [CHMDocumentSettings settingsWithCurrentSectionPath:document.currentSectionPath contentViewSettings:document.contentViewSettings windowSettings:document.windowSettings];
    settings.date = [NSDate date];
    
    [recentDocumentsSettings setObject:settings forKey:document.containerID];
    NSLog(@"DEBUG: Saved recent settings for document with title '%@': %@", [document title], settings);
    
    if (nil != document.tableOfContents) {
        self.lastDocumentWindowSettings = document.windowSettings;
    }
    else {
        self.lastDocumentWindowSettings.frame = document.windowSettings.frame;
    }
//    NSLog(@"DEBUG: Saved last document window settings: %@", self.lastDocumentWindowSettings);
}

- (void)saveRecentDocumentsSettings {
    if (![NSKeyedArchiver archiveRootObject:recentDocumentsSettings toFile:[self recentDocumentsSettingsFilePathForVersion:nil]]) {
        NSLog(@"ERROR: Can't save recent documents settings into file '%@'", [self recentDocumentsSettingsFilePathForVersion:nil]);
    }
}

- (void)dealloc {
    self.bookmarks = nil;
    self.recentDocumentsSettings = nil;
    
    self.lastDocumentWindowSettings = nil;
    
    [super dealloc];
}

@end
