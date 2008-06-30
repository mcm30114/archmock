#import <Cocoa/Cocoa.h>
#import "CHMSubViewController.h"

@interface SearchViewController : CHMSubViewController {
    IBOutlet NSArrayController *tableController;
    IBOutlet NSTableView *tableView;
}

- (void)selectCurrentSectionAndRevealSearchResult:(BOOL)shouldRevealResult;

@end
