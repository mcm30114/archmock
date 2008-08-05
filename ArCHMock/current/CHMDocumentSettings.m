#import "CHMDocumentSettings.h"


@implementation CHMDocumentSettings

@synthesize currentSectionPath;
@synthesize currentSectionScrollOffset;
@synthesize windowSettings;
@synthesize date;
@synthesize textSizeMultiplier;

+ (CHMDocumentSettings *)settingsWithCurrentSectionPath:(NSString *)currentSectionPath 
                                    sectionScrollOffset:(NSString *)sectionScrollOffset
                                         windowSettings:(CHMDocumentWindowSettings *)windowSettings {
    return [[[CHMDocumentSettings alloc] initWithCurrentSectionPath:currentSectionPath
                                                sectionScrollOffset:sectionScrollOffset
                                                     windowSettings:windowSettings] autorelease];
}

- (id)initWithCurrentSectionPath:(NSString *)initCurrentSectionPath
             sectionScrollOffset:(NSString *)initSectionScrollOffset
                  windowSettings:(CHMDocumentWindowSettings *)initWindowSettings {
    if (self = [super init]) {
        self.currentSectionPath = initCurrentSectionPath;
        self.windowSettings = initWindowSettings;
        if (nil == initSectionScrollOffset) {
            initSectionScrollOffset = @"[0, 0]";
        }
        self.currentSectionScrollOffset = initSectionScrollOffset;
        self.date = [NSDate date];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    [super init];
    
    self.currentSectionPath = [coder decodeObjectForKey:@"currentSectionPath"];
    self.currentSectionScrollOffset = [coder decodeObjectForKey:@"sectionScrollOffset"];
    self.textSizeMultiplier = [coder decodeFloatForKey:@"textSizeMultiplier"];
    self.windowSettings = [coder decodeObjectForKey:@"windowSettings"];
    self.date = [coder decodeObjectForKey:@"date"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:currentSectionPath forKey:@"currentSectionPath"];
    [coder encodeObject:currentSectionScrollOffset forKey:@"sectionScrollOffset"];
    [coder encodeFloat:textSizeMultiplier forKey:@"textSizeMultiplier"];
    [coder encodeObject:windowSettings forKey:@"windowSettings"];
    [coder encodeObject:date forKey:@"date"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: {date: %@, currentSectionPath: '%@', \
currentSectionScrollOffset: '%@', windowSettings: %@}", 
            [super description], date, currentSectionPath, currentSectionScrollOffset, 
            windowSettings];
}

- (void)dealloc {
    self.date = nil;
    self.currentSectionPath = nil;
    self.currentSectionScrollOffset = nil;
    
    self.windowSettings = nil;
    
    [super dealloc];
}

@end
