#import "CHMSectionAccumulatedSearchResult.h"


@implementation CHMSectionAccumulatedSearchResult

@synthesize sectionLabel, sectionPath, relevancy;

+ (CHMSectionAccumulatedSearchResult *)resultWithSectionLabel:(NSString *)sectionLabel sectionPath:(NSString *)sectionPath relevancy:(int)relevancy {
    return [[[CHMSectionAccumulatedSearchResult alloc] initWithSectionLabel:sectionLabel sectionPath:sectionPath relevancy:relevancy] autorelease];
}

- (id)initWithSectionLabel:(NSString *)initSectionLabel sectionPath:(NSString *)initSectionPath relevancy:(int)initRelevancy {
    if (self = [super init]) {
        self.sectionLabel = initSectionLabel;
        self.sectionPath = initSectionPath;
        self.relevancy = initRelevancy;
    }
    
    return self;
}

- (void)dealloc {
    self.sectionLabel = nil;
    self.sectionPath = nil;

    [super dealloc];
}

@end
