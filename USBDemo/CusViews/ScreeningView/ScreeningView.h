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
- (void)didShowProgressIndicatorWithTitle:(NSString *)title;
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
@property (weak) IBOutlet NSTextField *deviceSerialNumber;
@property (weak) IBOutlet NSPopUpButton *serialNumPopUpBtn;
@property (weak) IBOutlet NSScrollView *deviceScrollView;

@property (weak) IBOutlet NSDatePicker *saveDatePicker;
@property (weak) IBOutlet NSButton *updateUserInfoBtn;
@property (weak) IBOutlet NSButton *getUploadBtn;
@property (weak) IBOutlet NSButton *finishButton;
@property (weak) IBOutlet NSButton *setDetectionTimeBtn;

@property (weak) IBOutlet HolterGriddingView *holterGriddingView;
@property (weak) IBOutlet HolterChartView *holterChartView;

/// 激活蓝牙连接
- (void)activeBleHandle;

@end

NS_ASSUME_NONNULL_END
