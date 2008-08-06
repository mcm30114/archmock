#import "CHMSearchOperation.h"
#import "CHMDocument.h"
#import "CHMIndexSearchOperation.h"

@implementation CHMSearchOperation

+ (CHMSearchOperation *)operationWithDocument:(CHMDocument *)document query:(CHMSearchQuery *)query {
    if (!query) {
        NSLog(@"WARN: Can't create search operation without query");
        return nil;
    }
    
    if (document.index) {
//        NSLog(@"INFO: Document contains index. Creating index search operation");
        return [CHMSearchOperation indexSearchOperationWithDocument:document 
                                                              query:query];
    }
    else {
//        NSLog(@"WARN: Can't create search operation for documents without index");
        return nil;
    }
}

+ (CHMSearchOperation *)indexSearchOperationWithDocument:(CHMDocument *)document query:(CHMSearchQuery *)query {
    return [CHMIndexSearchOperation operationWithDocument:document query:query];
}

- (CHMSearchQuery *)query {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (BOOL)shouldSkipSectionWithLabel:(NSString *)sectionLabel path:(NSString *)sectionPath {
    return [[sectionPath lowercaseString] hasSuffix:@".hhp"];
}

- (void)foundWord:(NSString *)word occurencesNumber:(int)occurencesNumber sectionLabel:(NSString *)sectionLabel sectionPath:(NSString *)sectionPath {
    [self doesNotRecognizeSelector:_cmd];
}

@end
