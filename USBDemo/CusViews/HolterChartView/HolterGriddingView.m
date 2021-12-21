//
//  HolterGriddingView.m
//  USBDemo
//
//  Created by golfy on 2021/11/16.
//

#import "HolterGriddingView.h"

@implementation HolterGriddingView {
    CGFloat full_height;
    CGFloat full_width;
    CGFloat m_cell_square_width;
    CGFloat cell_square_width;
    
    CGPoint _lastPoint;
    NSInteger _lastIndex;
    CGPoint _prePoint1;
    CGPoint _prePoint2;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupParagram:self.frame];
}

/// 初始化参数
- (void)setupParagram:(CGRect)frame
{
    
    self.wantsLayer = YES; // 设备layer必须要设置。
    self.layer.backgroundColor = [NSColor whiteColor].CGColor;
    
    full_height = frame.size.height;
    full_width = frame.size.width;
//    m_cell_square_width = full_width / (_velocity * 2);
    // 整个屏幕分为12个大格, 1个大格表示5mm, 如velocity为25mm/s, 则表示5大格为1s数据
    // 一个小格宽度
    m_cell_square_width = full_width/(20 * 5.0f);
    // 一个大格宽度
    cell_square_width = 5 * m_cell_square_width;
    
}

- (void)setupGridLayer
{
    NSBezierPath *bezierPath = [NSBezierPath bezierPath];
    bezierPath.lineWidth = 0.5f;
    
    CGFloat pos_x = cell_square_width;
    while (pos_x < full_width) {
        [bezierPath moveToPoint:CGPointMake(pos_x, 0)];
        [bezierPath lineToPoint:CGPointMake(pos_x, full_height)];
        
        pos_x += cell_square_width;
    }
    
    CGFloat pos_y = cell_square_width;
    while (pos_y < full_height) {
        [bezierPath moveToPoint:CGPointMake(0, pos_y)];
        [bezierPath lineToPoint:CGPointMake(full_width, pos_y)];
        
        pos_y += cell_square_width;
    }
    
    [[NSColor redColor] set];
    [bezierPath stroke];
    
    bezierPath.lineWidth = 0.3f;
    pos_x = m_cell_square_width;
    while (pos_x < full_width) {
        [bezierPath moveToPoint:CGPointMake(pos_x, 0)];
        [bezierPath lineToPoint:CGPointMake(pos_x, full_height)];
        pos_x += m_cell_square_width;
    }

    pos_y = m_cell_square_width;
    while (pos_y < full_height) {
        [bezierPath moveToPoint:CGPointMake(0, pos_y)];
        [bezierPath lineToPoint:CGPointMake(full_width, pos_y)];
        pos_y += m_cell_square_width;
    }
    
    [[NSColor redColor] set];
    [bezierPath stroke];
}

- (CGMutablePathRef)CGPathFromPath:(NSBezierPath *)path
{
    CGMutablePathRef cgPath = CGPathCreateMutable();
    NSInteger n = [path elementCount];
    
    for (NSInteger i = 0; i < n; i++) {
        NSPoint ps[3];
        switch ([path elementAtIndex:i associatedPoints:ps]) {
            case NSMoveToBezierPathElement: {
                CGPathMoveToPoint(cgPath, NULL, ps[0].x, ps[0].y);
                break;
            }
            case NSLineToBezierPathElement: {
                CGPathAddLineToPoint(cgPath, NULL, ps[0].x, ps[0].y);
                break;
            }
            case NSCurveToBezierPathElement: {
                CGPathAddCurveToPoint(cgPath, NULL, ps[0].x, ps[0].y, ps[1].x, ps[1].y, ps[2].x, ps[2].y);
                break;
            }
            case NSClosePathBezierPathElement: {
                CGPathCloseSubpath(cgPath);
                break;
            }
            default: NSAssert(0, @"Invalid NSBezierPathElement");
        }
    }
    return cgPath;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    [self setupGridLayer];
}

@end
