#import <WebKit/WebKit.h>
#import "SectionContentViewController.h"
#import "CHMURLProtocol.h"
#import "CHMSearchQuery.h"
#import "CHMJavaScriptConsole.h"
#import "CHMContentViewSettings.h"


@implementation SectionContentViewController

@dynamic webView;
@synthesize scheduleScrollingToHighlight;

- (WebView *)webView {
    return (WebView *)[self view];
}

- (id)init {
    if (![super initWithNibName:@"ContentView" bundle:nil]) {
        return nil;
    }
    [self setTitle:@"Content View"];
    
    return self;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    [[self chmDocument] addObserver:self forKeyPath:@"currentSearchQuery" options:NSKeyValueChangeSetting context:nil];
}

// JavaScript extravaganza
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
    if (selector == @selector(contentScrolled:)) {
        return NO;
    }
    return YES;
}

+ (NSString *)webScriptNameForSelector:(SEL)selector {
    if (@selector(contentScrolled:)) {
        return @"contentScrolled";
    }
    return nil;
}

static CHMJavaScriptConsole *console = nil;
- (void)publishExternalObjectsInJavaScriptEnvironment {
    WebScriptObject *scriptObject = [[self webView] windowScriptObject];
    if (nil == console) {
        console = [CHMJavaScriptConsole new];
    }
    
    [scriptObject setValue:console forKey:@"console"];
    [scriptObject setValue:self forKey:@"contentViewController"];
}

- (void)contentScrolled:(NSString *)scrollOffset {
//    NSLog(@"DEBUG: Scroll offset: %@", scrollOffset);
    self.chmDocument.contentViewSettings.scrollOffset = scrollOffset;
}

- (void)updateScrollOffsetSetting {
    [self executeJavaScriptCode:@"updateControllerScrollOffsetSetting()" asynchronously:YES];
}

static NSString *librariesCode = nil;
- (void)injectJavaScriptIntoContent {
    if (nil == librariesCode) {
        NSString *prototypeScriptPath = [[NSBundle mainBundle] pathForResource:@"prototype-1.6.0.2-scriptaculous-1.8.1-effects-shrinkvars" ofType:@"js"];
        NSString *highlightScriptPath = [[NSBundle mainBundle] pathForResource:@"javascript-logic" ofType:@"js"];
        
        librariesCode = [[NSString stringWithFormat:@"%@;%@", [NSString stringWithContentsOfFile:prototypeScriptPath], [NSString stringWithContentsOfFile:highlightScriptPath]] retain];
    }
    
    [self executeJavaScriptCode:librariesCode asynchronously:NO];
}

- (IBAction)scheduleScrollingToHighlight:(id)sender {
    self.scheduleScrollingToHighlight = YES;
}

- (IBAction)scrollToNextHighlight:(id)sender {
    [self executeJavaScriptCode:@"highlighter.scrollToNextHighlight()" asynchronously:YES];
}

- (IBAction)scrollToPreviousHighlight:(id)sender {
    [self executeJavaScriptCode:@"highlighter.scrollToPreviousHighlight()" asynchronously:YES];
}

- (void)updateContentTextSizeMultiplierSetting {
    //    NSLog(@"DEBUG: textSizeMultiplier: %f", textSizeMultiplier);
    float textSizeMultiplier = [[self webView] textSizeMultiplier];
    self.chmDocument.contentViewSettings.textSizeMultiplier = textSizeMultiplier;
}

- (IBAction)makeContentTextLarger:(id)sender {
    [[self webView] makeTextLarger:sender];
    [self updateContentTextSizeMultiplierSetting];
}

- (IBAction)makeContentTextStandardSize:(id)sender {
    [[self webView] makeTextStandardSize:sender];
    [self updateContentTextSizeMultiplierSetting];
}

- (IBAction)makeContentTextSmaller:(id)sender {
    [[self webView] makeTextSmaller:sender];
    [self updateContentTextSizeMultiplierSetting];
}

- (BOOL)canScrollBetweenHighlights {
    id response = [self executeJavaScriptCode:@"highlighter.canScrollBetweenHighlights()" asynchronously:NO];
    return [response isKindOfClass:[NSNumber class]] && [response boolValue] == 1;
}

- (IBAction)scrollContentWithSuppliedOffset:(id)sender {
    NSString *scrollOffset = self.chmDocument.contentViewSettingsToApply.scrollOffset;
    NSLog(@"DEBUG: Scrolling content with offset from chmDocument.contentViewSettingsToApply: '%@'", scrollOffset);
    NSString *codeString = [NSString stringWithFormat:@"window.scrollTo.apply(window, %@);", scrollOffset];
    [self executeJavaScriptCode:codeString asynchronously:YES];
}

