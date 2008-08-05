#import <Cocoa/Cocoa.h>


@interface CHMSearchToken : NSObject {
    NSString *string;
    int position;
}

@property (retain) NSString *string;
@property int position;

+ (CHMSearchToken *)tokenWithString:(NSString *)string position:(int)position;

- (id)initWithString:(NSString *)initString position:(int)initPosition;

@end
