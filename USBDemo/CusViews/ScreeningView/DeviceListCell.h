//
//  DeviceListCell.h
//  USBDemo
//
//  Created by golfy on 2022/2/24.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class DeviceListCell;

@protocol DeviceListCellDelegate <NSObject>

@optional
- (void)connectDevice:(DeviceListCell *)cell index:(int)index;

@end

@interface DeviceListCell : NSTableCellView

@property (nonatomic, weak) id<DeviceListCellDelegate> delegate;

@property (weak) IBOutlet NSTextField *deviceRssiTField;
@property (weak) IBOutlet NSTextField *deviceSeriTField;
@property (weak) IBOutlet NSTextField *deviceNameTField;
@property (weak) IBOutlet NSButton *connectDeviceButton;

@property (nonatomic, assign) NSInteger index;

@end

NS_ASSUME_NONNULL_END
