//
//  SCProgressIndicator.m
//  USBDemo
//
//  Created by golfy on 2021/12/7.
//

#import "SCProgressIndicator.h"
#import "Masonry.h"

@interface SCProgressIndicator ()

@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@end

@implementation SCProgressIndicator

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.wantsLayer = YES;
    self.layer.backgroundColor = [NSColor.whiteColor colorWithAlphaComponent:0.5f].CGColor;
    
}

/// 重新布局
- (void)layoutSubviews:(NSRect)rect {
    self.frame = rect;
    
    [self.progressIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(self.progressIndicator.frame.size);
        make.centerX.mas_equalTo(self.mas_centerX);
        make.centerY.mas_equalTo(self.mas_centerY).mas_offset(-40);
    }];
    
    [self.progressTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(30);
        make.top.mas_equalTo(self.progressIndicator.mas_bottom).mas_offset(6);
    }];
    
}

- (void)startAnimation {
    [self.progressIndicator startAnimation:nil];
}

- (void)stopAnimation {
    [self.progressIndicator stopAnimation:nil];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

// 重写NSView的事件方法，就能创建遮罩视图
// 不在方法中调用 [super mouseDown:event] 就阻止了其传递，这里拦截了鼠标左键和右键，又不影响其上层的视图点击
// 如果你需要的是点击旁边区域隐藏某个视图时，就最好使用addLocalMonitorForEventsMatchingMask全局监听
- (void)mouseDown:(NSEvent *)event { }
- (void)rightMouseDown:(NSEvent *)event { }

@end
