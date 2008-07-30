#import "CHMIndex.h"
#import "NSData-CHMChunks.h"

@implementation CHMIndex

@synthesize containerID;

@synthesize indexData, sectionsData, stringsData, urlTableData, urlStringsData;    

@synthesize docIndexScale,    countScale,    locationScale;
@synthesize docIndexRootSize, countRootSize, locationRootSize;

@synthesize leafNodeOffset, nodeLength, treeDepth;

+ (CHMIndex *)indexWithContainer:(CHMContainer *)container {
    return [[[CHMIndex alloc] initWithContainer:container] autorelease];
}

- (id)initWithContainer:(CHMContainer *)container {
    if (self = [super init]) {
        if (![container doesObjectWithPathExist:@"/$FIftiMain"] || 
            ![container doesObjectWithPathExist:@"/#TOPICS"]    ||
            ![container doesObjectWithPathExist:@"/#STRINGS"]   ||
            ![container doesObjectWithPathExist:@"/#URLTBL"]    ||
            ![container doesObjectWithPathExist:@"/#URLSTR"]) {
            
            NSLog(@"WARN: At least one of required index objects not found");
            return nil;
        }
        
        self.indexData = [container dataForObjectWithPath:@"/$FIftiMain" offset:0 length:0];
        
        self.docIndexScale = [indexData shortFromOffset:0x1E];
        self.countScale = [indexData shortFromOffset:0x20];
        self.locationScale = [indexData shortFromOffset:0x22];
        
        if (docIndexScale != 2 || 
            countScale != 2 ||
            locationScale != 2) {
            NSLog(@"WARN: Unsupported index type");
            return nil;
        }
        
        self.containerID = container.uniqueID;
        
        self.docIndexRootSize = [indexData shortFromOffset:0x1F];
        self.countRootSize = [indexData shortFromOffset:0x21];
        self.locationRootSize = [indexData shortFromOffset:0x23];

        self.leafNodeOffset = [indexData longFromOffset:0x08];
        self.nodeLength = [indexData longFromOffset:0x2E];
        self.treeDepth = [indexData shortFromOffset:0x18];
        
        self.sectionsData = [container dataForObjectWithPath:@"/#TOPICS" offset:0 length:0];
        self.stringsData = [container dataForObjectWithPath:@"/#STRINGS" offset:0 length:0];
        self.urlTableData = [container dataForObjectWithPath:@"/#URLTBL" offset:0 length:0];
        self.urlStringsData = [container dataForObjectWithPath:@"/#URLSTR" offset:0 length:0];
        
//        NSLog(@"INFO: All index objects are loaded successfully");
    }
    
    return self;
}

