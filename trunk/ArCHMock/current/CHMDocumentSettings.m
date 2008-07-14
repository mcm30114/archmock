#import "CHMDocumentSettings.h"


@implementation CHMDocumentSettings

@synthesize currentSectionPath;

+ (CHMDocumentSettings *)settingsWithCurrentSectionPath:(NSString *)currentSectionPath {
    return [[[CHMDocumentSettings alloc] initWithCurrentSectionPath:currentSectionPath] autorelease];
}

- (id)initWithCurrentSectionPath:(NSString *)initCurrentSectionPath {
    if (self = [super init]) {
        self.currentSectionPath = initCurrentSectionPath;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    [super init];
    
    self.currentSectionPath = [coder decodeObjectForKey:@"currentSectionPath"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:currentSectionPath forKey:@"currentSectionPath"];
}

- (void)dealloc {
    self.currentSectionPath = nil;
    
    [super dealloc];
}

@end
