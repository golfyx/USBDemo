//
//  ReportsViewCell.h
//  USBDemo
//
//  Created by golfy on 2021/12/21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ReportsViewCellDelegate <NSObject>

@optional
- (void)downloadPDF:(int)index;

@end

@interface ReportsViewCell : NSTableCellView

@property (nonatomic, weak) id<ReportsViewCellDelegate> delegate;

@property (weak) IBOutlet NSTextField *typeTextField;
@property (weak) IBOutlet NSTextField *timeTextField;
@property (weak) IBOutlet NSTextField *stateTextField;
@property (nonatomic, assign) NSInteger index;

@end

NS_ASSUME_NONNULL_END
