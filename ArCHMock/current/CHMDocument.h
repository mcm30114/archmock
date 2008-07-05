#import <Cocoa/Cocoa.h>
#import "CHMContainer.h"
#import "CHMTableOfContents.h"
#import "CHMIndex.h"
#import "CHMSection.h"
#import "CHMSearchOperation.h";

#import "CHMSearchQuery.h"

@interface CHMDocument : NSDocument {
    CHMContainer *container;
    CHMTableOfContents *tableOfContents;
    CHMIndex *index;
    
    NSString *currentSectionPath;
    NSString *homeSectionPath;
    BOOL scrollToFirstHighlight;
    
    CHMSearchQuery *currentSearchQuery;
    CHMSearchOperation *currentSearchOperation;
    CHMSearchOperation *scheduledSearchOperation;
    
    NSMutableArray *currentSearchResults;
    NSMutableDictionary *searchResultBySectionPath;
}

@property (readonly) NSString *containerID;
@property BOOL scrollToFirstHighlight;

@property (retain) CHMContainer *container;
@property (retain) CHMTableOfContents *tableOfContents;
@property (retain) CHMIndex *index;

@property (retain) NSString *currentSectionPath;
@property (retain) NSString *homeSectionPath;
@property (retain) CHMSearchQuery *currentSearchQuery;
@property (retain) CHMSearchOperation *currentSearchOperation;
@property (retain) CHMSearchOperation *scheduledSearchOperation;

@property (retain) NSMutableArray *currentSearchResults;
@property (retain) NSMutableDictionary *searchResultBySectionPath;

- (CHMSection *)sectionByPath:(NSString *)sectionPath;

- (void)searchForText:(NSString *)text;

- (void)startSearchOperation:(CHMSearchOperation *)operation;

- (void)scheduleSearchOperation:(CHMSearchOperation *)operation;

- (void)searchOperationStarted:(CHMSearchQuery *)query;

- (void)clearCurrentSearchResults;

- (void)processAccumulatingSearchResults:(NSArray *)accumulatingResults;

- (void)cancelSearch;

- (void)cancelCurrentSearchOperation;

- (void)searchOperationEnded:(CHMSearchQuery *)query;

@end
