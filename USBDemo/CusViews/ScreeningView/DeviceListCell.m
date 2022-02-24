//
//  DeviceListCell.m
//  USBDemo
//
//  Created by golfy on 2022/2/24.
//

#import "DeviceListCell.h"

@implementation DeviceListCell

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (IBAction)connectDeviceButtonAction:(NSButton *)sender {
    
    if ([self.delegate respondsToSelector:@selector(connectDevice:index:)]) {
        [self.delegate connectDevice:self index:self.index];
    }
    
}

@end
