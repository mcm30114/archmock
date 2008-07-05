#import "CHMDocumentController.h"
#import "CHMDocument.h"


@implementation CHMDocumentController

@synthesize documentByContainerID, operationQueue;

+ (CHMDocumentController *)sharedCHMDocumentController {
    return (CHMDocumentController *)[self sharedDocumentController];
}

- (id)init {
    if (self = [super init]) {
        self.documentByContainerID = [NSMutableDictionary dictionary];
        operationQueue = [NSOperationQueue new];
    }
    
    return self;
}

- (void)addDocument:(NSDocument *)document {
    CHMDocument *chmDocument = (CHMDocument *)document;
    [documentByContainerID setObject:document forKey:chmDocument.containerID];
    
    [super addDocument:document];
}

- (void)removeDocument:(NSDocument *)document {
    CHMDocument *chmDocument = (CHMDocument *)document;
    
    [documentByContainerID removeObjectForKey:chmDocument.containerID];
    
    [super removeDocument:document];
}

- (void)dealloc {
    self.documentByContainerID = nil;
    self.operationQueue = nil;
    
    [super dealloc];
}

@end
