#import <Cocoa/Cocoa.h>
#import "CHMBookmark.h"
#import "CHMDocumentSettings.h"
#import "CHMDocumentWindowSettings.h"
#import "CHMDocument.h"

@interface CHMApplicationSettings : NSObject {
    NSString *applicationSupportFolderPath;
    NSString *bookmarksFilePath;
    NSString *recentDocumentsSettingsFilePath;
    
    CHMDocumentWindowSettings *lastDocumentWindowSettings;

    NSMutableArray *bookmarks;
    NSMutableDictionary *recentDocumentsSettings;
}

@property (retain) NSString *applicationSupportFolderPath;
@property (retain) NSString *bookmarksFilePath;
@property (retain) NSString *recentDocumentsSettingsFilePath;

@property (retain) CHMDocumentWindowSettings *lastDocumentWindowSettings;

@property (retain) NSMutableArray *bookmarks;
@property (retain) NSMutableDictionary *recentDocumentsSettings;

- (void)load;
- (void)save;

- (void)loadBookmarks;
- (void)addBookmark:(CHMBookmark *)bookmark;
- (void)saveBookmarks;

- (void)loadRecentDocumentsSettings;
- (void)addRecentSettingsForDocument:(CHMDocument *)document;
- (void)saveRecentDocumentsSettings;    

@end
