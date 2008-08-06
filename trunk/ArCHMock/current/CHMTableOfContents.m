#import <Foundation/NSXMLDocument.h>
#import "CHMTableOfContents.h"
#import "NSData-CHMChunks.h"
#import <libxml/HTMLparser.h>

@implementation CHMTableOfContents

@synthesize root, sectionsByPath;

+ (CHMTableOfContents *)tableOfContentsWithContainer:(CHMContainer *)container {
    return [[[CHMTableOfContents alloc] initWithContainer:container] autorelease];
}

- (id)initWithContainer:(CHMContainer *)container {
    if (self = [super init]) {
        NSString *tableOfContentsPath = [container findMetadataStringWithEncoding:container.encoding inSystemObjectWithOffset:0 orInStringsObjectWithOffset:0x60];
        
        if (!tableOfContentsPath) {
            NSLog(@"WARN: Can't find table of contents path");
            return nil;
        }

        tableOfContentsPath = [NSString stringWithFormat:@"/%@", tableOfContentsPath];
//        NSLog(@"DEBUG: Table of contents path: '%@'", tableOfContentsPath);
        
        
        NSData *data = [container dataForObjectWithPath:tableOfContentsPath];
        
        if (!data) {
            NSLog(@"WARN: Can't get table of contents data. Table of contents path: '%@'", tableOfContentsPath);
            return nil;
        }
        
        NSError *error = nil;
        NSXMLDocument *doc = nil;
        NSString *xmlString = [[[NSString alloc] initWithData:data encoding:container.encoding] autorelease];
        if (nil != xmlString) {
            doc =[[[NSXMLDocument alloc] initWithXMLString:xmlString options:NSXMLDocumentTidyHTML error:&error] autorelease];
        }
        
        if (!doc) {
            NSLog(@"WARN: Failed to open table of contents with provided encoding: %@", [error localizedDescription]);
            doc = [[[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyHTML error:&error] autorelease];
        }
        if (!doc) {
            NSLog(@"WARN: Can't parse table of contents: %@", [error localizedDescription]);
            return nil;
        }
        NSLog(@"DEBUG: character encoding: %@", [doc characterEncoding]);
        [doc setCharacterEncoding:[container.encodingName lowercaseString]];
        
//        NSLog(@"DEBUG: Populating table of contents");
        self.sectionsByPath = [NSMutableDictionary dictionary];
        
        self.root = [CHMSection sectionWithLabel:nil path:nil parent:nil];
        
        NSMutableArray *listItemsStack = [NSMutableArray array];
        NSMutableArray *listItemsQueue = [NSMutableArray array];
        
        CHMSection *currentParentSection = self.root;
        NSArray *rootListItems = [doc nodesForXPath:@"html/body/ul/li" error:&error];
        
        [listItemsQueue addObjectsFromArray:rootListItems];
        int sectionsCount = 0;
        while ([listItemsQueue count] > 0) {
            NSXMLElement *listItemElement = [listItemsQueue objectAtIndex:0];
            
            if ([listItemsStack count] > 0 && listItemElement == [listItemsStack objectAtIndex:0]) {
                [listItemsQueue removeObjectAtIndex:0];
                [listItemsStack removeObjectAtIndex:0];
                currentParentSection = currentParentSection.parent;
            }
            else {
                [listItemsStack insertObject:listItemElement atIndex:0];
                
                NSXMLElement *sectionElement = [[listItemElement nodesForXPath:@"object[@type='text/sitemap']" error:&error] lastObject];
                //                NSLog(@"DEBUG: section element: %@", sectionElement);
                NSXMLNode *labelAttribute = [[sectionElement nodesForXPath:@"param[@name='Name' or @name='name']/@value" error:&error] lastObject];
                NSXMLNode *pathAttribute = [[sectionElement nodesForXPath:@"param[@name='Local' or @name='local']/@value" error:&error] lastObject];
                NSString *label = [labelAttribute stringValue];
                NSString *path = [pathAttribute stringValue];
                CHMSection *section = [CHMSection sectionWithLabel:label path:path parent:currentParentSection];
                
                NSLog(@"DEBUG: section: %@", section);
                currentParentSection = section;
                sectionsCount++;
                
                if (section.path) {
                    NSString *lowercasedPath = [section.path lowercaseString];
                    if (![sectionsByPath objectForKey:lowercasedPath]) {
                        [sectionsByPath setObject:section forKey:lowercasedPath];
                    }
                }
                
                NSArray *childrenListItems = [listItemElement nodesForXPath:@"ul/li" error:&error];
                if ([childrenListItems count] > 0) {
                    if (1 == [childrenListItems count]) {
                        [listItemsQueue insertObject:[childrenListItems objectAtIndex:0] atIndex:0];
                    }
                    else {
                        [listItemsQueue insertObjects:childrenListItems atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [childrenListItems count])]];
                    }
                }
            }
        }
//        NSLog(@"INFO: Table of contents is populated with %d section(s)", sectionsCount);
    }
    
    return self;
}

- (void)dealloc {
    self.root = nil;
    self.sectionsByPath = nil;
    
    [super dealloc];
}

@end
