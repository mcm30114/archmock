#import "CHMDocumentWindowController.h"
#import "CHMApplicationDelegate.h"
#import "CHMBookmark.h"
#import "CHMDocumentController.h"

@implementation CHMDocumentWindowController

@dynamic isSidebarCollapsed;
@synthesize chmDocument;

@synthesize isSidebarCollapsing;
@synthesize tableOfContentsViewController, sectionContentViewController, searchViewController;

#define SIDEBAR_MIN_WIDTH 200.0

- (float)sidebarWidth {
    if (nil == sidebarView) {
        return SIDEBAR_MIN_WIDTH;
    }
    
    return [sidebarView frame].size.width;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    self.chmDocument = [self document];

    CHMDocumentWindowSettings *windowSettings = self.chmDocument.windowSettings;
//    NSLog(@"DEBUG: DocumentWindowController: window settings: %@", windowSettings);
    
    BOOL sidebarShouldBeCollapsed = windowSettings.isSidebarCollapsed;

    [[self window] setFrame:windowSettings.frame 
                    display:NO
                    animate:NO];
    
    if (sidebarShouldBeCollapsed || nil == chmDocument.tableOfContents) {
        [self hideSidebarWithAnimation:NO];
    }
    else {
        [self showSidebarWithAnimation:NO];
    }
    
    [self adjustSplitViewDivider];
    
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
    
    if (nil != chmDocument.tableOfContents) {
        tableOfContentsViewController = [TableOfContentsViewController new];
        [tableOfContentsViewController setRepresentedObject:chmDocument];
        [sidebarView setContentView:[tableOfContentsViewController view]];
    }
    
    if (chmDocument.index) {
        searchViewController = [SearchViewController new];
        [searchViewController setRepresentedObject:chmDocument];
    }
}

- (void)updateWindowSettings {
    self.chmDocument.windowSettings.frame = [[self window] frame];
    if (![self isSidebarCollapsed] && ![self isSidebarCollapsing]) {
        self.chmDocument.windowSettings.sidebarWidth = [self sidebarWidth];
    }
    self.chmDocument.windowSettings.isSidebarCollapsed = [self isSidebarCollapsed];
}

- (void)windowDidResize:(NSNotification *)notification {
    [self updateWindowSettings];
    [self adjustSplitViewDivider];
}

- (void)windowDidMove:(NSNotification *)notification {
    [self updateWindowSettings];
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

    [toolbar validateVisibleItems];
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

- (IBAction)scrollContentWithOffset:(id)sender {
    [sectionContentViewController scrollContentWithOffset:sender];
}

- (IBAction)clearSearchText:(id)sender {
    [searchPatternField setStringValue:@""];
    [self searchForText:searchPatternField];
}

- (IBAction)activateSearch:(id)sender {
    [[self window] makeFirstResponder:searchPatternField];
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
- (IBAction)openAddCurrentSectionToBookmarksWindow:(id)sender {
    NSString *bookmarkLabel = [[self window] title];
    [bookmarkNameForCurrentSectionField setStringValue:bookmarkLabel];
    [bookmarkNameForCurrentSectionField selectText:self];
    
    [NSApp beginSheet:addCurrentSectionToBookmarksWindow 
       modalForWindow:[self window] 
        modalDelegate:nil 
       didEndSelector:NULL 
          contextInfo:NULL];
}

- (IBAction)closeAddCurrentSectionToBookmarksWindow:(id)sender {
    [NSApp endSheet:addCurrentSectionToBookmarksWindow];
    [addCurrentSectionToBookmarksWindow orderOut:sender];
}

- (IBAction)addCurrentSectionToBookmarks:(id)sender {
    [self closeAddCurrentSectionToBookmarksWindow:self];

    NSString *bookmarkLabel = [bookmarkNameForCurrentSectionField stringValue];
    
    CHMDocument *document = self.chmDocument;
    CHMDocumentSettings *settings = [CHMDocumentSettings settingsWithCurrentSectionPath:document.currentSectionPath
                                                                    sectionScrollOffset:document.currentSectionScrollOffset
                                                                         windowSettings:document.windowSettings];
    CHMBookmark *bookmark = [CHMBookmark bookmarkWithLabel:bookmarkLabel
                                                   filePath:[[document fileURL] relativePath]
                                              sectionLabel:document.currentSectionLabel
                                          documentSettings:settings];
    
    [[CHMApplicationDelegate settings] addBookmark:bookmark];
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

- (IBAction)printDocument:(id)sender {
    NSView *currentSectionView = [[[sectionContentViewController.webView mainFrame] frameView] documentView];
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:currentSectionView
                                                                      printInfo:[[self document] printInfo]];
    
    [printOperation setShowPanels:YES];
    [[self document] runModalPrintOperation:printOperation
                                   delegate:nil
                             didRunSelector:nil
                                contextInfo:nil];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    NSString *documentTitle = self.chmDocument.title;
    NSString *sectionLabel = self.chmDocument.currentSectionLabel;
    
    if (nil == documentTitle || [documentTitle length] == 0) {
        documentTitle = displayName;
    }
    
    NSString *windowTitle = nil != sectionLabel && [sectionLabel length] > 0 
                            ? [NSString stringWithFormat:@"%@ - %@", sectionLabel, documentTitle] 
                            : documentTitle;
    
    return [(NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, 
                                                              (CFStringRef)windowTitle,
                                                              NULL) autorelease];
}

// SplitView delegate logic
- (IBAction)toggleSidebar:(id)sender {
    self.isSidebarCollapsed ? [self showSidebarWithAnimation:YES] : [self hideSidebarWithAnimation:YES];
}

- (void)showSidebarWithAnimation:(BOOL)animate {
    if ([splitView isSplitterAnimating] || !self.isSidebarCollapsed) {
        return;
    }
    
    float splitViewWidth = [splitView frame].size.width;
    float sidebarWidth = self.chmDocument.windowSettings.sidebarWidth;
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
    
    [self updateWindowSettings];
    
    self.isSidebarCollapsing = YES;
    [splitView setSplitterPosition:[splitView maxPossiblePositionOfDividerAtIndex:0] 
                           animate:animate];        
    self.isSidebarCollapsing = NO;
}

- (BOOL)isSidebarCollapsed {
    return ![self isSidebarCollapsing] && [sidebarView frame].size.width < 1;
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

- (void)splitViewWillResizeSubviews:(NSNotification *)notification {
    [self adjustSplitViewDivider];
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    if (![splitView isSplitterAnimating]) {
        [self adjustSplitViewDivider];
        [self updateWindowSettings];
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
