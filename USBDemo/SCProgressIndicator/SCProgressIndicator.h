//
//  SCProgressIndicator.h
//  USBDemo
//
//  Created by golfy on 2021/12/7.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCProgressIndicator : NSView

@property (weak) IBOutlet NSTextField *progressTitle;

/// 重新布局
- (void)layoutSubviews:(NSRect)rect;

- (void)startAnimation;
- (void)stopAnimation;

@end

NS_ASSUME_NONNULL_END
