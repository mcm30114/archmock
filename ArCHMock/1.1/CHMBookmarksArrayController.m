#import "CHMBookmarksArrayController.h"

@implementation CHMBookmarksArrayController

- (BOOL)canRemove {
    return [[self selectedObjects] count] > 0;
}

@end
