#import "CHMWindowController.h"
#import "CHMBookmark.h"
#import "CHMDocumentController.h"

@implementation CHMWindowController

@dynamic isSidebarCollapsed;
@synthesize chmDocument;

@synthesize isSidebarCollapsing;
@synthesize tableOfContentsViewController, sectionContentViewController, searchViewController;


- (void)windowDidLoad {
    [super windowDidLoad];
    self.chmDocument = [self document];
    
    sectionContentViewController = [SectionContentViewController new];
    [sectionContentViewController setRepresentedObject:chmDocument];
    [contentView setContentView:[sectionContentViewController view]];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self 
                           selector:@selector(sectionContentLoaded:) 
                               name:@"SectionContentLoaded" 
                             object:sectionContentViewController];
    [chmDocument addObserver:self 
                  forKeyPath:@"currentSectionPath" 
                     options:NSKeyValueChangeSetting
                     context:nil];
    
    [notificationCenter addObserver:self 
                           selector:@selector(switchSidebarView:) 
                               name:@"SearchOperationStarted" 
                             object:chmDocument];
    [notificationCenter addObserver:self 
                           selector:@selector(switchSidebarView:) 
                               name:@"SearchCancelled" 
                             object:chmDocument];
    
    if (chmDocument.tableOfContents) {
        tableOfContentsViewController = [TableOfContentsViewController new];
        [tableOfContentsViewController setRepresentedObject:chmDocument];
        [sidebarView setContentView:[tableOfContentsViewController view]];
        
        [self showSidebarWithAnimation:NO];
    }
    else {
        [self hideSidebarWithAnimation:NO];
    }
    
    if (chmDocument.index) {
        searchViewController = [SearchViewController new];
        [searchViewController setRepresentedObject:chmDocument];
    }
    
    chmDocument.currentSectionPath = chmDocument.homeSectionPath;
    
    [self adjustSplitViewDivider];
}

- (void)setToggleSidebarButtonImage {
    NSString *imageName = self.isSidebarCollapsed ? @"ShowSidebar" : @"HideSidebar";
    NSImage *image = [NSImage imageNamed:imageName];
    if ([image isValid]) {
        [toggleSidebarButton setImage:image];
        [toggleSidebarButton setNeedsDisplay:YES];
    }
}

- (void)switchSidebarView:(NSNotification *)notification {
    if (nil == self.chmDocument.currentSearchQuery) {
        if (self.chmDocument.tableOfContents) {
            [self switchToTableOfContentsView];
        }
        else {
            [self hideSidebarWithAnimation:YES];
        }
    }
    else {
        [self switchToSearchResultsView];
        [self showSidebarWithAnimation:YES];
    }
}

- (BOOL)switchToSearchResultsView {
//    NSLog(@"DEBUG: Window controller: switching to search results view");
    NSView *searchResultsView = [searchViewController view];
    if ([sidebarView contentView] != searchResultsView) {
        [sidebarView setContentView:searchResultsView];
        
        return YES;
    }
    return NO;
}

- (BOOL)switchToTableOfContentsView {
//    NSLog(@"DEBUG: Window controller: switching to table of contents view");
    NSView *tableOfContentsView = [tableOfContentsViewController view];
    if ([sidebarView contentView] != tableOfContentsView) {
        [sidebarView setContentView:tableOfContentsView];
        
        return YES;
    }
    return NO;
}

- (IBAction)searchForText:(id)sender {
    NSString *text = [sender stringValue];
    [self.chmDocument searchForText:text];
}

- (IBAction)scrollToNextHighlight:(id)sender {
    [sectionContentViewController scrollToNextHighlight:sender];
}

- (IBAction)scrollToPreviousHighlight:(id)sender {
    [sectionContentViewController scrollToPreviousHighlight:sender];
}

- (IBAction)clearSearchText:(id)sender {
    [searchField setStringValue:@""];
    [self searchForText:searchField];
}

- (IBAction)activateSearch:(id)sender {
    [[self window] makeFirstResponder:searchField];
}

- (IBAction)makeTextLarger:(id)sender {
    return [sectionContentViewController.webView makeTextLarger:sender];
}

