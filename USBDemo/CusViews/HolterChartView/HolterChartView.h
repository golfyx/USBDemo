//
//  HolterChartView.h
//  HolterDrawDemo
//
//  Created by bj_dev on 16/9/12.
//  Copyright © 2016年 bj_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kCellCount 10
#define kPixelsPerCell 25
#define kDefaultGain 10
#define kDefaultVelocity 25
#define kDefaultSample 500
#define kVelocityScale 0.5
#define kGainScale (0.2875 * 16) // 最新 0.2875 = 4.615 / 16 = 18.46 / 4

/// 实时心电传输绘图
@interface HolterChartView : NSView

@property (nonatomic, assign) CGFloat samplate;
@property (nonatomic, assign) CGFloat velocity;
@property (nonatomic, assign) CGFloat gain;
//每个数据所占的像素个数（X轴）=走速 / 采样率 * 每毫米像素点个数
//采样率 = 250（固定）

//线的宽度默认 width: 0.8  color: greenColor
- (instancetype)initWithFrame:(CGRect)frame;

- (instancetype)initWithFrame:(CGRect)frame
                    CureWidth:(CGFloat)curveWidth
                    CureColor:(NSColor *)curveColor;

- (void)clearCanvas;


@end
