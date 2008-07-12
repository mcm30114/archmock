#import <Cocoa/Cocoa.h>
#import "BDAlias.h"

@interface CHMBookmark : NSObject <NSCoding> {
    NSString *label;
    NSString *sectionLabel;
    NSString *sectionPath;
    NSString *filePath;
    
    BDAlias *fileAlias;
}

@property (retain) NSString *label;
@property (retain) NSString *sectionLabel;
@property (retain) NSString *filePath;
@property (retain) NSString *sectionPath;
@property (retain) BDAlias *fileAlias;

@property (readonly) NSString *fileRelativePath;
@property (readonly) NSColor *filePathColor;

+ (CHMBookmark *)bookmarkWithLabel:(NSString *)label 
                          filePath:(NSString *)filePath
                      sectionLabel:(NSString *)sectionLabel
                       sectionPath:(NSString *)sectionPath;
    
- (id)initWithLabel:(NSString *)initLabel
           filePath:(NSString *)initFilePath
       sectionLabel:(NSString *)initSectionLabel
        sectionPath:(NSString *)initSectionPath;
    
@end
