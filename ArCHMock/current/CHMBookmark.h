#import <Cocoa/Cocoa.h>
#import "BDAlias.h"

@interface CHMBookmark : NSObject <NSCoding> {
    NSString *label;
    NSString *sectionLabel;
    NSString *sectionPath;
    NSString *filePath;
    NSString *containerID;
    
    BDAlias *fileAlias;
}

@property (retain) NSString *label;
@property (retain) NSString *sectionLabel;
@property (retain) NSString *filePath;
@property (retain) NSString *sectionPath;
@property (retain) NSString *containerID;
@property (retain) BDAlias *fileAlias;

@property (readonly) NSString *fileRelativePath;

+ (CHMBookmark *)bookmarkWithLabel:(NSString *)label 
                          filePath:(NSString *)filePath
                      sectionLabel:(NSString *)sectionLabel
                       sectionPath:(NSString *)sectionPath;
    
- (id)initWithLabel:(NSString *)initLabel
           filePath:(NSString *)initFilePath
       sectionLabel:(NSString *)initSectionLabel
        sectionPath:(NSString *)initSectionPath;

- (NSString *)locateFile;

- (BOOL)isValid;
    
@end
