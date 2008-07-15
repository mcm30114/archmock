#import "CHMSearchToken.h"


@implementation CHMSearchToken

@synthesize string, position;

+ (CHMSearchToken *)tokenWithString:(NSString *)string 
                           position:(int)position {
    return [[[CHMSearchToken alloc] initWithString:string 
                                          position:position] autorelease];
}

- (id)initWithString:(NSString *)initString 
            position:(int)initPosition {
    if (self = [super init]) {
        self.string = initString;
        self.position = initPosition;
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: {string: '%@', position: %i}", 
            [super description],
            string,
            position];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    return [string isEqualToString:[object string]] && position == [object position];
}

- (void)dealloc {
    self.string = nil;
    
    [super dealloc];
}

@end
