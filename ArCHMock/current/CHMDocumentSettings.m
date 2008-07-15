#import "CHMDocumentSettings.h"


@implementation CHMDocumentSettings

@synthesize currentSectionPath;
@synthesize sectionScrollOffset;
@synthesize windowSettings;
@synthesize date;

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
            initSectionScrollOffset = @"{left: 0, top: 0}";
        }
        self.sectionScrollOffset = initSectionScrollOffset;
        self.date = [NSDate date];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    [super init];
    
    self.currentSectionPath = [coder decodeObjectForKey:@"currentSectionPath"];
    self.sectionScrollOffset = [coder decodeObjectForKey:@"sectionScrollOffset"];
    self.windowSettings = [coder decodeObjectForKey:@"windowSettings"];
    self.date = [coder decodeObjectForKey:@"date"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:currentSectionPath forKey:@"currentSectionPath"];
    [coder encodeObject:sectionScrollOffset forKey:@"sectionScrollOffset"];
    [coder encodeObject:windowSettings forKey:@"windowSettings"];
    [coder encodeObject:date forKey:@"date"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: {date: %@, currentSectionPath: '%@', \
sectionScrollOffset: %@, windowSettings: %@}", 
            [super description], date, currentSectionPath, sectionScrollOffset, 
            windowSettings];
}

- (void)dealloc {
    self.date = nil;
    self.currentSectionPath = nil;
    self.sectionScrollOffset = nil;
    
    self.windowSettings = nil;
    
    [super dealloc];
}

@end
