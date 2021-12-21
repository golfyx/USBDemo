//
//  ReportsView.m
//  USBDemo
//
//  Created by golfy on 2021/12/21.
//

#import "ReportsView.h"

#import "CommonUtil.h"
#import "SCRequestHandle.h"
#import "SCAppVaribleHandle.h"
#import "WDLog.h"
#import "EMRToast.h"
#import "MJExtension.h"
#import "SCReportInfo.h"
#import "ReportsViewCell.h"

@interface ReportsView ()<NSTableViewDelegate, NSTableViewDataSource, ReportsViewCellDelegate>


@property (nonatomic, strong) NSTableView *recordTableView;
@property (nonatomic, strong) NSMutableArray<SCReportInfo *> *recordDataArray;

@property (nonatomic, strong) NSString *documentPath;

@end

@implementation ReportsView

- (NSTableView *)recordTableView {
    if (!_recordTableView) {
        _recordTableView = [[NSTableView alloc]initWithFrame:_recordScrollView.bounds];
        NSTableColumn *column = [[NSTableColumn alloc]initWithIdentifier:@"recordTableColumn"];
        column.title = @" ";
        column.width = 400;
        [_recordTableView addTableColumn:column];
        _recordTableView.delegate = self;
        _recordTableView.dataSource = self;
        _recordScrollView.contentView.documentView = _recordTableView;
    }
    
    return _recordTableView;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _recordDataArray = [NSMutableArray array];
    
    self.recordTableView.wantsLayer = YES;
    
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return _recordDataArray.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row  {
    ReportsViewCell *cell = (ReportsViewCell *)[CommonUtil getViewFromNibName:@"ReportsViewCell"];
    cell.delegate = self;
    
    SCReportInfo *reportInfo = _recordDataArray[row];
    cell.typeTextField.stringValue = reportInfo.detectionType == 27 ? @"动态心电" : @"心脏负荷";
    cell.timeTextField.stringValue = (!reportInfo.detectionTime || [reportInfo.detectionTime isKindOfClass:NSNull.class]) ? @"--" : reportInfo.detectionTime;
    cell.stateTextField.stringValue = reportInfo.doctorState == 2 ? @"已出报告" : @"未出报告";
    cell.index = row;
    
    return cell;
}

- (void)downloadPDF:(int)index {
    NSMutableArray<NSDictionary *> *doctorInfoVOSArray = _recordDataArray[index].doctorInfoVOS;
    if (doctorInfoVOSArray && doctorInfoVOSArray.count > 0) {
        
        NSDictionary *doctorInfoVOS = doctorInfoVOSArray[0];
        NSString *reportUrl = doctorInfoVOS[@"reportUrl"];
        if (reportUrl && ![reportUrl isKindOfClass:NSNull.class]) {
            NSString *documentPath = [self createFilePath:_recordDataArray[index].detectionTime];
            [SCRequestHandle downloadPDFReportUrl:reportUrl fileDir:documentPath completion:^(BOOL success, id  _Nonnull responseObject) {
                if (success) {
                    NSString *reportUrlStr = responseObject;
                    if ([reportUrlStr hasPrefix:@"file://"]) {
                        reportUrlStr = [reportUrlStr substringFromIndex:6];
                    }
                    NSString *toFilePath = [NSString stringWithFormat:@"%@/%@.PDF", documentPath, self.nameValue.stringValue];
                    [self moveItemAtPath:reportUrlStr toPath:toFilePath overwrite:YES error:nil];
                } else {
                    [EMRToast Show:[self handlingInvalidData:responseObject title:@"获取用户信息失败"]];
                }
            }];
        } else {
            NSLog(@"没有reportUrl");
        }
    } else {
        NSLog(@"没有doctorInfoVOS");
    }
}

#pragma mark - 移动文件(夹)
/*参数1、被移动文件路径
 *参数2、要移动到的目标文件路径
 *参数3、当要移动到的文件路径文件存在，会移动失败，这里传入是否覆盖
 *参数4、错误信息
 */
- (BOOL)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath overwrite:(BOOL)overwrite error:(NSError **)error {
    // 先要保证源文件路径存在，不然抛出异常
    if (![self isExistsAtPath:path]) {
        [NSException raise:@"非法的源文件路径" format:@"源文件路径%@不存在，请检查源文件路径", path];
        return NO;
    }
    //获得目标文件的上级目录
    NSString *toDirPath = [self directoryAtPath:toPath];
    if (![self isExistsAtPath:toDirPath]) {
        // 创建移动路径
        if (![self createDirectoryAtPath:toDirPath error:error]) {
            return NO;
        }
    }
    // 判断目标路径文件是否存在
    if ([self isExistsAtPath:toPath]) {
        //如果覆盖，删除目标路径文件
        if (overwrite) {
            //删掉目标路径文件
            [self removeItemAtPath:toPath error:error];
        }else {
           //删掉被移动文件
            [self removeItemAtPath:path error:error];
            return YES;
        }
    }
    
    // 移动文件，当要移动到的文件路径文件存在，会移动失败
    BOOL isSuccess = [[NSFileManager defaultManager] moveItemAtPath:path toPath:toPath error:error];
    
    return isSuccess;
}
#pragma mark - 判断文件(夹)是否存在
- (BOOL)isExistsAtPath:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}
- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error {
    return [[NSFileManager defaultManager] removeItemAtPath:path error:error];
}
- (NSString *)directoryAtPath:(NSString *)path {
    return [path stringByDeletingLastPathComponent];
}
- (BOOL)createDirectoryAtPath:(NSString *)path error:(NSError **)error {
    NSFileManager *manager = [NSFileManager defaultManager];
    /* createDirectoryAtPath:withIntermediateDirectories:attributes:error:
     * 参数1：创建的文件夹的路径
     * 参数2：是否创建媒介的布尔值，一般为YES
     * 参数3: 属性，没有就置为nil
     * 参数4: 错误信息
    */
    BOOL isSuccess = [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:error];
    return isSuccess;
}

