#import <Cocoa/Cocoa.h>
#import "CHMDocument.h"

#import "CHMSection.h"
#import "CHMDocumentSplitView.h"
#import "TableOfContentsViewController.h";
#import "SectionContentViewController.h"
#import "SearchViewController.h"

@interface CHMWindowController : NSWindowController {
    CHMDocument *chmDocument;
    
    TableOfContentsViewController *tableOfContentsViewController;
    SectionContentViewController *sectionContentViewController;
    SearchViewController *searchViewController;
    
    BOOL isSidebarCollapsing;
    
    IBOutlet NSBox *contentView;
    IBOutlet NSBox *sidebarView;
    IBOutlet CHMDocumentSplitView *splitView;
    IBOutlet NSSearchField *searchField;
    IBOutlet NSToolbar *toolbar;
    IBOutlet NSSegmentedControl *goBackOrForwardControl;
    IBOutlet NSSegmentedControl *changeTextSizeControl;
    IBOutlet NSButton *goToHomeSectionButton;
    IBOutlet NSButton *toggleSidebarButton;
}

@property BOOL isSidebarCollapsing;
@property (readonly) BOOL isSidebarCollapsed;

@property (retain) CHMDocument *chmDocument;

@property (retain) TableOfContentsViewController *tableOfContentsViewController;
@property (retain) SectionContentViewController *sectionContentViewController;
@property (retain) SearchViewController *searchViewController;

- (IBAction)searchForText:(id)sender;
- (IBAction)scrollToNextHighlight:(id)sender;
- (IBAction)scrollToPreviousHighlight:(id)sender;

- (IBAction)activateSearch:(id)sender;
- (IBAction)toggleSidebar:(id)sender;
- (IBAction)clearSearchText:(id)sender;
- (IBAction)makeTextLarger:(id)sender;
- (IBAction)makeTextStandardSize:(id)sender;
- (IBAction)makeTextSmaller:(id)sender;
- (IBAction)changeTextSize:(id)sender;
- (IBAction)goToHomeSection:(id)sender;
- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;
- (IBAction)goBackOrForward:(id)sender;

- (BOOL)validateToolbarItem:(NSToolbarItem *)item;
- (BOOL)validateMenuItem:(NSMenuItem *)item;
- (BOOL)validateInterfaceItem:(SEL)action;

- (void)switchSidebarView:(NSNotification *)notification;
- (BOOL)switchToSearchResultsView;
- (BOOL)switchToTableOfContentsView;

- (void)showSidebarWithAnimation:(BOOL)animate;
- (void)hideSidebarWithAnimation:(BOOL)animate;
- (void)adjustSplitViewDivider;

@end
