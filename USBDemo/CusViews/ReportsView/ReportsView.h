//
//  ReportsView.h
//  USBDemo
//
//  Created by golfy on 2021/12/21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReportsView : NSView

@property (weak) IBOutlet NSTextField *userPhoneValue;
@property (weak) IBOutlet NSTextField *nameValue;
@property (weak) IBOutlet NSTextField *genderValue;
@property (weak) IBOutlet NSTextField *ageValue;
@property (weak) IBOutlet NSScrollView *recordScrollView;

@end

NS_ASSUME_NONNULL_END
