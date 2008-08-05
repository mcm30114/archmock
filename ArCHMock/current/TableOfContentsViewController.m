#import "TableOfContentsViewController.h"

@implementation TableOfContentsViewController

@dynamic tableOfContents;

- (CHMTableOfContents *)tableOfContents {
    return self.chmDocument.tableOfContents;
}

- (id)init {
    if (![super initWithNibName:@"TableOfContentsView" bundle:nil]) {
        return nil;
    }

    [self setTitle:@"Table of Contents"];
    
    return self;
}

- (void)selectSectionInTableOfContentsTree:(NSString *)sectionPath {
    CHMSection *section = [self.chmDocument locateSectionByPath:sectionPath]; 
    NSIndexPath *currentSelectionIndexPath = [treeController selectionIndexPath];
    if (!section && currentSelectionIndexPath) {
        [treeController removeSelectionIndexPaths:[NSArray arrayWithObject:currentSelectionIndexPath]];
    }
    else if (currentSelectionIndexPath != section.indexPath) {
//        NSLog(@"INFO: Selecting section in table of contents: %@", section);
        [treeController setSelectionIndexPath:section.indexPath];
    }
}

- (void)awakeFromNib {
    [treeController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueChangeSetting context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (isPerformingSync) {
        return;
    }
    
    isPerformingSync = YES;
    // TODO: use exceptions try/catch
    if (object == [self representedObject] && [keyPath isEqualToString:@"currentSectionPath"]) {
        [self selectSectionInTableOfContentsTree:self.chmDocument.currentSectionPath];
    }
    else if (object == treeController) {
        CHMSection *selectedSection = [[treeController selectedObjects] lastObject];
//        NSLog(@"INFO: Section is selected in table of contents: %@", selectedSection);
        
        self.chmDocument.currentSectionPath = selectedSection.path;
    }
    isPerformingSync = NO;
}

- (void)dealloc {
    [treeController removeObserver:self forKeyPath:@"selectedObjects"];

    [super dealloc];
}

@end
