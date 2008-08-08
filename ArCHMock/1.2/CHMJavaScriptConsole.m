#import "CHMJavaScriptConsole.h"


@implementation CHMJavaScriptConsole

- (void)log:(NSString *)string {
    NSLog(string);
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
    if (selector == @selector(log:)) {
        return NO;
    }
    return YES;
}

+ (NSString *)webScriptNameForSelector:(SEL)selector {
    if (@selector(log:)) {
        return @"log";
    }
    return nil;
}

@end
