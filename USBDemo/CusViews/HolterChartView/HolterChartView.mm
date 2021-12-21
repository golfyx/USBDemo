//
//  HolterChartView.m
//  HolterDrawDemo
//
//  Created by bj_dev on 16/9/12.
//  Copyright © 2016年 bj_dev. All rights reserved.
//

#import "HolterChartView.h"
#import "ShortcutHeader.h"
//#import <QuartzCore/CAShapeLayer.h>
#import "SCAppVaribleHandle.h"
#import "HolterGriddingView.h"

@interface HolterChartView ()
{
    CGFloat full_height;
    CGFloat full_width;
    CGFloat m_cell_square_width;
    CGFloat cell_square_width;
    
    CGPoint _lastPoint;
    NSInteger _lastIndex;
    CGPoint _prePoint1;
    CGPoint _prePoint2;
    
    NSInteger _pointCount;
}

// 数据存储的列表数组
@property (nonatomic, strong) NSArray<NSNumber *> *listArray;

@end

@implementation HolterChartView

- (instancetype)initWithFrame:(CGRect)frame
                    CureWidth:(CGFloat)curveWidth
                    CureColor:(NSColor *)curveColor {

    if (self = [super initWithFrame:frame]) {
        [self setupParagram:frame];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        [self setupParagram:frame];
        [self setupECGManager];
    }
    return self;
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupParagram:self.frame];
    [self setupECGManager];
}

/// 初始化参数
- (void)setupParagram:(CGRect)frame
{
    _samplate = 500;
    _gain = 10;
    _velocity = 25;
    
    self.wantsLayer = YES; // 设备layer必须要设置。
    self.layer.backgroundColor = [NSColor clearColor].CGColor;
    
    full_height = frame.size.height;
    full_width = frame.size.width;
    // 整个屏幕分为12个大格, 1个大格表示5mm, 如velocity为25mm/s, 则表示5大格为1s数据
    // 一个小格宽度
    m_cell_square_width = full_width/(20 * 5.0f);
    // 一个大格宽度
    cell_square_width = 5 * m_cell_square_width;
    
}

#pragma mark- 画图
- (void)drawRect:(CGRect)rect {
    // Drawing code
    [super drawRect:rect];
    
    
    if (_listArray) {
        CGContextRef ctx = [[NSGraphicsContext  currentContext] CGContext];
        
        CGFloat curveLineWidth = 0.8;
        CGContextSetLineWidth(ctx, curveLineWidth);
        CGContextSetStrokeColorWithColor(ctx, [NSColor blueColor].CGColor);
        if (_prePoint1.y == 0) {
            _prePoint1.y = full_height / 2;
        }
        if (_prePoint2.y == 0) {
            _prePoint2.y = full_height / 2;
        }
        if (_lastPoint.y == 0) {
            _lastPoint.y = full_height / 2;
        }
        CGContextMoveToPoint(ctx, _prePoint1.x, _prePoint1.y);
        CGContextAddLineToPoint(ctx, _prePoint2.x, _prePoint2.y);
        CGContextAddLineToPoint(ctx, _lastPoint.x, _lastPoint.y);
        for (; _lastIndex<self.listArray.count; _lastIndex++) {
            NSNumber *number = [self.listArray objectAtIndex:_lastIndex];
            
            CGFloat pointX = [self convertWavePointToPixels] +_lastPoint.x;
            CGFloat pointY = full_height / 2 - self.gain * ((kGainScale * number.floatValue / 1000) * (5 * m_cell_square_width * 2))/10.0f;
            if (pointX >= self.frame.size.width) {
                CGContextAddLineToPoint(ctx, pointX, pointY);
                _lastPoint = CGPointMake(0, pointY);
                _prePoint1 = _lastPoint;
                _prePoint2 = _lastPoint;
                break;
            }else{
                CGContextAddLineToPoint(ctx, pointX, pointY);
            }
            _prePoint2 = _prePoint1;
            _prePoint1 = _lastPoint;
            _lastPoint = CGPointMake(pointX, pointY);
        }
        CGContextStrokePath(ctx);
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[NSFont fontWithName:@"AvenirNext-DemiBold" size:12.0f],
                                 NSForegroundColorAttributeName:[NSColor blackColor]};

    NSString *text = [NSString stringWithFormat:@"25mm/s %.0fmm/mV", self.gain];
    [text drawInRect:CGRectMake(CGRectGetWidth(self.frame) - 120, CGRectGetHeight(self.frame) - 20, 120, 18) withAttributes:attributes];
}

- (void)setupECGManager {
    
    __weak typeof(self) weakSelf = self;
    SCAppVaribleHandleInstance.bleDrawDataBlock = ^(NSData *data) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf dealWithOriginDataHandle:data];
        });
        
    };
}

- (void)dealWithOriginDataHandle:(NSData *)data
{
    if (data == nil || data.length <= 0) return;
    
    Byte *resultBytes = (Byte *)[data bytes];
    NSMutableArray<NSNumber *> *showArray = [[NSMutableArray alloc] init];
    UInt8 cnt = 0;
    short packageIndex = 0;
    short result;
    
    if (resultBytes[0] == 0xA5 && resultBytes[1] == 0x5A && resultBytes[2] == 0x01)
    {
        
        cnt = (resultBytes[3] & 0xff - 1)/2;
        packageIndex = resultBytes[4];
        
        for (UInt8 i = 0; i < cnt; i++)
        {
            result = 0;
            result |= (resultBytes[5 + 2 * i + 1] & 0xff); // 第5位是索引
            result <<= 8;
            result |= (resultBytes[5 + 2 * i] & 0xff);
            
            result = result - 0x8000;
            [showArray addObject:@(result * -1)];
        }
    }
    
    self.listArray = showArray;
    _lastIndex = 0;
    CGFloat blinkSpace = 20;
    
    CGFloat displayW = self.listArray.count * [self convertWavePointToPixels] + blinkSpace;
    CGRect rect = CGRectZero;
    if (displayW > self.frame.size.width) {
        rect = CGRectMake(0, 0, (self.listArray.count - _lastIndex) * [self convertWavePointToPixels] + blinkSpace - self.frame.size.width, self.frame.size.height);
    } else {
        rect = CGRectMake(_lastPoint.x, 0, displayW, self.frame.size.height);
    }
    [self setNeedsDisplayInRect:rect];
}

- (CGFloat)convertWavePointToPixels {
    // 25mm/s 表示25小格为1s数据
    // 500个点即1s数据宽度为25小格
    return m_cell_square_width * _velocity / _samplate;
}

- (void)clearCanvas{
    _lastPoint = CGPointMake(0, full_height / 2);
    _prePoint2 = _lastPoint;
    _prePoint1 = _lastPoint;
    _listArray = nil;
    _pointCount = 0;
    [self setNeedsDisplay:YES];
}

@end
