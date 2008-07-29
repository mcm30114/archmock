#import "CHMContainer.h"
#import "NSData-CHMChunks.h"
#import "SSCrypto.h"
#import "chm_lib.h"
#import <CoreFoundation/CoreFoundation.h>

#define INVALID_ENCODING 65536

@implementation CHMContainer

@synthesize filePath, homeSectionPath, uniqueID, systemData, stringsData, windowsData;
@synthesize encoding;

@dynamic title;

+ (CHMContainer *)containerWithFilePath:(NSString *)filePath {
    return [[[CHMContainer alloc] initWithFilePath:filePath] autorelease];
}

- (id)initWithFilePath:(NSString*)path {
    if (self = [super init]) {
        self.filePath = path;
        //        NSLog(@"Opening CHM file '%@'", filePath);
        fileHandle = chm_open([filePath fileSystemRepresentation]);
        
        if (!fileHandle) {
            NSLog(@"ERROR: Can't open CHM file '%@'", filePath);
            return nil;
        }
        
        self.systemData = [self dataForObjectWithPath:@"/#SYSTEM"];
        if (!systemData) {
            NSLog(@"ERROR: Can't open CHM file: can't find #SYSTEM object");
            return nil;
        }
        
        self.uniqueID = [[SSCrypto getSHA1ForData:systemData] hexval];
        
        self.windowsData = [self dataForObjectWithPath:@"/#WINDOWS"];
        self.stringsData = [self dataForObjectWithPath:@"/#STRINGS"];
        
        self.homeSectionPath = [self findHomeSectionPath];
        self.encoding = [self findEncoding];
        if (self.homeSectionPath) {
//            NSLog(@"INFO: Home section path: '%@'", homeSectionPath);
        }
        else {
            NSLog(@"WARN: Can't locate home section path");
        }
        
        //        NSLog(@"Successfully opened CHM file '%@'", path);
    }
    return self;
}

- (NSUInteger)findEncoding {
    unsigned long lcidEncoding = [self findMetadataCharInSystemObjectWithOffset:0x4];
//    NSLog(@"DEBUG: LCID encoding: 0x%04x", lcidEncoding);
    
    switch (lcidEncoding) {
        case 0x0436:
        case 0x042d:
        case 0x0403:
        case 0x0406:
        case 0x0413:
        case 0x0813:
        case 0x0409:
        case 0x0809:
        case 0x0c09:
        case 0x1009:
        case 0x1409:
        case 0x1809:
        case 0x1c09:
        case 0x2009:
        case 0x2409:
        case 0x2809:
        case 0x2c09:
        case 0x3009:
        case 0x3409:
        case 0x0438:
        case 0x040b:
        case 0x040c:
        case 0x080c:
        case 0x0c0c:
        case 0x100c:
        case 0x140c:
        case 0x180c:
        case 0x0407:
        case 0x0807:
        case 0x0c07:
        case 0x1007:
        case 0x1407:
        case 0x040f:
        case 0x0421:
        case 0x0410:
        case 0x0810:
        case 0x043e:
        case 0x083e:
        case 0x0414:
        case 0x0814:
        case 0x0416:
        case 0x0816:
        case 0x040a:
        case 0x080a:
        case 0x0c0a:
        case 0x100a:
        case 0x140a:
        case 0x180a:
        case 0x1c0a:
        case 0x200a:
        case 0x240a:
        case 0x280a:
        case 0x2c0a:
        case 0x300a:
        case 0x340a:
        case 0x380a:
        case 0x3c0a:
        case 0x400a:
        case 0x440a:
        case 0x480a:
        case 0x4c0a:
        case 0x500a:
        case 0x0441:
        case 0x041d:
        case 0x081d:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin1);
        case 0x041c:
        case 0x041a:
        case 0x0405:
        case 0x040e:
        case 0x0415:
        case 0x0418:
        case 0x081a:
        case 0x041b:
        case 0x0424:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin2);
        case 0x0401:
        case 0x0801:
        case 0x0c01:
        case 0x1001:
        case 0x1401:
        case 0x1801:
        case 0x1c01:
        case 0x2001:
        case 0x2401:
        case 0x2801:
        case 0x2c01:
        case 0x3001:
        case 0x3401:
        case 0x3801:
        case 0x3c01:
        case 0x4001:
        case 0x0429:
        case 0x0420:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinArabic);
        case 0x0408:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinGreek);
        case 0x040d:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinHebrew);
        case 0x042c:
        case 0x041f:
        case 0x0443:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin5);
        case 0x041e:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinThai);
        case 0x0425:
        case 0x0426:
        case 0x0427:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin7);
        case 0x082c:
        case 0x0423:
        case 0x0402:
        case 0x043f:
        case 0x042f:
        case 0x0419:
        case 0x0c1a:
        case 0x0444:
        case 0x0422:
        case 0x0843:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsCyrillic);
        case 0x0404:
        case 0x0c04:
        case 0x1404:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSChineseTrad);
        case 0x0804:
        case 0x1004:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSChineseSimplif);
        case 0x0411:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese);
        case 0x0412:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSKorean);
        case 0x042a:
            return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsVietnamese);
        default:
            break;
    }
    
    return INVALID_ENCODING;
}

