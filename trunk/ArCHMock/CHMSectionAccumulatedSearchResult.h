#import <Cocoa/Cocoa.h>


@interface CHMSectionAccumulatedSearchResult : NSObject {
    NSString *sectionLabel;
    NSString *sectionPath;
    int relevancy;
}

@property (retain) NSString *sectionLabel;
@property (retain) NSString *sectionPath;
@property int relevancy;


+ (CHMSectionAccumulatedSearchResult *)resultWithSectionLabel:(NSString *)sectionLabel
                                            sectionPath:(NSString *)sectionPath
                                              relevancy:(int)relevancy;

- (id)initWithSectionLabel:(NSString *)initSectionLabel
               sectionPath:(NSString *)initSectionPath
                 relevancy:(int)initRelevancy;

@end
