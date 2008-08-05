#import <WebKit/WebKit.h>
#import "CHMSubViewController.h"

@interface SectionContentViewController : CHMSubViewController {
    BOOL scheduleScrollingToHighlight;
}

@property (readonly) WebView *webView;
@property BOOL scheduleScrollingToHighlight;

- (IBAction)scheduleScrollingToHighlight:(id)sender;
- (IBAction)scrollToNextHighlight:(id)sender;
- (IBAction)scrollToPreviousHighlight:(id)sender;
- (IBAction)scrollContentWithSuppliedOffset:(id)sender;
- (IBAction)makeContentTextLarger:(id)sender;
- (IBAction)makeContentTextStandardSize:(id)sender;
- (IBAction)makeContentTextSmaller:(id)sender;

- (BOOL)canScrollBetweenHighlights;

- (NSString *)executeJavaScriptCode:(NSString *)codeString asynchronously:(BOOL)asynchronously;

- (void)injectJavaScriptIntoContent;
- (void)highlightContentIfNeeded;
- (void)removeHighlights;

@end
