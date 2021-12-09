//
//  ViewController.h
//  USBDemo
//
//  Created by golfy on 2021/10/9.
//

#import <Cocoa/Cocoa.h>
#import "USBDeviceTool.h"
#import "UsbMonitor.h"
#import "ShortcutHeader.h"
#import "HolterGriddingView.h"
#import "HolterChartView.h"


/// 临时块详细信息
@interface SCTmpDeviceBlockInfo : NSObject


@end


@interface ViewController : NSViewController<USBDeviceDelegate, UsbMonitorDelegate>

@property (unsafe_unretained) IBOutlet NSTextView *textViewContent;
@property (weak) IBOutlet NSTextField *appVersion;
@property (weak) IBOutlet NSTextField *pidVid;
@property (weak) IBOutlet NSPopUpButton *deviceList;
@property (weak) IBOutlet NSTextField *batteryStatus;
@property (weak) IBOutlet NSTextField *dongleVersion;
@property (weak) IBOutlet NSTextField *ecgDataBlockCount;
@property (weak) IBOutlet NSTextField *readingStatus;
@property (weak) IBOutlet NSTextField *curEcgDataBlock;
@property (weak) IBOutlet NSPopUpButton *ecgDataPageList;
@property (weak) IBOutlet NSTextField *curEcgDataBlockDetail;
@property (weak) IBOutlet NSProgressIndicator *readingBlockProgress;
@property (weak) IBOutlet NSTextField *readingBlockProgressValue;
@property (weak) IBOutlet NSButton *isDeleteECGData;
@property (weak) IBOutlet NSButton *isHexadecimalDisplay;
@property (weak) IBOutlet NSButton *isStopDisplay;

@property (weak) IBOutlet NSTextField *userPhoneValue;
@property (weak) IBOutlet NSTextField *captchaValue;
@property (weak) IBOutlet NSTextField *nameValue;
@property (weak) IBOutlet NSPopUpButton *genderValue;
@property (weak) IBOutlet NSTextField *ageValue;
@property (weak) IBOutlet NSTextField *heightValue;
@property (weak) IBOutlet NSTextField *weightValue;


@property (weak) IBOutlet HolterGriddingView *holterGriddingView;
@property (weak) IBOutlet HolterChartView *holterChartView;


@end

