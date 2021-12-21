//
//  OnlyIntegerValueFormatter.h
//  USBDemo
//
//  Created by golfy on 2021/12/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OnlyIntegerValueFormatter : NSNumberFormatter

@property (nonatomic, assign) int maxLen;

@end

NS_ASSUME_NONNULL_END
