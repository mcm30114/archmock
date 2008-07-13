#import "CHMBookmarksController.h"

@implementation CHMBookmarksController

- (BOOL)canRemove {
    return [[self selectedObjects] count] > 0;
}

@end
