#import <Cocoa/Cocoa.h>
#import "CHMSearchToken.h"

@interface CHMSearchQuery : NSObject {
    NSString *searchString;
    NSMutableArray *tokens; 
    NSMutableArray *uniqueSubstrings;
    NSMutableDictionary *tokensBySubstrings;
}

@property (retain) NSMutableArray *tokens; 
@property (retain) NSMutableArray *uniqueSubstrings;
@property (retain) NSMutableDictionary *tokensBySubstrings;
@property (retain) NSString *searchString;

+ (CHMSearchQuery *)queryWithString:(NSString *)string;
- (id)initWithString:(NSString *)initString;

- (NSMutableArray *)tokensInfoArray;

@end
