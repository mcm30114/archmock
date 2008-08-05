#import "CHMIndexSearchOperation.h"
#import "CHMDocument.h"
#import "CHMSectionAccumulatingSearchResult.h"
#import "CHMSearchToken.h"


@implementation CHMIndexSearchOperation

@synthesize document, index, query, currentString;
@synthesize wordsInSectionsFound;
@synthesize flushWordsThreshold;
@synthesize searchResultBySectionPath;

+ (id)operationWithDocument:(CHMDocument *)document query:(CHMSearchQuery *)query {
    return [[[CHMIndexSearchOperation alloc] initWithDocument:document query:query] autorelease];
}

- (id)initWithDocument:(CHMDocument *)initDocument query:(CHMSearchQuery *)initQuery {
    if (self = [super init]) {
        self.document = initDocument;
        self.index = document.index;
        self.query = initQuery;
        
        self.wordsInSectionsFound = 0;
        self.flushWordsThreshold = 1000;
        self.searchResultBySectionPath = [NSMutableDictionary dictionary];
    }
    
    return self;
}


- (void)main {
//    NSLog(@"DEBUG: Search operation: search started");
    [NSThread setThreadPriority:0.5];
    
    [document performSelectorOnMainThread:@selector(searchOperationStarted:) withObject:self.query waitUntilDone:YES];
    
    @try {
        NSEnumerator *strings = [query.uniqueSubstrings objectEnumerator];
        while (![self isCancelled] && (self.currentString = [strings nextObject])) {
            [index searchForTextChunk:currentString forOperation:self];
        }
    }
    @catch (NSException *e) {
        NSLog(@"WARN: Exception ignored during search for '%@': '%@'", self.currentString, e);
    }
    @finally {
        if (![self isCancelled]) {
            [self flushSearchResults];
        }
        else {
//            NSLog(@"DEBUG: Search operation cancelled");
        }
//        NSLog(@"DEBUG: Search operation: search ended");
        [document performSelectorOnMainThread:@selector(searchOperationEnded:) withObject:query waitUntilDone:YES];
        self.searchResultBySectionPath = nil;
    }
}

- (void)foundWord:(NSString *)word occurencesNumber:(int)occurencesNumber sectionLabel:(NSString *)sectionLabel sectionPath:(NSString *)sectionPath {
//    NSLog(@"DEBUG: Word '%@' found %d time(s) in section '%@' with path '%@'", word, occurencesNumber, sectionLabel, sectionPath);
    
    if ([self isCancelled] || [self shouldSkipSectionWithLabel:sectionLabel path:sectionPath]) {
        return;
    }
    
    self.wordsInSectionsFound = self.wordsInSectionsFound + 1;
    CHMSectionAccumulatingSearchResult *result = [searchResultBySectionPath objectForKey:sectionPath];
    if (!result) {
        result = [CHMSectionAccumulatingSearchResult resultWithSectionLabel:sectionLabel sectionPath:sectionPath tokensInfo:[query tokensInfoArray]];
        [searchResultBySectionPath setObject:result forKey:sectionPath];
    }
    
    NSArray *tokens = [query.tokensBySubstrings objectForKey:self.currentString];
    for (CHMSearchToken *token in tokens) {
        NSNumber *previousOccurences = [result.tokensOccurences objectAtIndex:token.position];
        int currentOccurences = [previousOccurences intValue] + occurencesNumber;
        [result.tokensOccurences replaceObjectAtIndex:token.position withObject:[NSNumber numberWithInt:currentOccurences]];
    }
    
    if ([self isCancelled]) {
        return;
    }
    
    if (0 == (self.wordsInSectionsFound % self.flushWordsThreshold)) {
        self.flushWordsThreshold = self.flushWordsThreshold * 2;
        [self flushSearchResults];
//        NSLog(@"DEBUG: Making little pause");
        [NSThread sleepForTimeInterval:1];
    }
}

- (void)flushSearchResults {
    if ([self isCancelled]) {
        return;
    }
    
//    NSLog(@"DEBUG: Words in sections found: %i. Flushing search results", wordsInSectionsFound);
    
    NSArray *results = [searchResultBySectionPath allValues];
    NSMutableArray *filteredResults = [NSMutableArray array];
    for (CHMSectionAccumulatingSearchResult *result in results) {
        BOOL shouldReject = NO;
        for (NSNumber *occurencesNumber in result.tokensOccurences) {
            if (0 == [occurencesNumber intValue]) {
                shouldReject = YES;
                break;
            }
        }
        if (!shouldReject) {
            [filteredResults addObject:result];
        }
    }
    results = [NSArray arrayWithArray:filteredResults];
    
//    NSMutableArray *tokensMaxCounts = [query tokensInfoArray];
//    for (CHMSectionAccumulatingSearchResult *result in results) {
//        if ([self isCancelled]) {
//            return;
//        }
//        for (int i = 0; i < [result.tokensOccurences count]; i++) {
//            if ([self isCancelled]) {
//                return;
//            }
//            int oldMaxCount = [[tokensMaxCounts objectAtIndex:i] intValue];
//            int currentCount = [[result.tokensOccurences objectAtIndex:i] intValue];
//            if (currentCount > oldMaxCount) {
//                [tokensMaxCounts replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:currentCount]];
//            }
//        }
//    }
    
//    [results makeObjectsPerformSelector:@selector(calculateRelevancyPerTokenWithTokensMaxCounts:) withObject:tokensMaxCounts];
    
    int maxCount = 0;
    for (CHMSectionAccumulatingSearchResult *result in results) {
        if ([self isCancelled]) {
            return;
        }
        int currentTotalCount = result.tokensOccurencesTotalCount;
        if (currentTotalCount > maxCount) {
            maxCount = currentTotalCount;
        }
    }
    if (0 == maxCount) {
//        NSLog(@"ERROR: Max tokens occurences number is 0");
        return;
    }
    if ([self isCancelled]) {
        return;
    }
    for (CHMSectionAccumulatingSearchResult *result in results) {
        [result calculateTotalRelevancyWithMaxTokensCount:maxCount];
    }
    if ([self isCancelled]) {
        return;
    }
//    NSLog(@"DEBUG: Accumulating search results to flush: %@", results);
    [document performSelectorOnMainThread:@selector(processAccumulatingSearchResults:) withObject:results waitUntilDone:YES];
}

- (void)dealloc {
//    NSLog(@"DEBUG: Deallocating CHMIndexSearchOperation");
    
    self.document = nil;
    
    self.index = nil;
    self.query = nil;
    self.currentString = nil;
    
    self.searchResultBySectionPath = nil;
    
    [super dealloc];
}


@end
