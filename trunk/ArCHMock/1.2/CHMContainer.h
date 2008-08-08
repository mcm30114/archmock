#import <Cocoa/Cocoa.h>

@interface CHMContainer : NSObject {
    BOOL encodingAvailable;
    struct chmFile *fileHandle;
    NSString *filePath;
    NSString *title;
    NSString *homeSectionPath;
    NSString *uniqueID;
    
    NSData *systemData;
    NSData *stringsData;
    NSData *windowsData;
    
    NSUInteger encoding;
}

@property BOOL encodingAvailable;
@property (retain) NSString *filePath, *uniqueID;
@property (retain) NSData *systemData, *stringsData, *windowsData;

@property (retain) NSString *title;
@property (retain) NSString *homeSectionPath;

@property NSStringEncoding encoding;
@property (readonly) NSString *encodingName;

+ (CHMContainer *)containerWithFilePath:(NSString*)filePath;
- (id)initWithFilePath:(NSString *)path;

- (NSStringEncoding)findEncoding;
- (NSString *)findHomeSectionPathWithEncoding:(NSStringEncoding)encoding;
- (NSString *)findTitleWithEncoding:(NSStringEncoding)encoding;

- (BOOL)doesObjectWithPathExist:(NSString *)path;
    
- (NSString *)constructURLForObjectWithPath:(NSString *)path;
- (NSString *)findMetadataStringWithEncoding:(NSStringEncoding)encoding inSystemObjectWithOffset:(unsigned long)systemUnitOffset orInStringsObjectWithOffset:(unsigned long)stringsUnitOffset;

- (NSString *)findMetadataStringWithEncoding:(NSStringEncoding)encoding inSystemObjectWithOffset:(unsigned long)offset;
- (unsigned long)findMetadataCharInSystemObjectWithOffset:(unsigned long)offset;
- (NSString *)findMetadataStringWithEncoding:(NSStringEncoding)encoding inStringsObjectWithOffset:(unsigned long)offset;

- (NSData *)dataForObjectWithPath:(NSString *)path;
- (NSData *)dataForObjectWithPath:(NSString *)path offset:(unsigned long long)offset length:(long long)length;

- (NSString *)decodeString:(NSString *)string;

@end
