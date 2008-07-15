#import "CHMDocument.h"
#import "CHMDocumentWindowController.h"
#import "CHMDocumentController.h"
#import "CHMSectionAccumulatingSearchResult.h"
#import "CHMSectionAccumulatedSearchResult.h"

@implementation CHMDocument

@dynamic containerID;
@dynamic title;

@dynamic currentSectionLabel;

@synthesize uniqueID;
@synthesize container, tableOfContents, index;
@synthesize currentSectionPath;
@synthesize currentSectionScrollOffset;
@synthesize homeSectionPath;
@synthesize currentSearchQuery, currentSearchOperation, scheduledSearchOperation;
@synthesize currentSearchResults, searchResultBySectionPath;

@synthesize scrollToFirstHighlight;
@synthesize windowSettings;

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
    if (selector == @selector(setCurrentSectionScrollOffset:) || 
        selector == @selector(currentSectionScrollOffset)) {
        return NO;
    }
    return YES;
}

- (NSString *)containerID {
    return self.container.uniqueID;
}

- (NSString *)title {
    return self.container.title;
}

- (NSString *)currentSectionLabel {
    if (nil == self.currentSectionPath) {
        return nil;
    }
    
    CHMSection *section = [self locateSectionByPath:self.currentSectionPath];
    if (nil == section) {
        return self.currentSectionPath;
    }
    
    return section.label;
}

- (CHMSection *)locateSectionByPath:(NSString *)sectionPath {
    if (tableOfContents) {
        return [tableOfContents.sectionsByPath objectForKey:[sectionPath lowercaseString]];
    }
    
    return nil;
}

- (BOOL)readFromFile:(NSString *)filePath 
              ofType:(NSString *)typeName {
//    NSLog(@"INFO: Reading CHM from file '%@', of type: '%@'", filePath, typeName);
    
    self.container = [CHMContainer containerWithFilePath:filePath];
    
    if (!container) {
        NSLog(@"ERROR: Can't open CHM file '%@'", filePath);
        return NO;
    }
    
    self.tableOfContents = [CHMTableOfContents tableOfContentsWithContainer:container];
    self.index = [CHMIndex indexWithContainer:container];
    
    self.currentSearchResults = [NSMutableArray array];
    self.searchResultBySectionPath = [NSMutableDictionary dictionary];
    
    self.homeSectionPath = container.homeSectionPath;
    if (!homeSectionPath && tableOfContents) {
        NSArray *firstLevelSections = tableOfContents.root.children;
        if ([firstLevelSections count] > 0) {
            self.homeSectionPath = [[firstLevelSections objectAtIndex:0] path];
        }
    }
    
//    NSLog(@"DEBUG: Opening CHM document: '%@'", [self fileURL]);
    
    return YES;
}

- (void)makeWindowControllers {
    CHMDocumentWindowController *controller = [[[CHMDocumentWindowController alloc] 
                                        initWithWindowNibName:@"CHMDocument"] autorelease];
    [self addWindowController:controller];
}

- (void)searchForText:(NSString *)text {
    CHMSearchQuery *query = [CHMSearchQuery queryWithString:text];
//    NSLog(@"INFO: Search text: '%@', query: %@", text, query);
    
    if (!query) {
        [self cancelSearch];
        self.scrollToFirstHighlight = NO;
        return;
    }
    
    if (index) {
//        NSLog(@"INFO: Searching using index: %@", query);
        [self clearCurrentSearchResults];
        CHMSearchOperation *operation = [CHMSearchOperation indexSearchOperationWithDocument:self
                                                                                       query:query];
        if ([currentSearchOperation isExecuting]) {
            [self scheduleSearchOperation:operation];
            [self cancelCurrentSearchOperation];
        }
        else {
            [self startSearchOperation:operation];
        }
    }
    else {
        NSLog(@"WARN: Index search is not available for this document");
        self.currentSearchQuery = query;
        self.scrollToFirstHighlight = YES;
    }
}

- (void)clearCurrentSearchResults {
//    NSLog(@"DEBUG: Clearing current search results");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSearchResultsAboutToBeCleared" 
                                                        object:self];
    [currentSearchResults removeAllObjects];
    [searchResultBySectionPath removeAllObjects];
    self.currentSearchQuery = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSearchResultsCleared" 
                                                        object:self];
}