- (void)highlightContentIfNeeded {
    CHMSearchQuery *query = [[self chmDocument] currentSearchQuery];
    if (query) {
        NSLog(@"DEBUG: Highlighting content");
        NSString *searchString = [query.searchString stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
        [self executeJavaScriptCode:[NSString stringWithFormat:@"highlighter.highlight('%@')", searchString] asynchronously:NO];
        if (self.scheduleScrollingToHighlight) {
            [self executeJavaScriptCode:@"highlighter.scheduleScrollingToHighlight()" asynchronously:YES];
            self.scheduleScrollingToHighlight = NO;
        }
    }
}

- (void)removeHighlights {
//    NSLog(@"DEBUG: Removing content highlights");
    
    [self executeJavaScriptCode:@"highlighter.removeHighlights()" asynchronously:NO];
}

- (NSString *)executeJavaScriptCode:(NSString *)codeString asynchronously:(BOOL)asynchronously {
    codeString = [NSString stringWithFormat:@"try { %@; } catch(e) { Logger.error(e.toString()); }", codeString];
    WebScriptObject *scriptObject = [[self webView] windowScriptObject];
    if (asynchronously) {
        codeString = [NSString stringWithFormat:@"setTimeout(function() { %@; }, 0);", codeString];
    }
    return [scriptObject evaluateWebScript:codeString];
}
// End of JavaScript extravaganza

- (void)notifyAboutCurrentContentChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SectionContentLoaded" object:self];
    
    if (isPerformingSync) {
        return;
    }
    
    isPerformingSync = YES;
    
    NSURL *sectionURL = [NSURL URLWithString:[self.webView mainFrameURL]];
    NSString *urlPath = [[[sectionURL path] substringFromIndex:1] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlFragment = [sectionURL fragment];
    
    CHMDocument *chmDocument = self.chmDocument;
    CHMSection *section = nil;
    
    if (urlFragment) {
        NSString *urlPathWithFragment = [NSString stringWithFormat:@"%@#%@", urlPath, urlFragment];
        section = [chmDocument locateSectionByPath:urlPathWithFragment];
    }
    if (!section) {
        section = [chmDocument locateSectionByPath:urlPath];
    }
    
    NSString *path = section ? section.path : urlPath;
    chmDocument.currentSectionPath = path;
    
    isPerformingSync = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (isPerformingSync) {
        return;
    }
    
    isPerformingSync = YES;

    if (object == self.chmDocument) {
        if ([keyPath isEqualToString:@"currentSectionPath"]) {
            NSString *path = self.chmDocument.currentSectionPath;
            
            if (path) {
                [self.webView setMainFrameURL:[self.chmDocument.container constructURLForObjectWithPath:path]];
            }
        }
        else if ([keyPath isEqualToString:@"currentSearchQuery"]) {
            if (nil != [[self chmDocument] currentSearchQuery]) {
                [self removeHighlights];
                [self highlightContentIfNeeded];
            }
            else {
                [self removeHighlights];
            }
        }
    }
    
    isPerformingSync = NO;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
//    NSLog(@"DEBUG: Finished load for frame");
    if (frame == [sender mainFrame]) {
        [self publishExternalObjectsInJavaScriptEnvironment];
        [self injectJavaScriptIntoContent];
        [self updateScrollOffsetSetting];
        
        [self highlightContentIfNeeded];
        
        if (nil != self.chmDocument.contentViewSettingsToApply) {
            float textSizeMultiplier = self.chmDocument.contentViewSettingsToApply.textSizeMultiplier;
//            NSLog(@"DEBUG: Setting content text size multiplier: %f", textSizeMultiplier);
            [[self webView] setTextSizeMultiplier:textSizeMultiplier];
            [self updateContentTextSizeMultiplierSetting];
            
            [self scrollContentWithSuppliedOffset:self];
            
            self.chmDocument.contentViewSettingsToApply = nil;
        }
        
        [self notifyAboutCurrentContentChange];
    }
}

- (void)webView:(WebView *)sender didChangeLocationWithinPageForFrame:(WebFrame *)frame {
    NSLog(@"DEBUG: Changed location within page frame");
    [self notifyAboutCurrentContentChange];
}

static inline void openExternalURL(id<WebPolicyDecisionListener> listener, NSURLRequest *request) {
    if ([CHMURLProtocol canInitWithRequest:request]) {
        [listener use];
    } 
    else {
//        NSLog(@"INFO: Opening external URL: '%@'", [request URL]);
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
        [listener ignore];
    }
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
//    NSLog(@"DEBUG: decidePolicyForNavigationAction: %@", request);
    openExternalURL(listener, request);
}

- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener {
//    NSLog(@"DEBUG: decidePolicyForNewWindowAction: %@", request);
    openExternalURL(listener, request);
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element
    defaultMenuItems:(NSArray *)defaultMenuItems {
    NSURL *url = [element objectForKey:WebElementLinkURLKey];
    
    if (url && [CHMURLProtocol canInitWithRequest:[NSURLRequest requestWithURL:url]]) {
        return nil;
    }
    
    return defaultMenuItems;
}

- (void)dealloc {
    [[self chmDocument] removeObserver:self forKeyPath:@"currentSearchQuery"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}
@end
