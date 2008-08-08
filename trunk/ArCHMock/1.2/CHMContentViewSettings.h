#import <Cocoa/Cocoa.h>


@interface CHMContentViewSettings : NSObject <NSCoding> {
    NSString *scrollOffset;
    float textSizeMultiplier;
}

@property (retain) NSString *scrollOffset;
@property float textSizeMultiplier;

+ (CHMContentViewSettings *)settingsWithData:(NSData *)data;
- (NSData *)data;

@end
