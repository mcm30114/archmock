#import <Cocoa/Cocoa.h>
#import "CHMDocument.h"
#import "CHMBookmark.h"


@interface CHMDocumentController : NSDocumentController {
    NSOperationQueue *operationQueue;
    
    NSMutableDictionary *loadedDocumentByContainerID;

    NSWindowController *bookmarksWindowController;
    
    IBOutlet NSMenu *bookmarksMenu;
}

@property (retain) NSOperationQueue *operationQueue;

@property (retain) NSMutableDictionary *loadedDocumentByContainerID;

@property (retain) NSWindowController *bookmarksWindowController;

+ (CHMDocumentController *)sharedCHMDocumentController;

- (CHMDocument *)locateDocumentByContainerID:(NSString *)containerID;

- (IBAction)saveSettingsForCurrentDocuments:(id)sender;

- (IBAction)openBookmarksEditor:(id)sender;

@end