- (void)startSearchOperation:(CHMSearchOperation *)operation {
//    NSLog(@"DEBUG: Starting search operation: %@", operation.query);
    
    NSOperationQueue *queue = [CHMDocumentController sharedCHMDocumentController].operationQueue;
    [queue addOperation:operation];
//    [operation start];
    
    self.currentSearchOperation = operation;
}

- (void)scheduleSearchOperation:(CHMSearchOperation *)operation {
//    NSLog(@"DEBUG: Scheduling search operation: %@", operation.query);
    self.scheduledSearchOperation = operation;
}

- (void)searchOperationStarted:(CHMSearchQuery *)query {
//    NSLog(@"DEBUG: Search operation started: %@", query);
    self.currentSearchQuery = query;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchOperationStarted" 
                                                        object:self];
}

- (void)cancelSearch {
//    NSLog(@"DEBUG: Cancelling search");
    
    self.scheduledSearchOperation = nil;
    [self cancelCurrentSearchOperation];
    self.currentSearchQuery = nil;
    [self clearCurrentSearchResults];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchCancelled" 
                                                        object:self];
}
                
- (void)cancelCurrentSearchOperation {
    if ([currentSearchOperation isExecuting]) {
//        NSLog(@"INFO: Cancelling current search operation: %@", currentSearchOperation.query);
        [currentSearchOperation cancel];
    }
}

- (void)processAccumulatingSearchResults:(NSArray *)accumulatingResults {
//    NSLog(@"DEBUG: Processing search results: %i", [accumulatingResults count]);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AccumulatingSearchResultsAboutToBeProcessed" 
                                                        object:self];

    
    NSMutableArray *newAccumulatedResults = [NSMutableArray array];
    
    for (CHMSectionAccumulatingSearchResult *accumulatingResult in accumulatingResults) {
        CHMSectionAccumulatedSearchResult *accumulatedResult = [searchResultBySectionPath objectForKey:accumulatingResult.sectionPath];
        
        if (!accumulatedResult) {
            accumulatedResult = [CHMSectionAccumulatedSearchResult resultWithSectionLabel:accumulatingResult.sectionLabel
                                                                              sectionPath:accumulatingResult.sectionPath
                                                                                relevancy:accumulatingResult.relevancy];
            
            CHMSection *section = [self locateSectionByPath:accumulatedResult.sectionPath];
            if (section) {
                accumulatedResult.sectionLabel = section.label;
            }
            
            [searchResultBySectionPath setObject:accumulatedResult 
                                          forKey:accumulatedResult.sectionPath];
            [newAccumulatedResults addObject:accumulatedResult];
        }
        
        accumulatedResult.relevancy = accumulatingResult.relevancy;
    }
    
    if ([newAccumulatedResults count] > 0) {
//        NSLog(@"DEBUG: New accumulated results: %i", [newAccumulatedResults count]);
        NSMutableArray *currentSearchResultsProxy = [self mutableArrayValueForKey:@"currentSearchResults"];
        [currentSearchResultsProxy addObjectsFromArray:newAccumulatedResults];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AccumulatingSearchResultsProcessed" 
                                                        object:self];
}

- (void)searchOperationEnded:(CHMSearchQuery *)query {
//    NSLog(@"DEBUG: Search ended: %@", query);
    
    if (scheduledSearchOperation) {
//        NSLog(@"DEBUG: Starting scheduled search: %@", [scheduledSearchOperation query]);
        [self startSearchOperation:scheduledSearchOperation];
        self.scheduledSearchOperation = nil;
    }
}

//- (id)retain {
//    [super retain];
//    NSLog(@"DEBUG: Retaining CHM document: retain count: %i, %@", [self retainCount], self);
//    return self;
//}
//
//- (oneway void)release {
//    NSLog(@"DEBUG: Releasing CHM document: retain count: %i, %@", [self retainCount], self);
//    [super release];
//}
        
- (void)close {
//    NSLog(@"DEBUG: Closing CHM document: '%@'", [self fileURL]);
    self.scheduledSearchOperation = nil;
    self.currentSearchOperation = nil;

    [super close];
}

- (void)dealloc {
    //    NSLog(@"DEBUG: Deallocating CHMDocument");
    self.container = nil;
    self.tableOfContents = nil;
    self.index = nil;
    
    self.currentSectionPath = nil;
    
    self.currentSearchQuery = nil;
    self.currentSearchOperation = nil;
    self.scheduledSearchOperation = nil;
    
    self.currentSearchResults = nil;
    self.searchResultBySectionPath = nil;
    
    self.windowSettings = nil;
    
    [super dealloc];
}

@end
