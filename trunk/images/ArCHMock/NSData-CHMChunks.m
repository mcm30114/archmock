#import "NSData-CHMChunks.h"


@implementation NSData (CHMChunks)

- (BOOL)isOffsetValid:(NSUInteger)offset {
    if (offset >= [self length]) {
        NSLog(@"WARN: Invalid data offset detected: %d", offset);
        return NO;
    }
    
    return YES;
}

- (unsigned short)shortFromOffset:(NSUInteger)offset {
    NSRange valueRange = NSMakeRange(offset, 2);
    unsigned short value;
    
    [self getBytes:(void *)&value range:valueRange];
    return NSSwapLittleShortToHost(value);
}

- (unsigned long)longFromOffset:(NSUInteger)offset {
    NSRange valueRange = NSMakeRange(offset, 4);
    unsigned long value;
    
    [self getBytes:(void *)&value range:valueRange];
    return NSSwapLittleLongToHost(value);
}

- (unsigned char)charFromOffset:(NSUInteger)offset {
    NSRange valueRange = NSMakeRange(offset, 1);
    unsigned char value;
    
    [self getBytes:(void *)&value range:valueRange];
    return NSSwapLittleLongToHost(value);
}

- (NSString *)stringFromOffset:(NSUInteger)offset {
    if (![self isOffsetValid:offset]) {
        return nil;
    }
    const char *stringData = (const char *)[self bytes] + offset;
    return [NSString stringWithUTF8String:stringData];
}

- (NSString *)stringFromOffset:(NSUInteger)offset 
                        length:(NSUInteger)length {
    if (![self isOffsetValid:offset]) {
        return nil;
    }
    
    char *buffer = malloc(length);
    [self getBytes:buffer 
             range:NSMakeRange(offset, length)];
    
    NSString *string = [[[NSString alloc] initWithBytesNoCopy:buffer 
                                                       length:length 
                                                     encoding:NSUTF8StringEncoding 
                                                 freeWhenDone:YES] autorelease];
    if (!string) {
        NSLog(@"WARN: Can't construct string from data with offset: '%20X' and length: '%i'", offset, length);
        free(buffer);
    }
    return string;
}

- (NSData *)dataFromOffset:(NSUInteger)offset 
                    length:(NSUInteger)length {
    if (offset + length > [self length]) {
        length = [self length] - offset;
    }
    
    return [self subdataWithRange:NSMakeRange(offset, length)];
}

- (NSString *)indexWordFromOffset:(NSUInteger)offset 
                     previousWord:(NSString *)previousWord 
                   wordPartLength:(long long *)wordPartLength {
    unsigned char indexWordPartLength = [self charFromOffset:offset];
    unsigned char previousWordPartPosition = [self charFromOffset:offset + 1];
    NSString *word = [self stringFromOffset:offset + 2 
                                     length:indexWordPartLength - 1];
    
    if (0 != previousWordPartPosition) {
        //        NSLog(@"DEBUG: Taking part from previous index word '%@' up to position: '%i'", previousWord, previousWordPartPosition);
        word = [[previousWord substringToIndex:previousWordPartPosition] stringByAppendingString:word];
    }
    
    *wordPartLength = indexWordPartLength;
    
    return word;
}

// Algorithm is taken from ffus of ext.c of pyCHM
- (u_int64_t)encodedIntegerFromOffset:(NSUInteger)offset 
                 readDataLength:(long long *)readDataLength {
    *readDataLength = 0;
    int shift = 0;
    u_int64_t data = 0;
    
    unsigned char* byte = (unsigned char*)[self bytes] + offset;
    
	do {
		data |= ((*byte) & 0x7F) << shift;
		shift += 7;
        (*readDataLength)++;
	} while (*(byte++) & 0x80);
    
    return data;
}

// Finds the first unset bit in memory. Returns the number of set bits found.
// Returns -1 if the buffer runs out before we find an unset bit.
// Algorithm is taken from ffus of ext.c of pyCHM
static inline int firstUnsetBit(unsigned char *byte, 
                                int *bit, 
                                long long *readDataLength) {
    int bits = 0;
    *readDataLength = 0;
    
	while (*byte & (1 << *bit)) {
		if (*bit) {
            (*bit)--;
        }
		else { 
			byte++;
			(*readDataLength)++;
			*bit = 7; 
		}
		bits++;
	}
    
	if (*bit) {
        (*bit)--;
    }
	else { 
		(*readDataLength)++;
		*bit = 7; 
	}
    
	return bits;
}

// Algorithm is take from rc_int of ext.c of pyCHM
- (u_int64_t)decodeIntegerFromOffset:(NSUInteger)offset 
                               scale:(unsigned char)scale
                            rootSize:(unsigned char)rootSize
                                 bit:(int *)bit 
                      readDataLength:(long long *)readDataLength {
    *readDataLength = 0;
    
	if (!bit || *bit > 7 || scale != 2) {
		return ~(u_int64_t)0;
    }
    
	u_int64_t value = 0;
    unsigned char* byte = (unsigned char*)[self bytes] + offset;
    
	long long readDataLengthFromFirstUnsetBitSearch = 0;
    int count = firstUnsetBit(byte, 
                              bit,
                              &readDataLengthFromFirstUnsetBitSearch);
	*readDataLength += readDataLengthFromFirstUnsetBitSearch;
	byte += *readDataLength;
    
	int n, nBits, numBits, base;
	nBits = n = rootSize + (count ? count - 1 : 0);
    
	unsigned char mask;
	while (n > 0) {
		numBits = n > *bit ? *bit : n - 1;
		base = n > *bit ? 0    : *bit - (n - 1);
        
		switch(numBits) {
			case 0: 
				mask = 1; 
				break;
			case 1: 
				mask = 3; 
				break;
			case 2: 
				mask = 7; 
				break;
			case 3: 
				mask = 0xF; 
				break;
			case 4: 
				mask = 0x1F; 
				break;
			case 5: 
				mask = 0x3F; 
				break;
			case 6: 
				mask = 0x7F; 
				break;
			case 7: 
				mask = 0xFF; 
				break;
            default:
                mask = 0xFF;
				break;
		}
        
		mask <<= base;
		value = (value << (numBits + 1)) | (u_int64_t)((*byte & mask) >> base);
		
		if( n > *bit ){
			byte++;
			(*readDataLength)++;
            n -= *bit + 1;
			*bit = 7;
		} else {
			*bit -= n;
            n = 0;
		}
	}
    
	if (count) {
        value |= (u_int64_t)1 << nBits;
    }
    
	return value;
}

@end
