#import <Cocoa/Cocoa.h>


@interface CHMDocumentController : NSDocumentController {
    NSMutableDictionary *documentByContainerID;
    NSOperationQueue *operationQueue;
}

@property (retain) NSMutableDictionary *documentByContainerID;
@property (retain) NSOperationQueue *operationQueue;

+ (CHMDocumentController *)sharedCHMDocumentController;

@end
