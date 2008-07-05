#import <Cocoa/Cocoa.h>
#import "CHMContainer.h";
#import "CHMSearchOperation.h";


@interface CHMIndex : NSObject {
    NSString *containerID;
    
    unsigned char docIndexScale,    countScale,    locationScale,
                  docIndexRootSize, countRootSize, locationRootSize;
    
    u_int32_t leafNodeOffset, nodeLength;
    u_int16_t treeDepth;

    NSData *indexData, *sectionsData, *stringsData, *urlTableData, *urlStringsData;    
}

@property (retain) NSData *indexData, *sectionsData, *stringsData, *urlTableData, *urlStringsData;    

@property (retain) NSString *containerID;

@property unsigned char docIndexScale,    countScale,    locationScale;
@property unsigned char docIndexRootSize, countRootSize, locationRootSize;

@property u_int32_t     leafNodeOffset, nodeLength;
@property u_int16_t     treeDepth;

+ (CHMIndex *)indexWithContainer:(CHMContainer *)container;

- (id)initWithContainer:(CHMContainer *)container;

- (void)searchForTextChunk:(NSString *)textChunk 
              forOperation:(CHMSearchOperation *)operation;

- (u_int32_t)indexWordNodeOffsetForTextChunk:(NSString *)textChunk;

- (u_int32_t)firstIndexWordNodeOffset;

- (void)processWLCBlockWithCount:(u_int64_t)documentsCount 
                          offset:(u_int32_t)blockOffset 
                          length:(u_int64_t)blockLength
                       indexWord:(NSString *)indexWord
                       operation:(CHMSearchOperation *)operation;
    
@end
