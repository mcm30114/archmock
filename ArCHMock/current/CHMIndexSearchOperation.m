#import "CHMIndexSearchOperation.h"
#import "CHMDocument.h"
#import "CHMSectionAccumulatingSearchResult.h"
#import "CHMSearchToken.h"


@implementation CHMIndexSearchOperation

@synthesize document, index, query, currentString;
@synthesize wordsInSectionsFound;
@synthesize flushWordsThreshold;
@synthesize searchResultBySectionPath;

+ (id)operationWithDocument:(CHMDocument *)document 
                      query:(CHMSearchQuery *)query {
    return [[[CHMIndexSearchOperation alloc] initWithDocument:document 
                                                        query:query] autorelease];
}

- (id)initWithDocument:(CHMDocument *)initDocument
                 query:(CHMSearchQuery *)initQuery {
    if (self = [super init]) {
        self.document = initDocument;
        self.index = document.index;
        self.query = initQuery;
        
        self.wordsInSectionsFound = 0;
        self.flushWordsThreshold = 500;
        self.searchResultBySectionPath = [NSMutableDictionary dictionary];
    }
    
    return self;
}


- (void)main {
//    NSLog(@"DEBUG: Search operation: search started");
    [NSThread setThreadPriority:0.5];
    
    [document performSelectorOnMainThread:@selector(searchOperationStarted:)
                               withObject:self.query
                            waitUntilDone:YES];
    
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
        [document performSelectorOnMainThread:@selector(searchOperationEnded:)
                                   withObject:query 
                                waitUntilDone:YES];
        self.searchResultBySectionPath = nil;
    }
}

- (void)foundWord:(NSString *)word 
 occurencesNumber:(int)occurencesNumber 
     sectionLabel:(NSString *)sectionLabel 
      sectionPath:(NSString *)sectionPath {
//    NSLog(@"DEBUG: Word '%@' found %d time(s)\nin section '%@'\nwith path '%@'", 
//          word,
//          occurencesNumber,
//          sectionLabel,
//          sectionPath);
    
    if ([self isCancelled] || [self shouldSkipSectionWithLabel:sectionLabel 
                                                          path:sectionPath]) {
        return;
    }
    
    self.wordsInSectionsFound = self.wordsInSectionsFound + 1;
    CHMSectionAccumulatingSearchResult *result = [searchResultBySectionPath objectForKey:sectionPath];
    if (!result) {
        result = [CHMSectionAccumulatingSearchResult resultWithSectionLabel:sectionLabel 
                                                                sectionPath:sectionPath
                                                                 tokensInfo:[query tokensInfoArray]];
        [searchResultBySectionPath setObject:result 
                                      forKey:sectionPath];
    }
    
    NSArray *tokens = [query.tokensBySubstrings objectForKey:self.currentString];
    for (int i = 0; i < [tokens count]; i++) {
        CHMSearchToken *token = [tokens objectAtIndex:i];
        NSNumber *previousOccurences = [result.tokensOccurences objectAtIndex:token.position];
        int currentOccurences = [previousOccurences intValue] + occurencesNumber;
        [result.tokensOccurences replaceObjectAtIndex:token.position 
         withObject:[NSNumber numberWithInt:currentOccurences]];
    }
    
    if ([self isCancelled]) {
        return;
    }
    
    if (0 == (self.wordsInSectionsFound % self.flushWordsThreshold)) {
        self.flushWordsThreshold = self.flushWordsThreshold * 20;
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
    NSMutableArray *tokensMaxCounts = [query tokensInfoArray];
    for (int i = 0; i < [results count]; i++) {
        if ([self isCancelled]) {
            return;
        }
        CHMSectionAccumulatingSearchResult *result = [results objectAtIndex:i];
        
        for (int j = 0; j < [result.tokensOccurences count]; j++) {
            if ([self isCancelled]) {
                return;
            }
            int oldMaxCount = [[tokensMaxCounts objectAtIndex:j] intValue];
            int currentCount = [[result.tokensOccurences objectAtIndex:j] intValue];
            if (currentCount > oldMaxCount) {
                [tokensMaxCounts replaceObjectAtIndex:j 
                                           withObject:[NSNumber numberWithInt:currentCount]];
            }
        }
    }
    
    [results makeObjectsPerformSelector:@selector(calculateRelevancy:)
                             withObject:tokensMaxCounts];
    
    if ([self isCancelled]) {
        return;
    }
    
//    NSLog(@"DEBUG: Accumulating search results to flush: %d", [results count]);
    [document performSelectorOnMainThread:@selector(processAccumulatingSearchResults:)
                               withObject:results 
                            waitUntilDone:YES];
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
