#import <Cocoa/Cocoa.h>
#import "CHMContainer.h"
#import "CHMSection.h"


@interface CHMTableOfContents : NSObject {
    CHMSection *root;
    NSMutableDictionary *sectionsByPath;
}

@property (retain) CHMSection *root;
@property (retain) NSMutableDictionary *sectionsByPath;

+ (CHMTableOfContents *)tableOfContentsWithContainer:(CHMContainer *)container;

- (id)initWithContainer:(CHMContainer *)container;

@end
