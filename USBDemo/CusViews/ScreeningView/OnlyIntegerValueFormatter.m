//
//  OnlyIntegerValueFormatter.m
//  USBDemo
//
//  Created by golfy on 2021/12/21.
//

#import "OnlyIntegerValueFormatter.h"

@implementation OnlyIntegerValueFormatter

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.maxLen = 11;
    }
    return self;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString * _Nullable __autoreleasing *)newString errorDescription:(NSString * _Nullable __autoreleasing *)error {
    if([partialString length] == 0) {
        return YES;
    }
    
    if([partialString length] > self.maxLen) {
        return NO;
    }

    NSScanner* scanner = [NSScanner scannerWithString:partialString];

    if(!([scanner scanInt:0] && [scanner isAtEnd])) {
        return NO;
    }

    return YES;
}

@end
