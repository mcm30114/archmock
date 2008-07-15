#import <Cocoa/Cocoa.h>
#import "BDAlias.h"
#import "CHMDocumentSettings.h"

@interface CHMBookmark : NSObject <NSCoding> {
    NSString *label;
    NSString *sectionLabel;
    
    CHMDocumentSettings *documentSettings;

    NSString *filePath;
    BDAlias *fileAlias;
}

@property (retain) NSString *label;
@property (retain) NSString *sectionLabel;
@property (retain) NSString *filePath;
@property (retain) CHMDocumentSettings *documentSettings;
@property (retain) BDAlias *fileAlias;

@property (readonly) NSString *fileRelativePath;

+ (CHMBookmark *)bookmarkWithLabel:(NSString *)label 
                          filePath:(NSString *)filePath
                      sectionLabel:(NSString *)sectionLabel
                       documentSettings:(CHMDocumentSettings *)documentSettings;
    
- (id)initWithLabel:(NSString *)initLabel
           filePath:(NSString *)initFilePath
       sectionLabel:(NSString *)initSectionLabel
        documentSettings:(CHMDocumentSettings *)documentSettings;

- (NSString *)locateFile;

- (BOOL)isValid;
    
@end