- (IBAction)makeTextStandardSize:(id)sender {
    return [sectionContentViewController.webView makeTextStandardSize:sender];
}

- (IBAction)makeTextSmaller:(id)sender {
    return [sectionContentViewController.webView makeTextSmaller:sender];
}

- (IBAction)goToHomeSection:(id)sender {
    self.chmDocument.currentSectionPath = self.chmDocument.homeSectionPath;
}

- (IBAction)goBack:(id)sender {
    [sectionContentViewController.webView goBack];
}

- (IBAction)goForward:(id)sender {
    [sectionContentViewController.webView goForward];
}

- (IBAction)goBackOrForward:(id)sender {
    int clickedSegment = [sender selectedSegment];
    if (0 == [[sender cell] tagForSegment:clickedSegment]) {
        return [self goBack:self];
    }
    else if (1 == [[sender cell] tagForSegment:clickedSegment]) {
        return [self goForward:self];
    }
}

- (IBAction)changeTextSize:(id)sender {
    int clickedSegment = [sender selectedSegment];
    if (0 == [[sender cell] tagForSegment:clickedSegment]) {
        return [self makeTextSmaller:self];
    }
    else if (1 == [[sender cell] tagForSegment:clickedSegment]) {
        return [self makeTextLarger:self];
    }
}

- (IBAction)addCurrentSectionToBookmarks:(id)sender {
    NSLog(@"DEBUG: Adding current section to bookmarks");
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item {
    return [self validateInterfaceItem:[item action]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    return [self validateInterfaceItem:[item action]];
}

- (BOOL)validateInterfaceItem:(SEL)action {
    if (@selector(makeTextLarger:) == action) {
        return [sectionContentViewController.webView canMakeTextLarger];
    }
    else if (@selector(makeTextSmaller:) == action) {
        return [sectionContentViewController.webView canMakeTextSmaller];
    }
    else if (@selector(makeTextStandardSize:) == action) {
        return [sectionContentViewController.webView canMakeTextStandardSize];
    }
    else if (@selector(goBack:) == action) {
        return [sectionContentViewController.webView canGoBack];
    }
    else if (@selector(goForward:) == action) {
        return [sectionContentViewController.webView canGoForward];
    }
    else if (@selector(scrollToNextHighlight:) == action || 
             @selector(scrollToPreviousHighlight:) == action) {
        return [sectionContentViewController canScrollBetweenHighlights];
    }
    else if (@selector(goBackOrForward:) == action) {
        BOOL goBackEnabled = [self validateInterfaceItem:@selector(goBack:)];
        BOOL goForwardEnabled = [self validateInterfaceItem:@selector(goForward:)];
        
        [goBackOrForwardControl setEnabled:goBackEnabled
                                forSegment:0];
        [goBackOrForwardControl setEnabled:goForwardEnabled 
                                forSegment:1];
        
        return goBackEnabled || goForwardEnabled;
    }
    else if (@selector(changeTextSize:) == action) {
        [changeTextSizeControl setEnabled:[self validateInterfaceItem:@selector(makeTextSmaller:)] 
                               forSegment:0];
        [changeTextSizeControl setEnabled:[self validateInterfaceItem:@selector(makeTextLarger:)] 
                               forSegment:1];
    }
    else if (@selector(goToHomeSection:) == action) {
        NSString *homeSectionPath = self.chmDocument.homeSectionPath;
        NSString *currentSectionPath =  self.chmDocument.currentSectionPath;
        BOOL isEnabled = nil != homeSectionPath && ![currentSectionPath isEqualToString:homeSectionPath];
        [goToHomeSectionButton setEnabled:isEnabled];

        return isEnabled;
    }
    else if (@selector(toggleSidebar:) == action) {
        CHMDocument *document = self.chmDocument;
        if (nil != document.index && nil != document.currentSearchQuery) {
            return YES;
        }
        
        if (nil != document.tableOfContents) {
            return YES;
        }
        
        return NO;
    }
    
    return YES;    
}

- (IBAction)toggleSidebar:(id)sender {
    self.isSidebarCollapsed ? [self showSidebarWithAnimation:YES] : [self hideSidebarWithAnimation:YES];
}

- (IBAction)printDocument:(id)sender {
    NSView *currentSectionView = [[[sectionContentViewController.webView mainFrame] frameView] documentView];
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:currentSectionView
                                                                      printInfo:[[self document] printInfo]];
    
    [printOperation setShowPanels:YES];
    // With modalPrintOperation "Print" button on toolbar won't unstick immediately 
//    [printOperation runOperation];
    
    [[self document] runModalPrintOperation:printOperation
                                   delegate:nil
                             didRunSelector:nil
                                contextInfo:nil];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    CHMDocument *document = self.chmDocument;
    NSString *title = document.container.title;
    if (nil != title && 0 != [title length]) {
        if (document.tableOfContents) {
            CHMSection *section = [document sectionByPath:document.currentSectionPath];
            if (section && section.label && [section.label length] > 0) {
                title = [NSString stringWithFormat:@"%@ - %@", section.label, title];
            }
        }
        title = [(NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, 
                                                                   (CFStringRef)title,
                                                                   NULL) autorelease];
        
        return title;
    }
    
    return displayName;
}

// SplitView delegate logic
#define SIDEBAR_MIN_WIDTH 200.0

- (void)showSidebarWithAnimation:(BOOL)animate {
    if ([splitView isSplitterAnimating] || !self.isSidebarCollapsed) {
        return;
    }
    
    float splitViewWidth = [splitView frame].size.width;
    float sidebarWidth = [[NSUserDefaults standardUserDefaults] floatForKey:@"sidebarWidth"];
    if (!sidebarWidth) {
        sidebarWidth = SIDEBAR_MIN_WIDTH;
    }
    
    [splitView setSplitterPosition:splitViewWidth - sidebarWidth
                           animate:animate];
}

- (void)hideSidebarWithAnimation:(BOOL)animate {
    if ([splitView isSplitterAnimating] || self.isSidebarCollapsed) {
        return;
    }
    
    self.isSidebarCollapsing = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:[sidebarView frame].size.width
                forKey:@"sidebarWidth"];
    [splitView setSplitterPosition:[splitView maxPossiblePositionOfDividerAtIndex:0] 
                           animate:animate];        
    
    self.isSidebarCollapsing = NO;
}

