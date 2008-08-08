#import <Cocoa/Cocoa.h>
#import "CHMDocumentWindowSettings.h"
#import "CHMContentViewSettings.h"

@interface CHMDocumentSettings : NSObject <NSCoding> {
    NSString *currentSectionPath;
    NSDate *date;
    
    // XXX: Deprecated since 1.2. Moved to CHMContentViewSettings as scrollOffset
    NSString *currentSectionScrollOffset;
    
    CHMContentViewSettings *contentViewSettings;
    CHMDocumentWindowSettings *windowSettings;
}

// XXX: Deprecated since 1.2. Moved to CHMContentViewSettings as scrollOffset
@property (retain) NSString *currentSectionScrollOffset;

@property (retain) NSString *currentSectionPath;
@property (retain) NSDate *date;

@property (retain) CHMContentViewSettings *contentViewSettings;
@property (retain) CHMDocumentWindowSettings *windowSettings;

+ (CHMDocumentSettings *)settingsWithCurrentSectionPath:(NSString *)currentSectionPath contentViewSettings:(CHMContentViewSettings *)contentViewSettings windowSettings:(CHMDocumentWindowSettings *)windowSettings;

- (id)initWithCurrentSectionPath:(NSString *)initCurrentSectionPath contentViewSettings:(CHMContentViewSettings *)initContentViewSettings windowSettings:(CHMDocumentWindowSettings *)initWindowSettings;
    
@end
