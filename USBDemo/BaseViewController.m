//
//  BaseViewController.m
//  USBDemo
//
//  Created by golfy on 2021/11/18.
//

#import "BaseViewController.h"
#import "UsbMonitor.h"
#import "ShortcutHeader.h"
#import "HolterGriddingView.h"
#import "HolterChartView.h"

#import "ScreeningView.h"
#import "DeviceInteractionView.h"
#import "ReportsView.h"

#import "CommonUtil.h"
#import "WDLog.h"

#import "SCProgressIndicator.h"
#import "ConfigureHandle.h"

@interface BaseViewController () <ScreeningViewDelegate, ReportsViewDelegate>
@property (weak) IBOutlet NSView *contentCustomView;
@property (weak) IBOutlet NSSegmentedControl *topSegmentedControl;

@property (nonatomic, strong) HolterGriddingView *holterGriddingView;

@property (nonatomic, strong) ScreeningView *screeningView;
@property (nonatomic, strong) DeviceInteractionView *deviceInteractionView;
@property (nonatomic, strong) ReportsView *reportsView;

@property (nonatomic, strong) SCProgressIndicator *progressIndicator;

@end

@implementation BaseViewController

- (ScreeningView *)screeningView {
    if (!_screeningView) {
        _screeningView = (ScreeningView *)[CommonUtil getViewFromNibName:@"ScreeningView"];
        _screeningView.delegate = self;
    }
    return _screeningView;
}


- (DeviceInteractionView *)deviceInteractionView {
    if (!_deviceInteractionView) {
        _deviceInteractionView = (DeviceInteractionView *)[CommonUtil getViewFromNibName:@"DeviceInteractionView"];
    }
    return _deviceInteractionView;
}

- (ReportsView *)reportsView {
    if (!_reportsView) {
        _reportsView = (ReportsView *)[CommonUtil getViewFromNibName:@"ReportsView"];
        _reportsView.delegate = self;
    }
    return _reportsView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    // 打开全部LOG日志
    [WDLog sharedInstance].logLevelValue = LOG_ALL & (~LOG_MODUL_HIGHLEVEL);
    
    self.screeningView.frame = CGRectMake(0, 10, self.contentCustomView.frame.size.width, self.contentCustomView.frame.size.height - 10);
    [self.contentCustomView addSubview:self.screeningView];
    
    if (ConfigureHandleInstance.isScreeningMode) {
        self.topSegmentedControl.segmentCount = 2;
    }
    
    NSString *tmpStr = @"🀁中(￣▽￣)~*文[jSh😁12🐛j]";
    tmpStr = @"中文jSh12j";
    if (![CommonUtil validateUserName:tmpStr]) {
        NSLog(@"%@", [CommonUtil validateUserNameAndInterception:tmpStr]);
    }
    
}

- (IBAction)topSegmentedControlAction:(NSSegmentedControl *)sender {
    
    switch (sender.selectedSegment) {
        case 0:
        {
            [self.deviceInteractionView removeFromSuperview];
            [self.reportsView removeFromSuperview];
            self.screeningView.frame = CGRectMake(0, 10, self.contentCustomView.frame.size.width, self.contentCustomView.frame.size.height - 10);
            [self.contentCustomView addSubview:self.screeningView];
            [self.screeningView activeBleHandle];
        }
            break;
        case 1:
        {
            [self.screeningView removeFromSuperview];
            [self.deviceInteractionView removeFromSuperview];
            self.reportsView.frame = CGRectMake(0, 10, self.contentCustomView.frame.size.width, self.contentCustomView.frame.size.height - 10);
            self.reportsView.viewController = self;
            [self.contentCustomView addSubview:self.reportsView];
        }
            break;
        case 2:
        {
            [self.screeningView removeFromSuperview];
            [self.reportsView removeFromSuperview];
            self.deviceInteractionView.frame = CGRectMake(0, 10, self.contentCustomView.frame.size.width, self.contentCustomView.frame.size.height - 10);
            [self.contentCustomView addSubview:self.deviceInteractionView];
            [self.deviceInteractionView activeBleHandle];
        }
            break;
            
        default:
            break;
    }
}

- (void)didShowProgressIndicatorWithTitle:(NSString *)title {
    
    if (!self.presentingViewController) {
        self.progressIndicator = (SCProgressIndicator *)[CommonUtil getViewFromNibName:@"SCProgressIndicator"];
    }
    self.progressIndicator.progressTitle.stringValue = title.length > 0 ? title : @"请稍后...";
    [self.progressIndicator layoutSubviews:self.view.frame];
    [self.view addSubview:self.progressIndicator];
    [self.progressIndicator startAnimation];
}

- (void)didCompleteUploadData {
    if (self.progressIndicator) {
        [self.progressIndicator stopAnimation];
        [self.progressIndicator removeFromSuperview];
        self.progressIndicator = nil;
    }
}


- (void)didStartDownloadPDF {
    if (!self.presentingViewController) {
        self.progressIndicator = (SCProgressIndicator *)[CommonUtil getViewFromNibName:@"SCProgressIndicator"];
    }
    self.progressIndicator.progressTitle.stringValue = @"正在下载PDF文件，请稍后...";
    [self.progressIndicator layoutSubviews:self.view.frame];
    [self.view addSubview:self.progressIndicator];
    [self.progressIndicator startAnimation];
    
}

- (void)didCompleteHandleData {
    if (self.progressIndicator) {
        [self.progressIndicator stopAnimation];
        [self.progressIndicator removeFromSuperview];
        self.progressIndicator = nil;
    }
}

@end