- (void)searchForTextChunk:(NSString *)textChunk 
              forOperation:(CHMSearchOperation *)operation {
    NSLog(@"INFO: Searching through index for text: '%@'", textChunk);
    
    u_int32_t currentOffset = [self firstIndexWordNodeOffset];

    if (!currentOffset) {
        NSLog(@"WARN: Offset for leaf node not found");
        return;
    }
    
    NSString *indexWord;
    do {
        NSData *leafNodeData = [indexData dataFromOffset:currentOffset 
                                                  length:nodeLength]; 
        
        if (!leafNodeData) {
            NSLog(@"WARN: Leaf node with offset '%02X' not found", currentOffset);
            return;
        }
//        NSLog(@"DEBUG: Leaf node offset: '%02X'", currentOffset);
        currentOffset = [leafNodeData longFromOffset:0x0];
//        NSLog(@"DEBUG: Next leaf node offset: '%02X'", currentOffset);
        
        u_int32_t nodeEntryOffset = sizeof(u_int32_t) + sizeof(u_int16_t) + sizeof(u_int16_t);
        u_int16_t freeSpaceLength = [leafNodeData shortFromOffset:0x6];
        
        // WLC - Word Location Codes
        while (nodeEntryOffset < nodeLength - freeSpaceLength) {
            if ([operation isCancelled]) {
                return;
            }
            
            long long wordPartLength = 0;
            indexWord = [leafNodeData indexWordFromOffset:nodeEntryOffset 
                                             previousWord:indexWord 
                                           wordPartLength:&wordPartLength];
            nodeEntryOffset += 2 + wordPartLength;
//            unsigned char isTitle = [leafNodeData charFromOffset:nodeEntryOffset - 1];
//            NSLog(@"DEBUG: Index word: '%@', is title: '%i'", indexWord, isTitle);
            
            long long wlcRecordLength = 0;
            u_int64_t wlcCount = [leafNodeData encodedIntegerFromOffset:nodeEntryOffset 
                                                         readDataLength:&wlcRecordLength];
            nodeEntryOffset += wlcRecordLength;
            
            u_int32_t wlcOffset = [leafNodeData longFromOffset:nodeEntryOffset];
            
            nodeEntryOffset += sizeof(u_int32_t) + sizeof(u_int16_t);
            
            u_int64_t wlcBlockLength = [leafNodeData encodedIntegerFromOffset:nodeEntryOffset
                                                               readDataLength:&wlcRecordLength];
            nodeEntryOffset += wlcRecordLength;

            if ([operation isCancelled]) {
                return;
            }
            if (nil != indexWord && 
                NSNotFound != [indexWord rangeOfString:textChunk 
                                               options:NSCaseInsensitiveSearch].location) {
                //                NSLog(@"DEBUG: Index word found '%@' while searching for partial words", indexWord);
                [self processWLCBlockWithCount:wlcCount 
                                        offset:wlcOffset
                                        length:wlcBlockLength 
                                     indexWord:indexWord 
                                     operation:operation];
            }
        }
    } while(![operation isCancelled] && currentOffset);
    
//    NSLog(@"DEBUG: Done searching through index for text chunk '%@'", textChunk);
}

- (u_int32_t)indexWordNodeOffsetForTextChunk:(NSString *)textChunk {
//    NSLog(@"DEBUG: Searching for leaf node for text chunk: '%@', node length: '%02X', tree depth: '%i'", textChunk, nodeLength, treeDepth);
    
    u_int32_t indexNodeOffset = leafNodeOffset;
    u_int16_t currentTreeDepth = treeDepth;
    NSString *indexWord;
    while (--currentTreeDepth) {
//        NSLog(@"DEBUG: Testing node with offset: '%02X', depth: '%i'", indexNodeOffset, currentTreeDepth);
        
        NSData *indexNodeData = [indexData dataFromOffset:indexNodeOffset length:nodeLength]; 
        
        
        u_int16_t freeSpaceLength = [indexNodeData shortFromOffset:0];
//        NSLog(@"DEBUG: freeSpaceLength: '%02X'", freeSpaceLength);
        u_int32_t nodeEntryOffset = sizeof(u_int16_t);
        while (nodeEntryOffset < nodeLength - freeSpaceLength) {
            //            NSLog(@"DEBUG: entryOffset: '%02X'", entryOffset);
            long long wordPartLength = 0;
            indexWord = [indexNodeData indexWordFromOffset:nodeEntryOffset 
                                              previousWord:indexWord 
                                            wordPartLength:&wordPartLength];
            if ([textChunk caseInsensitiveCompare:indexWord] <= 0) {
//                NSLog(@"INFO: Greater index word found: '%@'", indexWord);
                indexNodeOffset = [indexNodeData longFromOffset:nodeEntryOffset + wordPartLength + 1];
                break;
            }
            //           NSLog(@"DEBUG: Lesser index word: '%@'", indexWord);
            nodeEntryOffset += wordPartLength + sizeof(unsigned char) + sizeof(u_int32_t) + sizeof(u_int16_t);
        }
    }
    
    if (leafNodeOffset == indexNodeOffset) {
        return 0;
    }
    
    return indexNodeOffset;
}

