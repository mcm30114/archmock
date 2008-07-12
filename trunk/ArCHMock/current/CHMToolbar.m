#import "CHMToolbar.h"


@implementation CHMToolbar

- (void)validateVisibleItems {
    [super validateVisibleItems];
    
    NSArray *items = [self visibleItems];
    for (int i = 0; i < [items count]; i++) {
        NSToolbarItem *item = [items objectAtIndex:i];
        if (![item autovalidates]) {
            [item setEnabled:[windowController validateInterfaceItem:[item action]]];
        }
    }
}

- (NSToolbarSizeMode)sizeMode {
    return NSToolbarSizeModeRegular;
}

@end
