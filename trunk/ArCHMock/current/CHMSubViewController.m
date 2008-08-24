#import "CHMSubViewController.h"

@implementation CHMSubViewController

@synthesize isPerformingSync;
@dynamic chmDocument;

- (CHMDocument *)chmDocument {
    return (CHMDocument *)[self representedObject];
}

- (void)setRepresentedObject:(id)representedObject {
    [[self representedObject] removeObserver:self forKeyPath:@"currentSectionPath"];
    
    [super setRepresentedObject:representedObject];
    
    [self.chmDocument addObserver:self forKeyPath:@"currentSectionPath" options:NSKeyValueChangeSetting context:nil];
}

- (void)dealloc {
    [[self representedObject] removeObserver:self forKeyPath:@"currentSectionPath"];
    
    [super dealloc];
}


@end
