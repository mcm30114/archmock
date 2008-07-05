#import <Cocoa/Cocoa.h>

@class CHMSearchQuery;
@class CHMDocument;
@class CHMIndexSearchOperation;

@interface CHMSearchOperation : NSOperation

+ (CHMSearchOperation *)operationWithDocument:(CHMDocument *)document 
                                        query:(CHMSearchQuery *)query;

+ (CHMSearchOperation *)indexSearchOperationWithDocument:(CHMDocument *)document 
                                                   query:(CHMSearchQuery *)query;

- (CHMSearchQuery *)query;

- (void)foundWord:(NSString *)word 
 occurencesNumber:(int)occurencesNumber 
     sectionLabel:(NSString *)sectionLabel 
      sectionPath:(NSString *)sectionPath;

- (BOOL)shouldSkipSectionWithLabel:(NSString *)sectionLabel 
                              path:(NSString *)sectionPath;

@end
