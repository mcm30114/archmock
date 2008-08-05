#import "CHMDocumentSettings.h"


@implementation CHMDocumentSettings

@synthesize currentSectionPath;
@synthesize date;

@synthesize contentViewSettings;
@synthesize windowSettings;

// XXX: Deprecated since 1.2. Moved to CHMContentViewSettings as scrollOffset
@synthesize currentSectionScrollOffset;

+ (CHMDocumentSettings *)settingsWithCurrentSectionPath:(NSString *)currentSectionPath contentViewSettings:(CHMContentViewSettings *)contentViewSettings windowSettings:(CHMDocumentWindowSettings *)windowSettings {
    return [[[CHMDocumentSettings alloc] initWithCurrentSectionPath:currentSectionPath contentViewSettings:contentViewSettings windowSettings:windowSettings] autorelease];
}

- (id)initWithCurrentSectionPath:(NSString *)initCurrentSectionPath contentViewSettings:(CHMContentViewSettings *)initContentViewSettings windowSettings:(CHMDocumentWindowSettings *)initWindowSettings {
    if (self = [super init]) {
        self.currentSectionPath = initCurrentSectionPath;
        self.contentViewSettings = initContentViewSettings;
        self.windowSettings = initWindowSettings;
        self.date = [NSDate date];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    [super init];
    
    self.currentSectionPath = [coder decodeObjectForKey:@"currentSectionPath"];
    self.contentViewSettings = [coder decodeObjectForKey:@"contentViewSettings"];
    self.windowSettings = [coder decodeObjectForKey:@"windowSettings"];
    self.date = [coder decodeObjectForKey:@"date"];

    // XXX: Deprecated since 1.2. Moved to CHMContentViewSettings as scrollOffset
    self.currentSectionScrollOffset = [coder decodeObjectForKey:@"currentSectionScrollOffset"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:currentSectionPath forKey:@"currentSectionPath"];
    [coder encodeObject:contentViewSettings forKey:@"contentViewSettings"];
    [coder encodeObject:windowSettings forKey:@"windowSettings"];
    [coder encodeObject:date forKey:@"date"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: {date: %@, currentSectionPath: '%@', contentViewSettings: %@, windowSettings: %@}", [super description], date, currentSectionPath, contentViewSettings, windowSettings];
}

- (void)dealloc {
    self.date = nil;
    self.currentSectionPath = nil;
    self.contentViewSettings = nil;
    self.windowSettings = nil;
    
    // XXX: Deprecated since 1.2. Moved to CHMContentViewSettings as scrollOffset
    self.currentSectionScrollOffset = nil;
    
    [super dealloc];
}

@end
