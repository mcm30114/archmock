#import <Cocoa/Cocoa.h>
#import "CHMContainer.h"
#import "CHMTableOfContents.h"
#import "CHMIndex.h"
#import "CHMSection.h"
#import "CHMSearchOperation.h";
#import "CHMSearchQuery.h"
#import "CHMDocumentWindowSettings.h"

@interface CHMDocument : NSDocument {
    CHMContainer *container;
    CHMTableOfContents *tableOfContents;
    CHMIndex *index;
    CHMDocumentWindowSettings *windowSettings;
    
    NSString *uniqueID;
    NSString *currentSectionPath;
    NSString *currentSectionScrollOffset;
    NSString *homeSectionPath;
    float textSizeMultiplierToSet;
    float textSizeMultiplier;
    BOOL scrollToFirstHighlight;
    BOOL dontClearContentOffsetOnUnload;
    
    CHMSearchQuery *currentSearchQuery;
    CHMSearchOperation *currentSearchOperation;
    CHMSearchOperation *scheduledSearchOperation;
    
    NSMutableArray *currentSearchResults;
    NSMutableDictionary *searchResultBySectionPath;
}

@property (readonly) NSString *containerID;
@property (readonly) NSString *title;

@property BOOL scrollToFirstHighlight;
@property BOOL dontClearContentOffsetOnUnload;
@property (retain) NSString *currentSectionScrollOffset;
@property float textSizeMultiplierToSet;
@property float textSizeMultiplier;
@property (retain) CHMDocumentWindowSettings *windowSettings;

@property (retain) NSString *uniqueID;

@property (retain) CHMContainer *container;
@property (retain) CHMTableOfContents *tableOfContents;
@property (retain) CHMIndex *index;

@property (retain) NSString *currentSectionPath;
@property (readonly) NSString *currentSectionLabel;

@property (retain) NSString *homeSectionPath;
@property (retain) CHMSearchQuery *currentSearchQuery;
@property (retain) CHMSearchOperation *currentSearchOperation;
@property (retain) CHMSearchOperation *scheduledSearchOperation;

@property (retain) NSMutableArray *currentSearchResults;
@property (retain) NSMutableDictionary *searchResultBySectionPath;

- (CHMSection *)locateSectionByPath:(NSString *)sectionPath;

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
