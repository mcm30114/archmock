#import <WebKit/WebKit.h>
#import "CHMSubViewController.h"

@interface SectionContentViewController : CHMSubViewController {
    BOOL shouldScheduleScrollingToHighlight;
}

@property (readonly) WebView *webView;
@property BOOL shouldScheduleScrollingToHighlight;

- (IBAction)scheduleScrollingToHighlight:(id)sender;
- (IBAction)scrollToNextHighlight:(id)sender;
- (IBAction)scrollToPreviousHighlight:(id)sender;
- (IBAction)scrollContentWithSuppliedOffset:(id)sender;
- (IBAction)makeContentTextLarger:(id)sender;
- (IBAction)makeContentTextStandardSize:(id)sender;
- (IBAction)makeContentTextSmaller:(id)sender;

- (BOOL)canScrollBetweenHighlights;

- (void)close;

@end
