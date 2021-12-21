//
//  ReportsViewCell.m
//  USBDemo
//
//  Created by golfy on 2021/12/21.
//

#import "ReportsViewCell.h"

@implementation ReportsViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    
}
- (IBAction)downloadPDF:(NSButton *)sender {
    
    if ([self.delegate respondsToSelector:@selector(downloadPDF:)]) {
        [self.delegate downloadPDF:self.index];
    }
    
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