- (NSString *)createFilePath:(NSString *)time {
    
    if (!time || [time isKindOfClass:NSNull.class]) {
        time = @"2000-01-01";
    }
    
    // 文件保存的路径
    _documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    _documentPath = [NSString stringWithFormat:@"%@/Reports/%@", _documentPath, [time componentsSeparatedByString:@" "].firstObject];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:_documentPath]) {
        WDLog(LOG_MODUL_FILE ,@"目录已经存在");
    } else {
        if ([fileManager createDirectoryAtPath:_documentPath withIntermediateDirectories:YES attributes:nil error:nil]) {
            WDLog(LOG_MODUL_FILE ,@"目录创建成功");
        } else{
            WDLog(LOG_MODUL_FILE ,@"目录创建失败");
        }
    }
    
    return _documentPath;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 70;
}
- (IBAction)openReportsPath:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] selectFile:nil inFileViewerRootedAtPath:self.documentPath];
}

- (IBAction)getReportsList:(NSButton *)sender {
    
    if (![CommonUtil validateMobile:self.userPhoneValue.stringValue]) {
        [EMRToast Show:@"请填写正确的手机号"];
        return;
    }
    
    NSString *captcha = @"998080"; /// 为了筛查写的固定验证码
    
    [SCRequestHandle userLoginWithPhone:self.userPhoneValue.stringValue captcha:captcha completion:^(BOOL success, id  _Nonnull responseObject) {
        if (success) {
            WDLog(LOG_MODUL_HTTPREQUEST, @"登录成功");
            [SCRequestHandle getCurUserInfoCompletion:^(BOOL success, id  _Nonnull responseObject) {
                if (success) {
                    
                    WDLog(LOG_MODUL_HTTPREQUEST, @"获取用户信息成功");
                    
                    // 记录id用于后续操作
                    int memberId = [[CommonUtil dataProcessing:responseObject title:@"memberId" isInt:YES] intValue];
                    NSString *name = [CommonUtil dataProcessing:responseObject title:@"name" isInt:NO];
                    GenderType genderType = [[CommonUtil dataProcessing:responseObject title:@"gender" isInt:YES] intValue];
                    NSString *birthday = [CommonUtil dataProcessing:responseObject title:@"birthdate" isInt:NO];
                    
                    self.nameValue.stringValue = name;
                    self.genderValue.stringValue = (GenderType_male == genderType ? @"男" : GenderType_female == genderType ? @"女" : @"未知");
                    self.ageValue.stringValue = [CommonUtil calAgeByBirthday:birthday];
                    
                    [SCRequestHandle getECGRecordList:memberId completion:^(BOOL success, id  _Nonnull responseObject) {
                        if (success) {
                            self.recordDataArray = [SCReportInfo mj_objectArrayWithKeyValuesArray:responseObject[@"data"]];
                            
                            [self.recordTableView reloadData];
                        } else {
                            [EMRToast Show:[self handlingInvalidData:responseObject title:@"获取记录列表失败"]];
                        }
                    }];
                    
                } else {
                    [EMRToast Show:[self handlingInvalidData:responseObject title:@"获取用户信息失败"]];
                }
            }];
        } else {
            [EMRToast Show:[self handlingInvalidData:responseObject title:@"登录失败"]];
        }
    }];
    
}

- (NSString *)handlingInvalidData:(id)responseObject title:(NSString *)title {
    NSString *msg = (responseObject[@"msg"] && ![responseObject isKindOfClass:NSNull.class]) ? responseObject[@"msg"] : title;
    WDLog(LOG_MODUL_HTTPREQUEST, @"%@", msg);
    return msg;
}



@end
