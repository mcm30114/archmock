#import <Cocoa/Cocoa.h>
#import "CHMSearchOperation.h"

@class CHMDocument;
@class CHMIndex;
@class CHMSearchQuery;

@interface CHMIndexSearchOperation : CHMSearchOperation {
    CHMDocument *document;
    CHMIndex *index;
    CHMSearchQuery *query;
    NSString *currentString;
    
    int wordsInSectionsFound;
    int flushWordsThreshold;
    NSMutableDictionary *searchResultBySectionPath;
}

+ (id)operationWithDocument:(CHMDocument *)document 
                      query:(CHMSearchQuery *)query;

- (id)initWithDocument:(CHMDocument *)initDocument
                 query:(CHMSearchQuery *)initQuery;

@property int wordsInSectionsFound;
@property int flushWordsThreshold;
@property (retain) CHMDocument *document;
@property (retain) CHMIndex *index;
@property (retain) CHMSearchQuery *query;
@property (retain) NSString *currentString;
@property (retain) NSMutableDictionary *searchResultBySectionPath;


- (void)flushSearchResults;

@end
