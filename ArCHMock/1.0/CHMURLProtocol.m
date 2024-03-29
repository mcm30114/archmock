#import "CHMURLProtocol.h"
#import "CHMContainer.h"
#import <Foundation/NSXMLDocument.h>

@class NSURLProtocolClient;

@implementation CHMURLProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSURL *url = [request URL];
    if (![[url scheme] isEqualToString:@"chm"]) {
        return NO;
    }
    
    NSString *containerUniqueID = [url host];
    return nil != [[CHMContainer containersByUniqueID] valueForKey:containerUniqueID];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    id client = [self client];
    
    NSURL *url = [[self request] URL];
//    NSLog(@"INFO: Handling URL '%@'", url);
    
    NSString *containerUniqueID = [url host];
    NSString *objectPath = [url path];
    NSString *parameters = [url parameterString];
    
    //    NSLog(@"DEBUG: Object path: '%@'", objectPath);
    
    CHMContainer *container = [[CHMContainer containersByUniqueID] valueForKey:containerUniqueID];
    
    if ([objectPath isEqualToString:@""]) {
        objectPath = [container homeSectionPath];
    }
    if (parameters) {
        objectPath = [NSString stringWithFormat:@"%@;%@", objectPath, parameters];
    }
    
    NSData   *objectData  = [container dataForObjectWithPath:objectPath];
    NSString *contentType = @"application/octet-stream";

    if (objectData) {
        NSPredicate *htmlPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES '.*?\\\\.(?i)html?($|#.*)'"];
        if ([htmlPredicate evaluateWithObject:objectPath]) {
            NSString *objectString = [[[NSString alloc] initWithData:objectData encoding:NSUTF8StringEncoding] autorelease];
            if (objectString) {
                contentType = @"text/html";
//                NSError *error = nil;
//                
//                NSString *debugFilePath = [[NSString stringWithFormat:@"~/Temp/%@/%@", [url host], [url path]] stringByExpandingTildeInPath];
//                [[NSFileManager defaultManager] createDirectoryAtPath:[debugFilePath stringByDeletingLastPathComponent]
//                                          withIntermediateDirectories:YES
//                                                           attributes:nil
//                                                                error:&error];
//                
//                [objectString writeToFile:debugFilePath
//                               atomically:YES
//                                 encoding:NSUTF8StringEncoding
//                                    error:&error];
//                if (error) {
//                    NSLog(@"WARN: Error while saving current file '%@': %@", debugFilePath, error);
//                }
//            NSLog(@"DEBUG: Object data is a string: '%@'", objectString);
//            NSError *error;
//            NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:objectString
//                                                                   options:NSXMLDocumentTidyHTML
//                                                                     error:&error] autorelease];
//            if (doc != nil) {
////                NSLog(@"DEBUG: Tidy HTML: '%@'", [doc XMLString]);
//                objectData = [doc XMLDataWithOptions:NSXMLDocumentIncludeContentTypeDeclaration | NSXMLDocumentTidyXML];
//                //                NSLog(@"DEBUG: XMLData: '%@'", objectData);
//            }
//            else {
//                NSLog(@"WARN: Error while parsing HTML: %@", error);
//            }
            }
        }
        
        NSURLResponse *response = [[[NSURLResponse alloc] initWithURL:url 
                                                             MIMEType:contentType
                                                expectedContentLength:[objectData length]
                                                     textEncodingName:nil] 
                                   autorelease];
        
        [client URLProtocol:self 
         didReceiveResponse:response 
         cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        
        [client URLProtocol:self didLoadData:objectData];
        
        //        NSLog(@"INFO: URL '%@' handled", url);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"URL handled" 
                                                            object:container 
                                                          userInfo:[NSDictionary dictionaryWithObject:url
                                                                                               forKey:@"url"]];
    }
    else {
        NSLog(@"WARN: URL '%@' isn't handled: no data for object with path '%@'", url, objectPath);
    }
    
    [client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
    
}

@end
