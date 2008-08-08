#import <Cocoa/Cocoa.h>


@interface CHMDocumentWindowSettings : NSObject <NSCoding> {
    NSRect frame;
    float sidebarWidth;
    BOOL isSidebarCollapsed;
}

@property BOOL isSidebarCollapsed;
@property NSRect frame;
@property float sidebarWidth;

+ (CHMDocumentWindowSettings *)settingsWithData:(NSData *)data;
- (NSData *)data;

@end