- (u_int32_t)firstIndexWordNodeOffset {
    
    u_int32_t indexNodeOffset = leafNodeOffset;
    u_int16_t currentTreeDepth = treeDepth;
    NSString *indexWord;
    while (--currentTreeDepth) {
//        NSLog(@"DEBUG: Testing node with offset: '%02X', depth: '%i'", indexNodeOffset, currentTreeDepth);
        
        NSData *indexNodeData = [indexData dataFromOffset:indexNodeOffset 
                                                   length:nodeLength]; 
        u_int16_t freeSpaceLength = [indexNodeData shortFromOffset:0];
//        NSLog(@"DEBUG: freeSpaceLength: '%04X'", freeSpaceLength);
        u_int32_t nodeEntryOffset = sizeof(u_int16_t);
        if (nodeEntryOffset < nodeLength - freeSpaceLength) {
//            NSLog(@"DEBUG: nodeEntryOffset: '%04X'", nodeEntryOffset);
            long long wordPartLength = 0;
            indexWord = [indexNodeData indexWordFromOffset:nodeEntryOffset 
                                              previousWord:indexWord 
                                            wordPartLength:&wordPartLength];
//            NSLog(@"DEBUG: Index word: '%@'", indexWord);
            indexNodeOffset = [indexNodeData longFromOffset:nodeEntryOffset + wordPartLength + 1];
            if (indexNodeOffset != leafNodeOffset) {
                return indexNodeOffset;
            }
        }
    }
    
    return 0;
}


- (void)processWLCBlockWithCount:(u_int64_t)documentsCount 
                          offset:(u_int32_t)blockOffset 
                          length:(u_int64_t)blockLength
                       indexWord:(NSString *)indexWord
                       operation:(CHMSearchOperation *)operation {
    
    int currentBit = 7;
    u_int64_t sectionIndex = 0;
    long currentOffset = 0;
    long long readDataLength = 0;
    
    NSData *wlcData = [indexData dataFromOffset:blockOffset length:blockLength];
    
    for (u_int64_t i = 0; i < documentsCount; i++) {
        if (currentBit != 7) {
            currentOffset++;
            currentBit = 7;
        }
        
        sectionIndex += [wlcData decodeIntegerFromOffset:currentOffset 
                                                 scale:docIndexScale
                                              rootSize:docIndexRootSize
                                                   bit:&currentBit
                                        readDataLength:&readDataLength];
        currentOffset += readDataLength;
        NSData *sectionData = [sectionsData dataFromOffset:sectionIndex * 16
                                                    length:16];
        
        if (!sectionData) {
            NSLog(@"WARN: Section data not found");
            continue;
        }
        
        u_int32_t labelStringOffset = [sectionData longFromOffset:4];
        NSString *sectionLabel = -1 == labelStringOffset ? nil : [stringsData stringFromOffset:labelStringOffset];
//        NSLog(@"DEBUG: Section label: '%@'", sectionLabel);
        
        u_int32_t urlTableOffset = [sectionData longFromOffset:8];
        NSData *urlData = [urlTableData dataFromOffset:urlTableOffset 
                                                length:12];
        
        if (!urlData) {
            NSLog(@"WARN: URL table data not found");
            continue;
        }
        
        u_int32_t pathStringOffset = [urlData longFromOffset:8];
        NSString *sectionPath = [urlStringsData stringFromOffset:pathStringOffset + 8   ];
        
//        NSLog(@"DEBUG: Section path: '%@'", sectionPath);
        
        uint64_t occurencesCount = [wlcData decodeIntegerFromOffset:currentOffset 
                                                              scale:countScale
                                                           rootSize:countRootSize
                                                                bit:&currentBit
                                                     readDataLength:&readDataLength];
//        NSLog(@"DEBUG: Occurences in document: '%i'", occurencesCount);
        currentOffset += readDataLength;
        
        [operation foundWord:indexWord
            occurencesNumber:occurencesCount
                sectionLabel:sectionLabel
                 sectionPath:sectionPath];
        
        if ([operation isCancelled]) {
            return;
        }
        
        for (int j = 0; j < occurencesCount; j++) {
            // TODO: find out how to interpret
            NSUInteger locationInDocument = [wlcData decodeIntegerFromOffset:currentOffset 
                                                                       scale:locationScale
                                                                    rootSize:locationRootSize
                                                                         bit:&currentBit
                                                              readDataLength:&readDataLength];
            //            NSLog(@"DEBUG: Location in document: '%i'", locationInDocument);
            currentOffset += readDataLength;
            
        }
    }
}

- (void)dealloc {
    self.containerID = nil;
    self.indexData = nil;
    self.sectionsData = nil;
    self.stringsData = nil;
    self.urlTableData = nil;
    self.urlStringsData = nil;
    
    [super dealloc];
}

@end
