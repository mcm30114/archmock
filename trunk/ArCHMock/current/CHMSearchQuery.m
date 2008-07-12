#import "CHMSearchQuery.h"

@implementation CHMSearchQuery

@synthesize searchString, tokens, tokensBySubstrings, uniqueSubstrings;

+ (CHMSearchQuery *)queryWithString:(NSString *)string {
    return [[[CHMSearchQuery alloc] initWithString:string] autorelease];
}

- (id)initWithString:(NSString *)initString {
    if (self = [super init]) {
        self.searchString = initString;
        
        NSMutableArray *substrings = [NSMutableArray 
                                      arrayWithArray:[searchString 
                                                      componentsSeparatedByCharactersInSet:[NSCharacterSet 
                                                                                            whitespaceAndNewlineCharacterSet]]];
        NSPredicate *emptyStringPredicate = [NSPredicate predicateWithFormat:@"SELF != ''"];
        substrings = [NSMutableArray arrayWithArray:[substrings filteredArrayUsingPredicate:emptyStringPredicate]];
        
        if ([substrings count] < 1) {
            return nil;
        }
        
        int wordsCount = [substrings count];
        
        self.tokens = [NSMutableArray array];
        self.uniqueSubstrings = [NSMutableArray array];
        self.tokensBySubstrings = [NSMutableDictionary dictionary];
        
        NSString *substring;
        int i = 0;
        while ([substrings count] > 0) {
            substring = [[substrings objectAtIndex:0] lowercaseString];
            [substrings removeObjectAtIndex:0];
            
//            if (wordsCount > 1) {
                NSArray *alphaNumericSubstrings = [substring 
                                                   componentsSeparatedByCharactersInSet:[[NSCharacterSet 
                                                                                          alphanumericCharacterSet] invertedSet]];
                alphaNumericSubstrings = [alphaNumericSubstrings filteredArrayUsingPredicate:emptyStringPredicate];
                if ([alphaNumericSubstrings count] > 0 && 
                    ([alphaNumericSubstrings count] != 1 || ![alphaNumericSubstrings containsObject:substring])) {
                    [substrings insertObjects:alphaNumericSubstrings 
                                    atIndexes:[NSIndexSet 
                                               indexSetWithIndexesInRange:NSMakeRange(0, [alphaNumericSubstrings count])]];
                    continue;
                }
//            }
            
            CHMSearchToken *token = [CHMSearchToken tokenWithString:[NSString stringWithString:substring] 
                                                           position:i++];
            if (![self.tokensBySubstrings objectForKey:substring]) {
                [uniqueSubstrings addObject:substring];
                [self.tokensBySubstrings setObject:[NSMutableArray array] forKey:substring];
            }
            NSMutableArray *substringTokens = [self.tokensBySubstrings objectForKey:substring];
            
            [substringTokens addObject:token];
            [tokens addObject:token];
        }
    }
    return self;
}

- (NSMutableArray *)tokensInfoArray {
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < [tokens count]; i++) {
        [array addObject:[NSNumber numberWithInt:0]];
    }
    return array;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ Search string: '%@';\n\
Tokens: %@;\n\
Unique substrings: %@",
            [super description],
            searchString,
            tokens,
            uniqueSubstrings];
}

- (void) dealloc {
    self.searchString = nil;
    self.tokens = nil;
    self.tokensBySubstrings = nil;
    self.uniqueSubstrings = nil;
    
    [super dealloc];
}

@end
