#import <Cocoa/Cocoa.h>
#import "CHMContainer.h"
#import "CHMTableOfContents.h"
#import "CHMIndex.h"
#import "CHMSection.h"

#import "CHMSearchOperation.h";
#import "CHMSearchQuery.h"

#import "CHMContentViewSettings.h"
#import "CHMDocumentWindowSettings.h"

@interface CHMDocument : NSDocument {
    CHMContainer *container;
    CHMTableOfContents *tableOfContents;
    CHMIndex *index;
    
    CHMContentViewSettings *contentViewSettings;
    CHMDocumentWindowSettings *windowSettings;
    
    CHMContentViewSettings *contentViewSettingsToApply;
    CHMDocumentWindowSettings *windowInitialSettings;
    
    NSString *uniqueID;
    NSString *currentSectionPath;
    NSString *homeSectionPath;
    
    CHMSearchQuery *currentSearchQuery;
    CHMSearchOperation *currentSearchOperation;
    CHMSearchOperation *scheduledSearchOperation;
    
    NSMutableArray *currentSearchResults;
    NSMutableDictionary *searchResultBySectionPath;
}

@property (readonly) NSString *containerID;
@property (readonly) NSString *title;

@property (readonly) CHMContentViewSettings *contentViewSettings;
@property (readonly) CHMDocumentWindowSettings *windowSettings;
@property (retain) CHMContentViewSettings *contentViewSettingsToApply;
@property (retain) CHMDocumentWindowSettings *windowInitialSettings;

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
