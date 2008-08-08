#import <Cocoa/Cocoa.h>


@interface ManagingViewController : NSViewController {
    NSManagedObjectContext *managedObjectContext;
}

@property (retain) NSManagedObjectContext *managedObjectContext;

@end
