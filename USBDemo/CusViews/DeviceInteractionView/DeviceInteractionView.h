//
//  DeviceInteractionView.h
//  USBDemo
//
//  Created by golfy on 2021/11/18.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// 设备交互界面
@interface DeviceInteractionView : NSView

@property (unsafe_unretained) IBOutlet NSTextView *displayContent;
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

/// 激活蓝牙连接
- (void)activeBleHandle;

@end

NS_ASSUME_NONNULL_END
