#import <WebKit/WebKit.h>
#import "CHMSubViewController.h"

@interface SectionContentViewController : CHMSubViewController {
}

@property (readonly) WebView *webView;

- (IBAction)scrollToNextHighlight:(id)sender;
- (IBAction)scrollToPreviousHighlight:(id)sender;
- (IBAction)scrollContentWithOffset:(id)sender;
- (BOOL)canScrollBetweenHighlights;

- (NSString *)performJavaScriptCode:(NSString *)codeString 
                       asynchronously:(BOOL)asynchronously;

- (void)injectJavaScriptIntoContent;
- (void)highlightContentIfNeeded;
- (void)removeHighlights;

@end
