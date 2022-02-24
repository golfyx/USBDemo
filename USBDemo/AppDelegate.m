//
//  AppDelegate.m
//  USBDemo
//
//  Created by golfy on 2021/10/9.
//

#import "AppDelegate.h"
#import "SCBulkDataHandle.h"

@interface AppDelegate ()


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    for (DeviceObject *deviceObject in [[SCBulkDataHandle sharedManager] getDeviceArray]) {
        [[SCBulkDataHandle sharedManager] sendReadUSBBulkAndClearCacheCmd:deviceObject readUSBBulk:2];
    }
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

// 当最后一个窗口关闭后关闭APP
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
