//
//  ReportsView.h
//  USBDemo
//
//  Created by golfy on 2021/12/21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReportsView : NSView

@property (nonatomic, strong) NSViewController *viewController;

@property (weak) IBOutlet NSTextField *userPhoneValue;
@property (weak) IBOutlet NSTextField *nameValue;
@property (weak) IBOutlet NSTextField *genderValue;
@property (weak) IBOutlet NSTextField *ageValue;
@property (weak) IBOutlet NSScrollView *personnelScrollView;
@property (weak) IBOutlet NSScrollView *recordScrollView;
//@property (weak) IBOutlet NSTableView *personnelTableView;
//@property (weak) IBOutlet NSTableView *recordTableView;
@property (weak) IBOutlet NSDatePicker *datePicker;

@end

NS_ASSUME_NONNULL_END