- (BOOL)isSidebarCollapsed {
    return ![self isSidebarCollapsing] && [sidebarView frame].size.width < SIDEBAR_MIN_WIDTH;
}

- (void)sectionContentLoaded:(NSNotification *)notification {
    [self synchronizeWindowTitleWithDocumentName];
    [self adjustSplitViewDivider];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == [self document] && [keyPath isEqualToString:@"currentSectionPath"]) {
        [self synchronizeWindowTitleWithDocumentName];
    }
}


- (void)adjustSplitViewDivider {
    splitView.dividerThickness = self.isSidebarCollapsed ? 0.0 : 1.0;
    [splitView adjustSubviews];
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin
         ofSubviewAt:(NSInteger)offset {
    return [splitView frame].size.width * 0.6;
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax 
         ofSubviewAt:(NSInteger)offset {
    return self.isSidebarCollapsing ? proposedMax : proposedMax - SIDEBAR_MIN_WIDTH - [splitView dividerThickness];
}

- (void)splitViewWillResizeSubviews:(NSNotification *)aNotification {
    [self adjustSplitViewDivider];
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
    if (![splitView isSplitterAnimating]) {
        [self adjustSplitViewDivider];
    }
}

//- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
//    // Don't interfere with animation.
//    if ([splitView isSplitterAnimating]) {
//        [sender setNeedsDisplay:YES];
//        return;
//    }
//    
//    // Do whatever else you want to do in this delegate.
//}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [chmDocument removeObserver:self 
                     forKeyPath:@"currentSectionPath"];

    self.chmDocument = nil;
    self.sectionContentViewController = nil;
    self.tableOfContentsViewController = nil;
    self.searchViewController = nil;
    
    [super dealloc];
}

@end
