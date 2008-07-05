#import "ManagingViewController.h"


@implementation ManagingViewController

@synthesize managedObjectContext;

- (void)dealloc {
    managedObjectContext = nil;
    
    [super dealloc];
}

@end
