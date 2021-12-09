//
//  HIDDevice.h
//  USBDemo
//
//  Created by golfy on 2021/10/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DeviceDelegate <NSObject>
-(void)idrReaderOpened;
-(void)idrReaderClosed;
@end

@interface HIDDevice : NSObject

-(BOOL) initialize:(id<DeviceDelegate>) delegate;
-(void) finalize;
-(IOReturn) hidRead:(unsigned char *)buffer size:(long)size;
-(IOReturn) hidWrite:(const unsigned char *)buffer size:(long)size;

@end

NS_ASSUME_NONNULL_END
