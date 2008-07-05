#import <Cocoa/Cocoa.h>

@interface CHMSectionAccumulatingSearchResult : NSObject {
    NSString *sectionLabel;
    NSString *sectionPath;
    
    NSMutableArray *tokensOccurences;
    
    int relevancy;
}

@property (retain) NSString *sectionLabel, *sectionPath;
@property (retain) NSMutableArray *tokensOccurences;
@property int relevancy;

+ (CHMSectionAccumulatingSearchResult *)resultWithSectionLabel:(NSString *)sectionLabel 
                                              sectionPath:(NSString *)sectionPath
                                               tokensInfo:(NSMutableArray *)tokensInfo;

- (id)initWithSectionLabel:(NSString *)initSectionLabel
               sectionPath:(NSString *)initSectionPath
                tokensInfo:(NSMutableArray *)initTokensInfo;

- (void)calculateRelevancy:(NSArray *)tokensMaximumCounts;

@end
