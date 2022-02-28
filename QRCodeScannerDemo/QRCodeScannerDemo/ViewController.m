//
//  ViewController.m
//  QRCodeScannerDemo
//
//  Created by 朱博文 on 16/6/17.
//  Copyright © 2016年 朱博文. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeScannerUtility.h"
#import <ZBWQRCodeScanner/QRCodeScannerUtility.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotification:) name:@"ScannerResultNotification" object:nil];
}


- (void)onNotification:(NSNotification *)notif
{
    NSString *value = notif.object;
    
    self.textView.text = value;
}

- (IBAction)onGenerate:(id)sender {
    UIImage *image = [QRCodeScannerUtility scQRCodeForString:self.textView.text size:180.0];
    
    self.imageView.image = image;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
