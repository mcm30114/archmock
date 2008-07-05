#import <Cocoa/Cocoa.h>
#import "CHMDocument.h"

@interface CHMSubViewController : NSViewController {
    BOOL isPerformingSync;
}

@property BOOL isPerformingSync;
@property (readonly) CHMDocument *chmDocument;

@end
