#import <Cocoa/Cocoa.h>


@interface CHMDocumentSplitView : NSSplitView {
    CGFloat dividerThickness;
    BOOL isSplitterAnimating;
}

@property CGFloat dividerThickness;
@property BOOL isSplitterAnimating;

- (void)setSplitterPosition:(float)newSplitterPosition 
                    animate:(BOOL)animate;

@end
