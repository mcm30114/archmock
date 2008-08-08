#import "CHMContentViewSettings.h"


@implementation CHMContentViewSettings

@synthesize scrollOffset;
@synthesize textSizeMultiplier;

+ (CHMContentViewSettings *)settingsWithData:(NSData *)data {
    if (nil == data) {
        return nil;
    }
    
    NSKeyedUnarchiver *unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease];
    CHMContentViewSettings *settings = [unarchiver decodeObjectForKey:@"CHMContentViewSettings"];
    [unarchiver finishDecoding];
    
    return settings;
}

- (id)init {
    if (self = [super init]) {
        self.scrollOffset = @"[0, 0]";
        self.textSizeMultiplier = 1.;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.scrollOffset = [coder decodeObjectForKey:@"scrollOffset"];
        self.textSizeMultiplier = [coder decodeFloatForKey:@"textSizeMultiplier"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:scrollOffset forKey:@"scrollOffset"];
    [coder encodeFloat:textSizeMultiplier forKey:@"textSizeMultiplier"];
}

- (NSData *)data {
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease];
    [archiver encodeObject:self forKey:@"CHMContentViewSettings"];
    [archiver finishEncoding];
    
    return [NSData dataWithData:data];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: {textSizeMultiplier: %f, scrollOffset: '%@'}", [super description], textSizeMultiplier, scrollOffset];
}

- (void)dealloc {
    self.scrollOffset = nil;
    
    [super dealloc];
}

@end
