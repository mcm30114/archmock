#import <Cocoa/Cocoa.h>


@interface CHMDocumentSettings : NSObject <NSCoding> {
    NSString *currentSectionPath;
}

@property (retain) NSString *currentSectionPath;

+ (CHMDocumentSettings *)settingsWithCurrentSectionPath:(NSString *)currentSectionPath;

- (id)initWithCurrentSectionPath:(NSString *)initCurrentSectionPath;

@end
