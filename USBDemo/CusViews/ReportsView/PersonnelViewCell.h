//
//  PersonnelViewCell.h
//  USBDemo
//
//  Created by golfy on 2021/12/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN


@protocol PersonnelViewCellDelegate <NSObject>

@optional
- (void)downloadPDF:(NSInteger)index;

@end

@interface PersonnelViewCell : NSTableCellView

@property (nonatomic, weak) id<PersonnelViewCellDelegate> delegate;

@property (weak) IBOutlet NSTextField *nameTextField;
@property (weak) IBOutlet NSTextField *genderTextField;
@property (weak) IBOutlet NSTextField *ageTextField;
@property (weak) IBOutlet NSTextField *phoneTextField;
@property (nonatomic, assign) NSInteger index;

@end

NS_ASSUME_NONNULL_END
