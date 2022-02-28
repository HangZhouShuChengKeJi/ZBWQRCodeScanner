//
//  ScannerViewController.m
//  QRCodeScannerDemo
//
//  Created by 朱博文 on 16/6/17.
//  Copyright © 2016年 朱博文. All rights reserved.
//

#import "ScannerViewController.h"
#import <ZBWQRCodeScanner/QRCodeScanner.h>

@interface ScannerViewController ()<QRCodeScannerInterfaceDelegate,QRCodeScannerDeviceExceptionDelegate>

@property(nonatomic, retain) QRCodeScannerView *scannerView;

@end

@implementation ScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    __weak typeof(self) weakSelf = self;

    QRCodeScannerView *scannerView = [QRCodeScannerView scannerViewWithDelegate:self
                                                           photoPickerShowBlock:nil
                                                        photoPickerdismissBlock:nil
                                                                         result:^(NSString *resultStr,
                                                                                  ZBWCodeType type,
                                                                                  BOOL isFromPhoto) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ScannerResultNotification" object:resultStr];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }];
    
    [self.view addSubview:scannerView];
    
    self.scannerView = scannerView;
}

- (void)dealloc {
    [self.scannerView pauseScanner];
}



@end
