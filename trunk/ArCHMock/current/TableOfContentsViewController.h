#import "CHMSubViewController.h"
#import "CHMTableOfContents.h"
#import "CHMSection.h"

@interface TableOfContentsViewController : CHMSubViewController {
    IBOutlet NSTreeController *treeController;
}

@property (readonly) CHMTableOfContents *tableOfContents;

@end
