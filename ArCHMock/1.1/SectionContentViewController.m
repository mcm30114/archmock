#import <WebKit/WebKit.h>
#import "SectionContentViewController.h"
#import "CHMURLProtocol.h"
#import "CHMSearchQuery.h"
#import "CHMJavaScriptConsole.h"


@implementation SectionContentViewController

@dynamic webView;

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
    
    [[self chmDocument] addObserver:self 
                         forKeyPath:@"currentSearchQuery" 
                            options:NSKeyValueChangeSetting
                            context:nil];
}

- (void)dealloc {
    [[self chmDocument] removeObserver:self 
                            forKeyPath:@"currentSearchQuery"];
    [super dealloc];
}

// JavaScript extravaganza
static NSString *librariesCode = nil;
- (void)injectJavaScriptIntoContent {
    if (nil == librariesCode) {
        NSString *prototypeScriptPath = [[NSBundle mainBundle] pathForResource:@"prototype-1.6.0.2-scriptaculous-1.8.1-effects-shrinkvars" 
                                                                        ofType:@"js"];
        NSString *highlightScriptPath = [[NSBundle mainBundle] pathForResource:@"javascript-logic" 
                                                                        ofType:@"js"];
        
        librariesCode = [[NSString stringWithFormat:@"%@;%@", 
                          [NSString stringWithContentsOfFile:prototypeScriptPath], 
                          [NSString stringWithContentsOfFile:highlightScriptPath]] retain];
    }
    
    [self performJavaScriptCode:librariesCode 
                 asynchronously:NO];
}

- (IBAction)scrollToNextHighlight:(id)sender {
    [self performJavaScriptCode:@"highlighter.scrollToNextHighlight()"
                 asynchronously:YES];
}

- (IBAction)scrollToPreviousHighlight:(id)sender {
    [self performJavaScriptCode:@"highlighter.scrollToPreviousHighlight()"
                 asynchronously:YES];
}

- (BOOL)canScrollBetweenHighlights {
    id response = [self performJavaScriptCode:@"highlighter.canScrollBetweenHighlights()"
                               asynchronously:NO];
    
    return [response isKindOfClass:[NSNumber class]] && [response boolValue] == 1;
}

- (IBAction)scrollContentWithOffset:(id)sender {
    NSString *code = [NSString stringWithFormat:@"window.scrollTo.apply(window, %@);", 
                      self.chmDocument.currentSectionScrollOffset];
    [self performJavaScriptCode:code 
                 asynchronously:YES];
}

- (void)highlightContentIfNeeded {
    CHMSearchQuery *query = [[self chmDocument] currentSearchQuery];
    if (query) {
//        NSLog(@"DEBUG: Highlighting content");
        NSString *searchString = [query.searchString stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
        [self performJavaScriptCode:[NSString stringWithFormat:@"highlighter.highlight('%@')", searchString]
                     asynchronously:NO];

        if (self.chmDocument.scrollToFirstHighlight) {
            if (self.chmDocument.index) {
                self.chmDocument.scrollToFirstHighlight = NO;
            }
//            NSLog(@"DEBUG: Scheduling highlight scrolling");
            [self performJavaScriptCode:@"highlighter.scheduleScrollingToHighlight()"
                         asynchronously:YES];
        }
    }
}

- (void)removeHighlights {
//    NSLog(@"DEBUG: Removing content highlights");
    
    [self performJavaScriptCode:@"highlighter.removeHighlights()"
                 asynchronously:NO];
}

- (NSString *)performJavaScriptCode:(NSString *)codeString 
                     asynchronously:(BOOL)asynchronously {
    codeString = [NSString stringWithFormat:@"try { %@; } catch(e) { Logger.error(e.toString()); }", 
                  codeString];
    WebScriptObject *scriptObject = [[self webView] windowScriptObject];
    if (asynchronously) {
        codeString = [NSString stringWithFormat:@"setTimeout(function() { %@; }, 0);", codeString];
    }
    return [scriptObject evaluateWebScript:codeString];
}
// End of JavaScript extravaganza

- (void)notifyAboutCurrentContentChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SectionContentLoaded" 
                                                        object:self];
    
    if (isPerformingSync) {
        return;
    }
    
    isPerformingSync = YES;
    
    NSURL *sectionURL = [NSURL URLWithString:[self.webView mainFrameURL]];
    NSString *urlPath = [[[sectionURL path] substringFromIndex:1] 
                         stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (isPerformingSync) {
        return;
    }
    
    isPerformingSync = YES;

    // TODO: use exceptions try/catch
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

static CHMJavaScriptConsole *console = nil;

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    if (nil == console) {
        console = [CHMJavaScriptConsole new];
    }
//    NSLog(@"DEBUG: Finished load for frame");
    if (frame == [sender mainFrame]) {
//        NSLog(@"DEBUG: Injecting JavaScript into content");
        [[[self webView] windowScriptObject] setValue:console 
                                               forKey:@"console"];
        [[[self webView] windowScriptObject] setValue:self.chmDocument 
                                               forKey:@"chmDocument"];
        [self injectJavaScriptIntoContent];
//        NSLog(@"DEBUG: JavaScript injected");
        [self highlightContentIfNeeded];
        
        [self notifyAboutCurrentContentChange];
    }
}

- (void)webView:(WebView *)sender didChangeLocationWithinPageForFrame:(WebFrame *)frame {
//    NSLog(@"DEBUG: Changed location within page frame");
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

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
//    NSLog(@"DEBUG: decidePolicyForNavigationAction: %@", request);
    openExternalURL(listener, request);
}

- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation 
        request:(NSURLRequest *)request 
   newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener {
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

@end
