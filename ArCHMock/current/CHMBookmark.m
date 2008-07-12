#import "CHMBookmark.h"


@implementation CHMBookmark

@synthesize label, sectionLabel, sectionPath;
@synthesize filePath, fileAlias;
@dynamic fileRelativePath;
@dynamic filePathColor;

+ (CHMBookmark *)bookmarkWithLabel:(NSString *)label 
                          filePath:(NSString *)filePath
                      sectionLabel:(NSString *)sectionLabel
                       sectionPath:(NSString *)sectionPath {
    return [[[CHMBookmark alloc] initWithLabel:label
                                      filePath:filePath
                                  sectionLabel:sectionLabel
                                   sectionPath:sectionPath] autorelease];
}

- (id)initWithLabel:(NSString *)initLabel
           filePath:(NSString *)initFilePath
       sectionLabel:(NSString *)initSectionLabel
        sectionPath:(NSString *)initSectionPath {
    if (self = [super init]) {
        self.fileAlias = [BDAlias aliasWithPath:initFilePath];

        self.label = initLabel;
        self.filePath = initFilePath;
        self.sectionLabel = initSectionLabel;
        self.sectionPath = initSectionPath;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    [super init];
    
    self.label = [coder decodeObjectForKey:@"label"];
    self.sectionLabel = [coder decodeObjectForKey:@"sectionLabel"];
    self.sectionPath = [coder decodeObjectForKey:@"sectionPath"];
    self.filePath = [coder decodeObjectForKey:@"filePath"];
    self.fileAlias = [BDAlias aliasWithData:[coder decodeObjectForKey:@"fileAliasData"]];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:label forKey:@"label"];
    [coder encodeObject:filePath forKey:@"filePath"];
    [coder encodeObject:[fileAlias aliasData] forKey:@"fileAliasData"];
    [coder encodeObject:sectionLabel forKey:@"sectionLabel"];
    [coder encodeObject:sectionPath forKey:@"sectionPath"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: {\n\
    label: '%@',\n\
    file relative path: '%@',\n\
    Section label: '%@',\n\
    Section path: '%@'\n\
}",
            [super description],
            label,
            self.fileRelativePath,
            sectionLabel,
            sectionPath
            ];
}


static BOOL doesFileExist(NSString *filePath) {
    BOOL isDirectory;
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath 
                                                isDirectory:&isDirectory] && !isDirectory;
}

- (BOOL)locateFile {
    if (doesFileExist(filePath)) {
        return YES;
    }
    else {
        NSString *testFilePath = [fileAlias fullPath];
        if (testFilePath) {
            self.filePath = testFilePath;
            return YES;
        }
    }
    
    return NO;
}

- (NSString *)fileRelativePath {
    [self locateFile];
    return [self.filePath stringByAbbreviatingWithTildeInPath];
}

- (NSColor *)filePathColor {
    return [self locateFile] ? [NSColor textColor] : [NSColor redColor];
}

- (void)dealloc {
    self.label = nil;
    self.sectionLabel = nil;
    self.sectionPath = nil;
    self.filePath = nil;
    self.fileAlias = nil;
    
    [super dealloc];
}

@end
