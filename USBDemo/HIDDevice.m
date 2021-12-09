//
//  HIDDevice.m
//  USBDemo
//
//  Created by golfy on 2021/10/12.
//

#import "HIDDevice.h"
#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDLib.h>
#import <IOKit/hid/IOHIDKeys.h>

static const NSInteger iDR210_VID = 0x250;
static const NSInteger iDR210_PID = 0x2b222;

@implementation HIDDevice {
    @private
    IOHIDManagerRef gIOHIDManager;
    IOHIDDeviceRef  gIOHIDDev;
    id<DeviceDelegate> devDelegate;
}

- (BOOL)initialize:(id<DeviceDelegate>) delegate{
    gIOHIDDev = NULL;
    gIOHIDManager = IOHIDManagerCreate( kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    if (gIOHIDManager) {
        devDelegate = delegate;
        
//        IOReturn res = IOHIDManagerOpen(gIOHIDManager, kIOHIDOptionsTypeNone);
//        NSLog(@"- open mgr:%x", res);
 
        // schedule with runloop
        IOHIDManagerScheduleWithRunLoop(gIOHIDManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        // register callbacks
        IOHIDManagerRegisterDeviceMatchingCallback(gIOHIDManager, devMatchingCallback, (__bridge void *)(self));
        IOHIDManagerRegisterDeviceRemovalCallback(gIOHIDManager, devRemovalCallback, (__bridge void *)(self));
        IOHIDManagerSetDeviceMatching(gIOHIDManager, NULL);
        return YES;
    }
    return NO;
}
 
-(void) finalize {
    if(gIOHIDDev){
        [self closeDevice];
    }
    
    if (gIOHIDManager) {
        IOHIDManagerUnscheduleFromRunLoop(gIOHIDManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        
        IOReturn ioreturn = IOHIDManagerClose(gIOHIDManager, kIOHIDOptionsTypeNone);
        NSLog(@"close IOHIDManager(%x).", ioreturn);
 
    }
    devDelegate = NULL;
}
 
-(void)setIOHIDDevFound:(IOHIDDeviceRef) dev attach:(BOOL)isAttach{
    if (isAttach) {
        NSLog(@"routon HIDReader attach");
        
        [self openDevice:dev];
    }else{
        NSLog(@"routon HIDReader detach");
        [self closeDevice];
    }
}
 
static void devMatchingCallback(void * inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef) {
    if(isIDR210Reader(inIOHIDDeviceRef)){
        [(__bridge HIDDevice *)inContext setIOHIDDevFound:inIOHIDDeviceRef attach:YES];
    }
}
 
static  void devRemovalCallback(void * inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef) {
    if(isIDR210Reader(inIOHIDDeviceRef)){
        [(__bridge HIDDevice *)inContext setIOHIDDevFound:inIOHIDDeviceRef attach:NO];
    }
}
 
static Boolean isIDR210Reader(IOHIDDeviceRef inIOHIDDeviceRef){
    uint32_t vid = IOHIDDevGetUInt32Property(inIOHIDDeviceRef, CFSTR(kIOHIDVendorIDKey));
    uint32_t pid = IOHIDDevGetUInt32Property(inIOHIDDeviceRef, CFSTR(kIOHIDProductIDKey));
    return iDR210_VID == vid && iDR210_PID == pid;
}
 
static uint32_t IOHIDDevGetUInt32Property(IOHIDDeviceRef inIOHIDDeviceRef, CFStringRef inKey) {
    uint32_t outValue = 0;
    if (inIOHIDDeviceRef != NULL) {
        CFTypeRef tCFTypeRef = IOHIDDeviceGetProperty(inIOHIDDeviceRef, inKey);
        if (tCFTypeRef != NULL && (CFNumberGetTypeID() == CFGetTypeID(tCFTypeRef))  ) {
            Boolean result = CFNumberGetValue((CFNumberRef) tCFTypeRef, kCFNumberSInt32Type, &outValue);
            if (!result) {
                NSLog(@"get %@ failed.", inKey);
            }
        }
    }
 
    return outValue;
}
 
static void _ykosx_CopyToCFArray(const void *value, void *context) {
    CFArrayAppendValue( ( CFMutableArrayRef ) context, value );
}
 
-(void) findDevice{
    IOHIDDeviceRef device = NULL;
    CFDictionaryRef dict;
    CFStringRef keys[2];
    CFStringRef values[2];
    
    CFNumberRef vendorID = CFNumberCreate( kCFAllocatorDefault, kCFNumberIntType, &iDR210_VID );
    CFNumberRef productID = CFNumberCreate( kCFAllocatorDefault, kCFNumberIntType, &iDR210_PID );
    
    keys[0] = CFSTR( kIOHIDVendorIDKey );  values[0] = (void *) vendorID;
    keys[1] = CFSTR( kIOHIDProductIDKey ); values[1] = (void *) productID;
    
    dict = CFDictionaryCreate( kCFAllocatorDefault, (const void **) &keys, (const void **) &values, 1, NULL, NULL);
    
    IOHIDManagerSetDeviceMatching( gIOHIDManager, dict );
    
    CFSetRef devSet = IOHIDManagerCopyDevices( gIOHIDManager );
    
    if ( devSet ) {
        
        CFMutableArrayRef array = CFArrayCreateMutable( kCFAllocatorDefault, 0, NULL );
        
        CFSetApplyFunction( devSet, _ykosx_CopyToCFArray, array );
        
        CFIndex cnt = CFArrayGetCount( array );
        
        if (cnt > 0) {
            device = (IOHIDDeviceRef) CFArrayGetValueAtIndex( array, 0 );
        }
        
        CFRelease( array );
        CFRelease( devSet );
    }
    
    CFRelease( dict );
    CFRelease( vendorID );
    CFRelease( productID );
    
    if (device) {
        CFStringRef info = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));
        char manufacturer[256] = "";    // name of manufacturer
        (CFStringGetCString(info, manufacturer, sizeof(manufacturer), kCFStringEncodingUTF8));
        
        NSLog(@"Found devie:%s.", manufacturer);
        [self openDevice:device];
    }
}
 
-(IOReturn)checkHIDDevice{
    if (!gIOHIDDev) {
        NSLog(@"close devie failed(%x).", kIOReturnNotOpen);
        return kIOReturnNotOpen;
    }
    return kIOReturnSuccess;
}
 
-(IOReturn)openDevice:(IOHIDDeviceRef)device{
    IOReturn ioReturn = IOHIDDeviceOpen( device, kIOHIDOptionsTypeNone );
 
 
    if ( kIOReturnSuccess == ioReturn ) {
        gIOHIDDev = device;
        if(devDelegate){
            [devDelegate idrReaderOpened];
        }
    }else{
        gIOHIDDev = NULL;
    }
    NSLog(@"open devie (%x).", ioReturn);
    return ioReturn;
}
 
-(IOReturn)closeDevice {
    IOReturn ioReturn = [self checkHIDDevice];
    if (kIOReturnSuccess == ioReturn) {
        ioReturn = IOHIDDeviceClose( gIOHIDDev, kIOHIDOptionsTypeNone );
    }
    NSLog(@"close devie (%x).", ioReturn);
    gIOHIDDev = NULL;
    if (devDelegate) {
        [devDelegate idrReaderClosed];
    }
    return ioReturn;
}
 
-(IOReturn)hidWrite:(const unsigned char *)buffer size:(long)size {
    IOReturn ioReturn = [self checkHIDDevice];
    if (kIOReturnSuccess == ioReturn) {
        ioReturn = IOHIDDeviceSetReport( gIOHIDDev, kIOHIDReportTypeOutput, 0, buffer, size);
        
    }
    
    if ( ioReturn != kIOReturnSuccess ) {
        NSLog(@"write devie (%x).", ioReturn);
    }
    
    return ioReturn;
}
 
-(IOReturn)hidRead:(unsigned char *)buffer size:(long)size{
    CFIndex sizecf = size;
    IOReturn ioReturn = [self checkHIDDevice];
    if ( kIOReturnSuccess == ioReturn ) {
        // write完必须间隔几毫秒再read,否则在210,240设备上会导致高频率读写失败.
        [NSThread sleepForTimeInterval:(0.005)];
        ioReturn = IOHIDDeviceGetReport( gIOHIDDev, kIOHIDReportTypeInput, 0, (uint8_t *)buffer, &sizecf );
        if ( kIOReturnSuccess == ioReturn ) {
            ioReturn = (int)sizecf;
        }else{
            NSLog(@"read devie (%x).", ioReturn);
        }
    }
    return ioReturn;
}

@end
