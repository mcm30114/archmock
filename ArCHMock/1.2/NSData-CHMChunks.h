#import <Foundation/Foundation.h>

@interface NSData (CHMChunks)

- (unsigned short)shortFromOffset:(NSUInteger)offset;
- (unsigned long)longFromOffset:(NSUInteger)offset;
- (unsigned char)charFromOffset:(NSUInteger)offset;

- (NSData *)dataFromOffset:(NSUInteger)offset length:(NSUInteger)length;
- (NSString *)stringWithEncoding:(NSStringEncoding)encoding fromOffset:(NSUInteger)offset;
- (NSString *)stringWithEncoding:(NSStringEncoding)encoding fromOffset:(NSUInteger)offset length:(NSUInteger)length;

- (u_int64_t)encodedIntegerFromOffset:(NSUInteger)offset readDataLength:(long long *)readDataLength;
- (u_int64_t)decodeIntegerFromOffset:(NSUInteger)offset scale:(unsigned char)scale rootSize:(unsigned char)rootSize bit:(int *)bit readDataLength:(long long *)readDataLength;

- (NSString *)indexWordWithEncoding:(NSStringEncoding)encoding fromOffset:(NSUInteger)offset previousWord:(NSString *)previousWord wordPartLength:(long long *)wordPartLength;

@end