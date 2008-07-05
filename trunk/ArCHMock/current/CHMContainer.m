#import "CHMContainer.h"
#import "NSData-CHMChunks.h"
#import "chm_lib.h"
#include <openssl/sha.h>

@implementation CHMContainer

@synthesize filePath, homeSectionPath, uniqueID, systemData, stringsData, windowsData;
@dynamic title;

static NSMutableDictionary *containersByUniqueID;

+ (void)initialize {
    [super initialize];
    containersByUniqueID = [NSMutableDictionary new];
}

+ (CHMContainer *)containerWithFilePath:(NSString *)filePath {
    return [[[CHMContainer alloc] initWithFilePath:filePath] autorelease];
}

+ (NSMutableDictionary *)containersByUniqueID {
    return containersByUniqueID;
}

+ (void)dealloc {
    [containersByUniqueID release];
    
    [super dealloc];
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
            NSLog(@"ERROR: Can't open CHM file: can't find SYSTEM object");
            return nil;
        }
        
        unsigned char digest[SHA_DIGEST_LENGTH];
        SHA1([systemData bytes], [systemData length], digest);
        unsigned int *digestInt = (unsigned int *)digest;
        uniqueID = [[NSString alloc] initWithFormat:@"%x%x%x%x%x", digestInt[0], 
                    digestInt[1], digestInt[2], digestInt[3], digestInt[4]];
        
        self.windowsData = [self dataForObjectWithPath:@"/#WINDOWS"];
        self.stringsData = [self dataForObjectWithPath:@"/#STRINGS"];
        
        self.homeSectionPath = [self locateHomeSectionPath];
        if (self.homeSectionPath) {
//            NSLog(@"INFO: Home section path: '%@'", homeSectionPath);
        }
        else {
            NSLog(@"WARN: Can't locate home section path");
        }
        
        // TODO: Check if dictionary is really necessary
        [[CHMContainer containersByUniqueID] setObject:self forKey:uniqueID];
        
        //        NSLog(@"Successfully opened CHM file '%@'", path);
    }
    return self;
}

- (NSString *)locateHomeSectionPath {
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
    for (int i = 0; i < [testPaths count]; i++) {
        NSString *testPath = [testPaths objectAtIndex:i];
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

- (NSString *)findMetadataStringInStringsObjectWithOffset:(unsigned long)offset {
    if (windowsData && stringsData) {
        unsigned long entryCount = [windowsData longFromOffset:0];
        unsigned long entrySize  = [windowsData longFromOffset:4];
        
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

- (void)dealloc {
    if (fileHandle) {
        chm_close(fileHandle);
        //        NSLog(@"DEBUG: CHM file '%@' closed", self.filePath);
    }
    
    self.filePath = nil;
    self.uniqueID = nil;
    self.homeSectionPath = nil;
    
    self.systemData  = nil;
    self.stringsData = nil;
    self.windowsData = nil;
    
    [super dealloc];
}

@end
