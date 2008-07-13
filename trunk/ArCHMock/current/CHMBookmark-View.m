#import "CHMBookmark-View.h"


@implementation CHMBookmark (View)

@dynamic filePathColor;

- (NSColor *)filePathColor {
    return [self isValid] ? [NSColor textColor] : [NSColor redColor];
}

@end
