#import "CHMToolbar.h"


@implementation CHMToolbar

- (void)validateVisibleItems {
    [super validateVisibleItems];
    
    for (NSToolbarItem *item in [self visibleItems]) {
        if (![item autovalidates]) {
            [item setEnabled:[windowController validateInterfaceItem:[item action]]];
        }
    }
}

- (NSToolbarSizeMode)sizeMode {
    return NSToolbarSizeModeRegular;
}

@end
