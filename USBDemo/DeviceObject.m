//
//  DeviceObject.m
//  USBDemo
//
//  Created by golfy on 2021/10/18.
//

#import "DeviceObject.h"
 
@implementation DeviceObject
 
@synthesize notification;
@synthesize interface;
@synthesize locationID;
@synthesize deviceName;
 
@synthesize dev;
@synthesize pipeIn;
@synthesize pipeOut;
@synthesize maxPacketSizeIn;
@synthesize maxPacketSizeOut;
 
@end
