#import "CHMSection.h"


@implementation CHMSection

@synthesize label, path, parent, indexPath, children;

+ (CHMSection *)sectionWithLabel:(NSString *)initName 
                            path:(NSString *)initPath
                          parent:(CHMSection *)parentSection {
    return [[[CHMSection alloc] initWithLabel:initName 
                                        path:initPath
                                      parent:parentSection] autorelease];
}

- (id)initWithLabel:(NSString *)initLabel
               path:(NSString *)initPath
             parent:(CHMSection *)parentSection {
    if (self = [super init]) {
        self.label    = initLabel;
        self.path     = initPath;
        self.parent   = parentSection;
        self.children = [NSMutableArray array];
        
        if (parentSection) {
            self.indexPath = [parentSection.indexPath indexPathByAddingIndex:[parentSection.children count]];
            [parentSection.children addObject:self];
        }
        else {
            self.indexPath = [[NSIndexPath new] autorelease];
        }
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ Label: '%@', path: '%@', indexPath: %@", 
            [super description],
            label, 
            path, 
            indexPath];
}

- (void)dealloc {
    self.label    = nil;
    self.path     = nil;
    self.parent   = nil;
    self.children = nil;
    
    [super dealloc];
}

@end
