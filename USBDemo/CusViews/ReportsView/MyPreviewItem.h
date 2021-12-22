//
//  MyPreviewItem.h
//  USBDemo
//
//  Created by golfy on 2021/12/22.
//

#import <Foundation/Foundation.h>
#import <QuickLookUI/QLPreviewItem.h>

NS_ASSUME_NONNULL_BEGIN

@interface MyPreviewItem : NSObject<QLPreviewItem>

@property(nullable, nonatomic) NSURL *previewItemURL;
@property(nullable, nonatomic) NSString *previewItemTitle;
@property(nullable, nonatomic) id previewItemDisplayState;

@end

NS_ASSUME_NONNULL_END
