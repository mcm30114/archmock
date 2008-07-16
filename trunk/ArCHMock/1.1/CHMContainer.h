#import <Cocoa/Cocoa.h>

@interface CHMContainer : NSObject {
    struct chmFile *fileHandle;
    NSString *filePath;
    NSString *homeSectionPath;
    NSString *uniqueID;
    
    NSData *systemData;
    NSData *stringsData;
    NSData *windowsData;
}

@property (retain) NSString *filePath, *uniqueID;
@property (retain) NSData *systemData, *stringsData, *windowsData;

@property (readonly) NSString *title;
@property (retain) NSString *homeSectionPath;

+ (CHMContainer *)containerWithFilePath:(NSString*)filePath;

- (id)initWithFilePath:(NSString *)path;

- (NSString *)locateHomeSectionPath;

- (BOOL)doesObjectWithPathExist:(NSString *)path;
    
- (NSString *)constructURLForObjectWithPath:(NSString *)path;

- (NSString *)findMetadataStringInSystemObjectWithOffset:(unsigned long)systemUnitOffset 
                             orInStringsObjectWithOffset:(unsigned long)stringsUnitOffset;

- (NSString *)findMetadataStringInSystemObjectWithOffset:(unsigned long)offset;

- (NSString *)findMetadataStringInStringsObjectWithOffset:(unsigned long)offset;

- (NSData *)dataForObjectWithPath:(NSString *)path;

- (NSData *)dataForObjectWithPath:(NSString *)path 
                           offset:(unsigned long long)offset 
                           length:(long long)length;

@end
