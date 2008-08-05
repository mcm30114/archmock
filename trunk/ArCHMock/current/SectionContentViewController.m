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

- (void)awakeFromNib {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self 
                           selector:@selector(jumpToAnchorIfNeeded:) 
                               name:@"URLHandled" 
                             object:nil];
}

// TODO: Remove
- (void)jumpToAnchorIfNeeded:(NSNotification *)notification {
    if ([notification object] == self.chmDocument) {
//        NSURL *url = [[notification userInfo] objectForKey:@"url"];
//        NSString *fragment = [url fragment];
//        if (fragment) {
//            NSLog(@"DEBUG: URL handled: %@. Jumping to fragment: '%@'", url, [url fragment]);
//        }
    }
}

- (void)dealloc {
    [[self chmDocument] removeObserver:self 
                            forKeyPath:@"currentSearchQuery"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

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
    
    [self executeJavaScriptCode:librariesCode 
                 asynchronously:NO];
}

- (IBAction)scrollToNextHighlight:(id)sender {
    [self executeJavaScriptCode:@"highlighter.scrollToNextHighlight()"
                 asynchronously:YES];
}

- (IBAction)scrollToPreviousHighlight:(id)sender {
    [self executeJavaScriptCode:@"highlighter.scrollToPreviousHighlight()"
                 asynchronously:YES];
}

- (BOOL)canScrollBetweenHighlights {
    id response = [self executeJavaScriptCode:@"highlighter.canScrollBetweenHighlights()"
                               asynchronously:NO];
    
    return [response isKindOfClass:[NSNumber class]] && [response boolValue] == 1;
}

- (IBAction)scrollContentWithOffset:(id)sender {
//    NSLog(@"DEBUG: Scrolling content with offset");
    NSString *codeString = [NSString stringWithFormat:@"window.scrollTo.apply(window, %@);", 
                      self.chmDocument.currentSectionScrollOffset];
    [self executeJavaScriptCode:codeString 
                 asynchronously:YES];
}

- (void)highlightContentIfNeeded {
    CHMSearchQuery *query = [[self chmDocument] currentSearchQuery];
    if (query) {
//        NSLog(@"DEBUG: Highlighting content");
        NSString *searchString = [query.searchString stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
        [self executeJavaScriptCode:[NSString stringWithFormat:@"highlighter.highlight('%@')", searchString]
                     asynchronously:NO];

        if (self.chmDocument.scrollToFirstHighlight) {
            if (self.chmDocument.index) {
                self.chmDocument.scrollToFirstHighlight = NO;
            }
//            NSLog(@"DEBUG: Scheduling highlight scrolling");
            [self executeJavaScriptCode:@"highlighter.scheduleScrollingToHighlight()"
                         asynchronously:YES];
        }
    }
}

- (void)removeHighlights {
//    NSLog(@"DEBUG: Removing content highlights");
    
    [self executeJavaScriptCode:@"highlighter.removeHighlights()"
                 asynchronously:NO];
}

- (NSString *)executeJavaScriptCode:(NSString *)codeString 
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

    // TODO: Use exceptions try/catch
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
        
        
        if (.0 != self.chmDocument.textSizeMultiplierToSet) {
            [[self webView] setTextSizeMultiplier:self.chmDocument.textSizeMultiplierToSet];
            self.chmDocument.textSizeMultiplier = [[self webView] textSizeMultiplier];
            self.chmDocument.textSizeMultiplierToSet = .0;
        }
        
        // TODO: Refactor
        NSString *currentSectionScrollOffset = self.chmDocument.currentSectionScrollOffset;
        
        if (nil == currentSectionScrollOffset || [@"[0, 0]" isEqualToString:self.chmDocument.currentSectionScrollOffset]) {
            NSURL *sectionURL = [NSURL URLWithString:[self.webView mainFrameURL]];
            NSString *urlFragment = [sectionURL fragment];
            
            if (urlFragment) {
//                NSLog(@"DEBUG: Jumping to anchor: '%@'", urlFragment);
                NSString *jumpToAnchorCodeString = [NSString stringWithFormat:@"jumpToAnchor('%@');", urlFragment];
                
                [self executeJavaScriptCode:jumpToAnchorCodeString 
                             asynchronously:NO];
            }
        }
        else {
            [self scrollContentWithOffset:self];
        }

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
