#import <Cocoa/Cocoa.h>


@interface CHMSection : NSObject {
    NSString *label;
    NSString  *path;
    CHMSection *parent;
    NSIndexPath *indexPath;
    NSMutableArray *children;
}

@property (retain) NSString *label;
@property (retain) NSString *path;
@property (retain) CHMSection *parent;
@property (retain) NSIndexPath *indexPath;
@property (retain) NSMutableArray *children;

+ (CHMSection *)sectionWithLabel:(NSString *)initName path:(NSString *)initPath parent:(CHMSection *)parentSection;
- (id)initWithLabel:(NSString *)initName path:(NSString *)initPath parent:(CHMSection *)parentSection;

@end
