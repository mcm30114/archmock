#import "SearchViewController.h"
#import "CHMSectionAccumulatedSearchResult.h"

@implementation SearchViewController

- (id) init {
    if (![self initWithNibName:@"SectionAccumulatedSearchResultsView" bundle:nil]) {
        return nil;
    }
    [self setTitle:@"Search Results"];

    return self;
}

- (void)awakeFromNib {
    NSData *sortDescriptorsData = [[NSUserDefaults standardUserDefaults] 
                                   objectForKey:@"SectionAccumulatedSearchResultsSortDescriptors"];
    if (sortDescriptorsData) {
        [tableView setSortDescriptors:[NSKeyedUnarchiver unarchiveObjectWithData:sortDescriptorsData]];
    }
    
    [tableController addObserver:self
                      forKeyPath:@"selectedObjects"
                         options:NSKeyValueChangeSetting
                         context:nil];
    [tableView addObserver:self 
                forKeyPath:@"sortDescriptors" 
                   options:NSKeyValueChangeSetting
                   context:nil];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self 
                           selector:@selector(disableRearrangement:) 
                               name:@"CurrentSearchResultsAboutToBeCleared" 
                             object:self.chmDocument];
    [notificationCenter addObserver:self 
                           selector:@selector(enableRearrangement:) 
                               name:@"CurrentSearchResultsCleared" 
                             object:self.chmDocument];
    [notificationCenter addObserver:self 
                           selector:@selector(disableRearrangement:)
                               name:@"AccumulatingSearchResultsAboutToBeProcessed" 
                             object:self.chmDocument];
    [notificationCenter addObserver:self 
                           selector:@selector(enableRearrangement:) 
                               name:@"AccumulatingSearchResultsProcessed" 
                             object:self.chmDocument];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (isPerformingSync) {
        return;
    }
    
    isPerformingSync = YES;
    if (object == [self representedObject]) {
        if ([keyPath isEqualToString:@"currentSectionPath"]) {
            [self selectCurrentSectionAndRevealSearchResult:YES];
        }
    }
    else if (object == tableController) {
        if ([keyPath isEqualToString:@"selectedObjects"]) {
            if ([[tableController selectedObjects] count] > 0) {
                CHMSectionAccumulatedSearchResult *selectedResult = [[tableController selectedObjects] lastObject];
                NSString *selectedSectionPath = selectedResult.sectionPath;
                if (![selectedSectionPath isEqualToString:self.chmDocument.currentSectionPath]) {
                    self.chmDocument.scrollToFirstHighlight = YES;
                    self.chmDocument.currentSectionPath = selectedSectionPath;
                }
            }
        }
    }
    else if (object == tableView) {
        if ([keyPath isEqualToString:@"sortDescriptors"]) {
            NSData *sortDescriptorsData = [NSKeyedArchiver archivedDataWithRootObject:[tableView sortDescriptors]];
            [[NSUserDefaults standardUserDefaults] setObject:sortDescriptorsData
                                                      forKey:@"SectionAccumulatedSearchResultsSortDescriptors"];
        }
    }
    isPerformingSync = NO;
}

- (void)selectCurrentSectionAndRevealSearchResult:(BOOL)shouldRevealResult {
    NSString *sectionPath = self.chmDocument.currentSectionPath;
    if (sectionPath) {
        CHMSectionAccumulatedSearchResult *result = [self.chmDocument.searchResultBySectionPath 
                                                     objectForKey:sectionPath];
        if (result) {
            if ([tableController setSelectedObjects:[NSArray arrayWithObject:result]]) {
                if (shouldRevealResult) {
                    int selectionIndex = [tableController selectionIndex];
                    [tableView scrollRowToVisible:selectionIndex];
                }
            }
        }
        else {
            [tableController setSelectedObjects:[NSArray array]];
        }
    }
    else {
        [tableController setSelectedObjects:[NSArray array]];
    }
}

- (void)disableRearrangement:(NSNotification *)notification {
    isPerformingSync = YES;
    [tableView setSortDescriptors:[NSArray array]];
    isPerformingSync = NO;
}

- (void)enableRearrangement:(NSNotification *)notification {
    NSData *sortDescriptorsData = [[NSUserDefaults standardUserDefaults] 
                                   objectForKey:@"SectionAccumulatedSearchResultsSortDescriptors"];
    if (sortDescriptorsData) {
        [tableView setSortDescriptors:[NSKeyedUnarchiver unarchiveObjectWithData:sortDescriptorsData]];
    }
    isPerformingSync = YES;
    [self selectCurrentSectionAndRevealSearchResult:NO];
    isPerformingSync = NO;
}

- (void)dealloc {
    [tableController removeObserver:self
                         forKeyPath:@"selectedObjects"];
    [tableView removeObserver:self 
                   forKeyPath:@"sortDescriptors"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

@end