- (NSString *)findHomeSectionPath {
    NSString *pathFromMetadata = [self findMetadataStringInSystemObjectWithOffset:2
                                                      orInStringsObjectWithOffset:0x68];
    if (![pathFromMetadata isEqualToString:@""] 
        && ([self doesObjectWithPathExist:pathFromMetadata]
        || [self doesObjectWithPathExist:[NSString stringWithFormat:@"/%@", pathFromMetadata]])) {
        return pathFromMetadata;
    }
    
    NSArray *testPaths = [NSArray arrayWithObjects:@"/index.html", 
                          @"/default.html", 
                          @"/index.htm", 
                          @"/default.htm", nil];
    for (NSString *testPath in testPaths) {
        if ([self doesObjectWithPathExist:testPath]) {
            return [testPath stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
    }
    
    return nil;
}

- (NSString *)constructURLForObjectWithPath:(NSString *)path {
    return [NSString stringWithFormat:@"chm://%@/%@", uniqueID, path];
}

- (NSString *)title {
    NSString *title = [[self findMetadataStringInStringsObjectWithOffset:0x14] 
                       stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (title && 0 != [title length]) {
//        NSLog(@"DEBUG: Title found in #STRINGS: '%@'", title);
        return title;
    }
    
    title = [[self findMetadataStringInSystemObjectWithOffset:3] 
             stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (title && 0 != [title length]) {
//        NSLog(@"DEBUG: Title found in #SYSTEM: '%@'", title);
        return title;
    }
    
    return nil;
}

- (NSString *)indexPath {
    return [self findMetadataStringInSystemObjectWithOffset:1
                                orInStringsObjectWithOffset:0x64];
}

- (NSString *)findMetadataStringInSystemObjectWithOffset:(unsigned long)systemObjectOffset 
                             orInStringsObjectWithOffset:(unsigned long)stringsObjectOffset {
    NSString *metadataString;
    if ((metadataString = [self findMetadataStringInSystemObjectWithOffset:systemObjectOffset])
        && 0 != [metadataString length]) {
        return metadataString;
    }
    return [self findMetadataStringInStringsObjectWithOffset:stringsObjectOffset];
}

- (NSString *)findMetadataStringInSystemObjectWithOffset:(unsigned long)offset {
    unsigned int maxOffset = [systemData length];
    
    NSString *string;
    for (unsigned int currentOffset = 0; 
         currentOffset < maxOffset; 
         currentOffset += [systemData shortFromOffset:currentOffset + 2] + 4) {
        unsigned int currentMetadataOffset = [systemData shortFromOffset:currentOffset];
        if (offset == currentMetadataOffset && (string = [systemData stringFromOffset:currentOffset + 4])) {
            return string;
        }
    }
    
    return nil;
}

- (unsigned long)findMetadataCharInSystemObjectWithOffset:(unsigned long)offset {
    unsigned int maxOffset = [systemData length];
    
    for (unsigned int currentOffset = 0; 
         currentOffset < maxOffset; 
         currentOffset += [systemData shortFromOffset:currentOffset + 2] + 4) {
        unsigned int currentMetadataOffset = [systemData shortFromOffset:currentOffset];
        if (offset == currentMetadataOffset) {
            return [systemData longFromOffset:currentOffset + 4];
        }
    }
    
    return 0x0;
}

- (NSString *)findMetadataStringInStringsObjectWithOffset:(unsigned long)offset {
    if (windowsData && stringsData) {
        unsigned long entryCount = [windowsData longFromOffset:0];
        unsigned long entrySize = [windowsData longFromOffset:4];
        
        NSString *string;
        for (int entryIndex = 0; entryIndex < entryCount; entryIndex++) {
            unsigned long entryOffset = 8 + ( entryIndex * entrySize );
            if (string = [stringsData stringFromOffset:[windowsData longFromOffset:entryOffset + offset]]) {
                return string;
            }
        }
    }
    
    return nil;
}

- (BOOL)doesObjectWithPathExist:(NSString *)path {
    //    NSLog(@"DEBUG: Check if object with path '%@' exists", path);
    if (!path) {
        NSLog(@"WARN: Invalid path: '%@'", path);
        
        return NO;
    }
    struct chmUnitInfo unitInfo;
    return CHM_RESOLVE_SUCCESS == chm_resolve_object(fileHandle, 
                                                     [path UTF8String], 
                                                     &unitInfo);
}

- (NSData *)dataForObjectWithPath:(NSString *)path {
    return [self dataForObjectWithPath:path offset:0 length:0];
}


- (NSData *)dataForObjectWithPath:(NSString *)path 
                           offset:(unsigned long long)offset
                           length:(long long)length {
//    NSLog(@"DEBUG: Object with path '%@' requested. Offset: '%02qX', length: '%02qX'", path, offset, length);
    
    struct chmUnitInfo unitInfo;
    if (CHM_RESOLVE_SUCCESS != 
        chm_resolve_object(fileHandle, [path UTF8String], &unitInfo)) {
        NSLog(@"WARN: Object with path '%@' not found", path);
        return nil;
    }
    
    if (length <= 0) {
        length = unitInfo.length;
    }
    
    void *buffer = malloc(length);
    if (!buffer) {
        NSLog(@"ERROR: Failed to allocate buffer '%qu' bytes long for object data '%@'", length, path);
        return nil;
    }
    
    if (!chm_retrieve_object(fileHandle, 
                             &unitInfo, 
                             buffer, 
                             offset, 
                             length)) {
        NSLog(@"ERROR: Failed to load object data '%@' '%qi' bytes long", path, length);
        free(buffer);
        
        return nil;
    }
    
    //    NSLog(@"INFO: Object data with path '%@' loaded successfully", path); 
    return [[[NSData alloc] initWithBytesNoCopy:buffer 
                                         length:length 
                                   freeWhenDone:YES] autorelease];
}

//- (id)retain {
//    [super retain];
//    NSLog(@"DEBUG: Retaining CHM container: retain count: %i, %@", [self retainCount], self);
//    return self;
//}
//
//- (oneway void)release {
//    NSLog(@"DEBUG: Releasing CHM container: retain count: %i, %@", [self retainCount], self);
//    [super release];
//}

- (void)dealloc {
//    NSLog(@"DEBUG: Deallocating CHMContainer");
    
    if (fileHandle) {
        chm_close(fileHandle);
    }
    
    self.filePath = nil;
    self.uniqueID = nil;
    self.homeSectionPath = nil;
    
    self.systemData = nil;
    self.stringsData = nil;
    self.windowsData = nil;
    
    [super dealloc];
}

@end
