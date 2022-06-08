//
//  SCReportInfo.m
//  USBDemo
//
//  Created by golfy on 2021/12/21.
//

#import "SCReportInfo.h"

@implementation SCDoctorInfoVOS


@end

@implementation SCReportInfo

-(NSString *)description {
    
    NSMutableString *tmpStr = [NSMutableString stringWithFormat:@"%d : ",self.detectionId];
    
    for (int i = 0; i < self.doctorInfoVOS.count; i++) {
        [tmpStr appendString:self.doctorInfoVOS[i][@"reportUrl"]];
    }
    
    return tmpStr;
}

@end
