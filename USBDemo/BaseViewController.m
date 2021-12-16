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

#import "CommonUtil.h"

#import "SCProgressIndicator.h"

@interface BaseViewController () <ScreeningViewDelegate>
@property (weak) IBOutlet NSView *contentCustomView;
@property (weak) IBOutlet NSSegmentedControl *topSegmentedControl;

@property (nonatomic, strong) HolterGriddingView *holterGriddingView;

@property (nonatomic, strong) ScreeningView *screeningView;
@property (nonatomic, strong) DeviceInteractionView *deviceInteractionView;

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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.screeningView.frame = CGRectMake(0, 10, self.contentCustomView.frame.size.width, self.contentCustomView.frame.size.height - 10);
    [self.contentCustomView addSubview:self.screeningView];
    
}

- (IBAction)topSegmentedControlAction:(NSSegmentedControl *)sender {
    
    switch (sender.selectedSegment) {
        case 0:
        {
            [self.deviceInteractionView removeFromSuperview];
            self.screeningView.frame = CGRectMake(0, 10, self.contentCustomView.frame.size.width, self.contentCustomView.frame.size.height - 10);
            [self.contentCustomView addSubview:self.screeningView];
            [self.screeningView activeBleHandle];
        }
            break;
        case 1:
        {
            [self.screeningView removeFromSuperview];
            self.deviceInteractionView.frame = CGRectMake(0, 10, self.contentCustomView.frame.size.width, self.contentCustomView.frame.size.height - 10);
            [self.contentCustomView addSubview:self.deviceInteractionView];
            [self.deviceInteractionView activeBleHandle];
        }
            break;
            
        default:
            break;
    }
}

- (void)didStopAndUploadData {
    if (!self.presentingViewController) {
        self.progressIndicator = (SCProgressIndicator *)[CommonUtil getViewFromNibName:@"SCProgressIndicator"];
    }
    self.progressIndicator.progressTitle.stringValue = @"正在上传数据，请稍后...";
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

@end
