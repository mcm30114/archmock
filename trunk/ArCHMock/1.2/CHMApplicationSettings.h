#import <Cocoa/Cocoa.h>
#import "CHMBookmark.h"
#import "CHMDocumentSettings.h"
#import "CHMContentViewSettings.h"
#import "CHMDocumentWindowSettings.h"
#import "CHMDocument.h"

@interface CHMApplicationSettings : NSObject {
    CHMDocumentWindowSettings *lastDocumentWindowSettings;

    NSMutableArray *bookmarks;
    NSMutableDictionary *recentDocumentsSettings;
}

@property (retain) CHMDocumentWindowSettings *lastDocumentWindowSettings;

@property (retain) NSMutableArray *bookmarks;
@property (retain) NSMutableDictionary *recentDocumentsSettings;

- (void)load;
- (void)save;

- (void)loadBookmarksForVersion:(NSString *)version;
- (void)addBookmark:(CHMBookmark *)bookmark;
- (void)saveBookmarks;

- (void)loadRecentDocumentsSettingsForVersion:(NSString *)version;
- (void)addRecentSettingsForDocument:(CHMDocument *)document;
- (void)saveRecentDocumentsSettings;    

@end
