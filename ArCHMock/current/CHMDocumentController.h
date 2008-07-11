#import <Cocoa/Cocoa.h>
#import "CHMBookmark.h"


@interface CHMDocumentController : NSDocumentController {
    NSMutableDictionary *loadedDocumentByContainerID;
    NSOperationQueue *operationQueue;
    
    NSString *applicationSupportFolderPath;
    
    NSMutableArray *bookmarks;
    NSString *bookmarksFilePath;
    
    IBOutlet NSArrayController *bookmarksController;
    IBOutlet NSWindow *bookmarksWindow;
}

@property (retain) NSMutableDictionary *loadedDocumentByContainerID;
@property (retain) NSOperationQueue *operationQueue;

@property (retain) NSMutableArray *bookmarks;
@property (retain) NSString *bookmarksFilePath;
@property (retain) NSString *applicationSupportFolderPath;

+ (CHMDocumentController *)sharedCHMDocumentController;

- (IBAction)loadBookmarks:(id)sender;
- (IBAction)editBookmarks:(id)sender;
- (IBAction)saveBookmarks:(id)sender;

- (void)addBookmark:(CHMBookmark *)bookmark;

@end
