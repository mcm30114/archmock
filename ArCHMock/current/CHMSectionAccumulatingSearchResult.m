#import "CHMSectionAccumulatingSearchResult.h"


@implementation CHMSectionAccumulatingSearchResult

@synthesize sectionLabel, sectionPath, tokensOccurences, relevancy;

+ (CHMSectionAccumulatingSearchResult *)resultWithSectionLabel:(NSString *)sectionLabel 
                                              sectionPath:(NSString *)sectionPath
                                               tokensInfo:(NSMutableArray *)tokensInfo {
    return [[[CHMSectionAccumulatingSearchResult alloc] initWithSectionLabel:sectionLabel
                                                            sectionPath:sectionPath
                                                             tokensInfo:tokensInfo] autorelease];
}

- (id)initWithSectionLabel:(NSString *)initSectionLabel
               sectionPath:(NSString *)initSectionPath
                tokensInfo:(NSMutableArray *)initTokensInfo {

    if (self = [super init]) {
        self.sectionLabel = initSectionLabel;
        self.sectionPath = initSectionPath;
        self.tokensOccurences = initTokensInfo;
    }
    
    return self;
}

- (void)calculateRelevancy:(NSArray *)tokensMaximumCounts {
//    NSLog(@"DEBUG: Local token counts: %@", tokensOccurences);
//    NSLog(@"DEBUG: Maximum token counts: %@", tokensMaximumCounts);
    float myRelevancy = 0;
    float tokenRelevancyRatio = 1 / (float)[tokensMaximumCounts count];
//    NSLog(@"DEBUG: Token relevancy ratio: %f", tokenRelevancyRatio);
    for (int i = 0; i < [tokensMaximumCounts count]; i++) {
        float tokenMaximumCount = [[tokensMaximumCounts objectAtIndex:i] floatValue];
        if (0 != tokenMaximumCount) {
            float tokenLocalCount = [[tokensOccurences objectAtIndex:i] floatValue];
            float currentTokenRatio = tokenLocalCount / tokenMaximumCount;
//            NSLog(@"DEBUG: Current token ratio: %f", currentTokenRatio);
            myRelevancy += ceil(100 * tokenRelevancyRatio * currentTokenRatio);
        }
    }
//    NSLog(@"DEBUG: Relevancy '%f'", myRelevancy);
    self.relevancy = myRelevancy;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"%@ Section label: '%@', \
path: '%@', search relevancy: %i;\ntokens occurences: %@",
            [super description],
            sectionLabel,
            sectionPath,
            relevancy,
            tokensOccurences];
}

- (void) dealloc {
    self.sectionLabel = nil;
    self.sectionPath = nil;
    self.tokensOccurences = nil;
    
    [super dealloc];
}

@end
