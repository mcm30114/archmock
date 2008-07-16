#import "CHMDocumentWindowSettings.h"


@implementation CHMDocumentWindowSettings

@synthesize frame;
@synthesize sidebarWidth;
@synthesize isSidebarCollapsed;

+ (CHMDocumentWindowSettings *)settingsWithData:(NSData *)data {
    if (nil == data) {
        return nil;
    }
    
    NSKeyedUnarchiver *unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease];
    CHMDocumentWindowSettings *settings = [unarchiver decodeObjectForKey:@"CHMDocumentWindowSettings"];
    [unarchiver finishDecoding];
    
    return settings;
}

- (NSData *)data {
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease];
    [archiver encodeObject:self 
                    forKey:@"CHMDocumentWindowSettings"];
    [archiver finishEncoding];

    return [NSData dataWithData:data];
}

- (id) init {
    if (self = [super init]) {
        self.frame = NSMakeRect(100., 100., 900., 600.);
        self.isSidebarCollapsed = NO;
        self.sidebarWidth = 200;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    [super init];
    
    self.frame = [coder decodeRectForKey:@"frame"];
    
    self.sidebarWidth = [coder decodeFloatForKey:@"sidebarWidth"];
    self.isSidebarCollapsed = [coder decodeBoolForKey:@"isSidebarCollapsed"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeRect:frame forKey:@"frame"];
    
    [coder encodeFloat:sidebarWidth forKey:@"sidebarWidth"];
    [coder encodeBool:isSidebarCollapsed forKey:@"isSidebarCollapsed"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: {frame: %@, sidebarWidth: %f \
isSidebarCollapsed: %@}", [super description], NSStringFromRect(self.frame), 
            sidebarWidth, isSidebarCollapsed ? @"YES" : @"NO"];
}

@end
