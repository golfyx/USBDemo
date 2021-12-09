//
//  ScreeningView.h
//  USBDemo
//
//  Created by golfy on 2021/11/18.
//

#import <Cocoa/Cocoa.h>
#import "HolterGriddingView.h"
#import "HolterChartView.h"

NS_ASSUME_NONNULL_BEGIN


@protocol ScreeningViewDelegate <NSObject>
@optional
- (void)didStopAndUploadData;
- (void)didCompleteUploadData;

@end

/// 快速筛查系统
@interface ScreeningView : NSView

@property(nonatomic,strong)id<ScreeningViewDelegate> delegate;

@property (weak) IBOutlet NSTextField *batteryStatus;
@property (weak) IBOutlet NSTextField *curEcgDataBlockDetail;
@property (weak) IBOutlet NSProgressIndicator *readingBlockProgress;
@property (weak) IBOutlet NSTextField *readingBlockProgressValue;
@property (weak) IBOutlet NSButton *isDeleteECGData;

@property (weak) IBOutlet NSTextField *userPhoneValue;
@property (weak) IBOutlet NSTextField *captchaValue;
@property (weak) IBOutlet NSTextField *nameValue;
@property (weak) IBOutlet NSPopUpButton *genderValue;
@property (weak) IBOutlet NSTextField *ageValue;
@property (weak) IBOutlet NSTextField *heightValue;
@property (weak) IBOutlet NSTextField *weightValue;


@property (weak) IBOutlet HolterGriddingView *holterGriddingView;
@property (weak) IBOutlet HolterChartView *holterChartView;

/// 激活蓝牙连接
- (void)activeBleHandle;

@end

NS_ASSUME_NONNULL_END
