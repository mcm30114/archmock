#import <Cocoa/Cocoa.h>
#import "CHMDocumentWindowSettings.h"

@interface CHMDocumentSettings : NSObject <NSCoding> {
    NSString *currentSectionPath;
    NSString *currentSectionScrollOffset;
    NSDate *date;
    
    CHMDocumentWindowSettings *windowSettings;
}

@property (retain) NSString *currentSectionPath;
@property (retain) NSString *currentSectionScrollOffset;
@property (retain) NSDate *date;

@property (retain) CHMDocumentWindowSettings *windowSettings;

+ (CHMDocumentSettings *)settingsWithCurrentSectionPath:(NSString *)currentSectionPath 
                                    sectionScrollOffset:(NSString *)sectionScrollOffset
                                         windowSettings:(CHMDocumentWindowSettings *)windowSettings;

- (id)initWithCurrentSectionPath:(NSString *)initCurrentSectionPath
             sectionScrollOffset:(NSString *)initSectionScrollOffset
                  windowSettings:(CHMDocumentWindowSettings *)initWindowSettings;
    
@end
