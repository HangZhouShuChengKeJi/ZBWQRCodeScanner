//
//  QRCodeScannerView.m
//  QRScannerDemo
//
//  Created by 朱博文 on 16/6/17.
//  Copyright © 2016年 zhangfei. All rights reserved.
//

#import "QRCodeScannerView.h"

#import <AVFoundation/AVFoundation.h>
#import "QRCodeScannerUtility.h"
#import <ZXingObjC/ZXBarcodeFormat.h>

#define QRCodeScannerView_Height_Scale (CGRectGetHeight([UIScreen mainScreen].bounds)/480)

#define QRCodeScannerView_V_Space  (20 * QRCodeScannerView_Height_Scale)
#define QRCodeScannerView_H_Space  10
#define QRCodeScannerView_DefaultColor [UIColor colorWithRed:255/255.0 green:51/255.0 blue:103/255.0 alpha:1]


UIImage *imageInQRCodeScannerBundle(NSString *imageName)
{
    NSString*path = [[NSBundle mainBundle] pathForResource:@"QRCodeScanner" ofType:@"bundle"];
    NSBundle *bundle =  [NSBundle bundleWithPath:path];
    return [UIImage imageWithContentsOfFile:[bundle pathForResource:imageName ofType:@"png"]];
}


@interface QRCScannerMaskView : UIView

// 指示器
@property (nonatomic) QRCScannerIndicatorType       lineType;
@property (nonatomic) UIImage                       *indicatorImage;
@property (nonatomic) UIColor                       *indicatorLineColor;

@property (nonatomic) UIColor                       *cornerLineColor;

@property (nonatomic) CGRect                        scannerRect;
@property (nonatomic) UIView                        *scanIndicatorView;

- (void)startScannerAnimation;
- (void)pauseScannerAnimation;

@end

@implementation QRCScannerMaskView

- (void)startScannerAnimation
{
    [self pauseScannerAnimation];
    
    CGFloat distance = CGRectGetHeight(_scannerRect);
    CGFloat x = CGRectGetMidX(self.bounds);
    CGFloat y = CGRectGetMinY(_scannerRect);// - self.scanIndicatorView.frame.size.height / 2;
    self.scanIndicatorView.center = CGPointMake(x, y);
    self.scanIndicatorView.hidden = NO;
    
    [UIView beginAnimations:@"" context:nil];
    
    [UIView setAnimationDuration:2];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationRepeatCount:HUGE_VALF];
    
    self.scanIndicatorView.center = CGPointMake(x, y + distance);
    
    [UIView commitAnimations];
}

- (void)pauseScannerAnimation
{
    [self.scanIndicatorView.layer removeAllAnimations];
    self.scanIndicatorView.hidden = YES;
}

- (void)dealloc
{
//    NSLog(@"释放 QRCScannerMaskView");
}

- (void)initSubViews
{
    [_scanIndicatorView removeFromSuperview];
    
    if (self.lineType == QRCScannerIndicatorType_ColorLine) {
        
        _scanIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(_scannerRect),
                                                                      CGRectGetMinY(_scannerRect) - .5,
                                                                      CGRectGetWidth(_scannerRect),
                                                                      1)];
        _scanIndicatorView.backgroundColor = self.indicatorLineColor ? : [UIColor redColor];
        
    } else {
        self.indicatorImage = self.indicatorImage ? : imageInQRCodeScannerBundle(@"scan_indicator_line@2x");
        _scanIndicatorView = [[UIImageView alloc] initWithImage:self.indicatorImage];
        _scanIndicatorView.frame = CGRectMake(CGRectGetMinX(_scannerRect),
                                              CGRectGetMinY(_scannerRect) - self.indicatorImage.size.height / 2,
                                              CGRectGetWidth(_scannerRect),
                                              self.indicatorImage.size.height);
    }
    
    [self addSubview:_scanIndicatorView];
    
    [self startScannerAnimation];
}

- (void)drawRect:(CGRect)rect
{
    self.backgroundColor = [UIColor clearColor];
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[[UIColor blackColor] colorWithAlphaComponent:.5] setFill];
    CGContextFillRect(context, rect);
    
    CGContextClearRect(context, self.scannerRect);
    
    CGFloat cornerLength = 15;
    CGFloat cornerLineWidth = 2;
    CGFloat minX = CGRectGetMinX(self.scannerRect) + cornerLineWidth / 2;
    CGFloat minY = CGRectGetMinY(self.scannerRect) + cornerLineWidth / 2;
    CGFloat maxX = CGRectGetMaxX(self.scannerRect) - cornerLineWidth / 2;
    CGFloat maxY = CGRectGetMaxY(self.scannerRect) - cornerLineWidth / 2;
    
    [self.cornerLineColor setStroke];
    CGContextSetLineWidth(context, cornerLineWidth);
    CGContextSetLineCap(context, kCGLineCapSquare);
    
    CGContextMoveToPoint(context, minX, minY + cornerLength);
    CGContextAddLineToPoint(context, minX, minY);
    CGContextAddLineToPoint(context, minX + cornerLength, minY);
    
    CGContextMoveToPoint(context, maxX - cornerLength, minY);
    CGContextAddLineToPoint(context, maxX, minY);
    CGContextAddLineToPoint(context, maxX, minY + cornerLength);
    
    CGContextMoveToPoint(context, maxX, maxY - cornerLength);
    CGContextAddLineToPoint(context, maxX, maxY);
    CGContextAddLineToPoint(context, maxX - cornerLength, maxY);
    
    CGContextMoveToPoint(context, minX + cornerLength, maxY);
    CGContextAddLineToPoint(context, minX, maxY);
    CGContextAddLineToPoint(context, minX, maxY - cornerLength);
    
    CGContextStrokePath(context);
    
    [self initSubViews];
}

@end


@interface QRCodeScannerView() <AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) QRCScannerMaskView        *scannerMaskView;
@property (nonatomic) UILabel                   *tipStrLable;
@property (nonatomic) UIButton                  *lightBtn;
@property (nonatomic) UIButton                  *photoBtn;
@property (nonatomic) UIView                    *scanIndicatorView;

@property (nonatomic,assign)CGRect clearDrawRect;
@property (nonatomic,assign)BOOL isOn;

@property (nonatomic,strong)AVCaptureSession *session;
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *preview;
@property (nonatomic,strong)AVCaptureDeviceInput * input;
@property (nonatomic,strong)AVCaptureMetadataOutput * output;
@property (nonatomic,strong)AVCaptureDevice * device;

@property (nonatomic)   dispatch_queue_t    queue;

@property (nonatomic, strong) NSTimer       *focusTimer;


@property (nonatomic, weak) id <QRCodeScannerInterfaceDelegate, QRCodeScannerDeviceExceptionDelegate>  delegate;

@property (nonatomic, copy) void (^scanResultBlock)(NSString *resultStr, ZBWCodeType type, BOOL isFromPhoto);
@property (nonatomic, copy) void (^photoPickerShowBlock)(UIImagePickerController *viewcontroller);
@property (nonatomic, copy) void (^photoPickerDismissBlock)(UIImagePickerController *viewcontroller);


@property (nonatomic, copy) NSArray                 *codeTypes;
@property (nonatomic, assign) ZBWCodeType           codeType;

@end
@implementation QRCodeScannerView


static NSArray *defaultCodeType = nil;
static NSDictionary *typeInt2StringMap = nil;
static NSDictionary *typeString2IntMap = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultCodeType = @[AVMetadataObjectTypeEAN13Code,
//                            AVMetadataObjectTypeEAN8Code,
//                            AVMetadataObjectTypeCode128Code,
                            AVMetadataObjectTypeQRCode];
        
        typeInt2StringMap = @{
            @(ZBWCodeType_QRCode) : AVMetadataObjectTypeQRCode,
            @(ZBWCodeType_EAN13) : AVMetadataObjectTypeEAN13Code
        };
        typeString2IntMap = @{
            AVMetadataObjectTypeQRCode : @(ZBWCodeType_QRCode),
            AVMetadataObjectTypeEAN13Code : @(ZBWCodeType_EAN13)
        };
    });
}

#pragma mark- 类型转换
+ (NSString *)typeToAVMetadataObjectType:(ZBWCodeType)type {
    return typeInt2StringMap[@(type)];
}

+ (ZBWCodeType)typeToZBWType:(NSString *)str {
    if (str.length == 0) {
        return ZBWCodeType_Unkonwn;
    }
    return [(NSNumber *)typeString2IntMap[str] integerValue];
}

+ (ZBWCodeType)zxingTypeToZBWType:(ZXBarcodeFormat)type {
    if (type == kBarcodeFormatQRCode) {
        return ZBWCodeType_QRCode;
    }
    if (type == kBarcodeFormatEan13) {
        return ZBWCodeType_EAN13;
    }
    
    return ZBWCodeType_Unkonwn;
}

#pragma mark- Public

+ (instancetype)scannerViewWithDelegate:(id<QRCodeScannerInterfaceDelegate,
                                         QRCodeScannerDeviceExceptionDelegate>)delegate
                   photoPickerShowBlock:(void (^)(UIImagePickerController *))showBlock
                photoPickerdismissBlock:(void (^)(UIImagePickerController *))dismissBlock
                                 result:(void (^)(NSString *, ZBWCodeType type, BOOL isFromPhoto))resultBlock
{
    return [QRCodeScannerView scannerViewWithDelegate:delegate
                                                 type:ZBWCodeType_QRCode|ZBWCodeType_EAN13
                                 photoPickerShowBlock:showBlock
                              photoPickerdismissBlock:dismissBlock
                                               result:resultBlock];
}

+ (instancetype)scannerViewWithDelegate:(id<QRCodeScannerInterfaceDelegate,QRCodeScannerDeviceExceptionDelegate>)delegate
                                   type:(ZBWCodeType)type
                   photoPickerShowBlock:(void (^)(UIImagePickerController *))showBlock
                photoPickerdismissBlock:(void (^)(UIImagePickerController *))dismissBlock
                                 result:(void (^)(NSString *, ZBWCodeType, BOOL))resultBlock {
    QRCodeScannerView *scannerView = [[QRCodeScannerView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    scannerView.codeType = type;
    if (type == ZBWCodeType_Unkonwn) {
        scannerView.codeTypes = defaultCodeType;
    } else {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
        if (type & ZBWCodeType_QRCode) {
            [array addObject:AVMetadataObjectTypeQRCode];
        }
        if (type & ZBWCodeType_EAN13) {
            [array addObject:AVMetadataObjectTypeEAN13Code];
        }
        scannerView.codeTypes = array;
    }
    
    scannerView.delegate = delegate;
    scannerView.photoPickerShowBlock = showBlock;
    scannerView.photoPickerDismissBlock = dismissBlock;
    scannerView.scanResultBlock = resultBlock;
    
    return scannerView;
}

- (void)setPhotoPickerShowBlock:(void (^)(UIImagePickerController *))showBlock
                   dismissBlock:(void (^)(UIImagePickerController *))dismissBlock
                         result:(void (^)(NSString *, ZBWCodeType type, BOOL isFromPhoto))resultBlock
{
    self.photoPickerShowBlock = showBlock;
    self.photoPickerDismissBlock = dismissBlock;
    self.scanResultBlock = resultBlock;
}

- (void)startScanner
{
    if (!_session) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.queue, ^{
        if (weakSelf.session.running) {
            return;
        }
        [weakSelf.session startRunning];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.scannerMaskView startScannerAnimation];
            [weakSelf startTimer];
        });
    });
}

- (void)startScannerDelay:(float)delayTime
{
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf startScanner];
    });
}

- (void)pauseScanner
{
    if (!_session) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.queue, ^{
        if (!weakSelf.session.running) {
            return;
        }
        [weakSelf.session stopRunning];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.scannerMaskView pauseScannerAnimation];
            [weakSelf stopTimer];
        });
    });
}

- (CGRect)scannerRect
{
    CGRect rect = self.bounds;
    return CGRectMake(rect.size.width / 2 - _scanAreaSize.width / 2,
                      rect.size.height / 2 - _scanAreaSize.height / 2 + self.offsetY,
                      _scanAreaSize.width,_scanAreaSize.height);;
}


- (void)autoFocusAtPoint {
    [self focusAtPoint:CGPointMake(self.preview.bounds.size.width/2, self.preview.bounds.size.height/2)];
}

- (void)focusAtPoint:(CGPoint)point{
    CGSize size = self.preview.bounds.size;
    CGPoint focusPoint = CGPointMake(point.x/size.width , point.y /size.height);
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.device setFocusPointOfInterest:focusPoint];
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        [self.device unlockForConfiguration];
    }
}

- (void)startTimer {
    if (!_focusTimer) {
        _focusTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(autoFocusAtPoint) userInfo:nil repeats:YES];
        [_focusTimer fire];
    }
}

- (void)stopTimer {
    if (_focusTimer && [_focusTimer isValid]) {
        [_focusTimer invalidate];
    }
    _focusTimer = NULL;
}

#pragma mark- Override
- (instancetype)init
{
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        [self initData];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame: frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self initData];
    }
    
    return self;
}

- (void)dealloc
{
    [self clearAVCapture];
//    NSLog(@"释放 QRCodeScannerView %p", self);
}


- (void)drawRect:(CGRect)rect {
    self.clearDrawRect = CGRectMake(rect.size.width / 2 - _scanAreaSize.width / 2,
                                    rect.size.height / 2 - _scanAreaSize.height / 2 + self.offsetY,
                                    _scanAreaSize.width,_scanAreaSize.height);
    [self initSubviews];
}

#pragma mark- Private

- (void)initData
{
    self.backgroundColor = [UIColor blackColor];
    _scanAreaSize = CGSizeMake(260, 260);
    _cornerLineColor = QRCodeScannerView_DefaultColor;
    _indicatorLineColor = QRCodeScannerView_DefaultColor;
}

- (void)initSubviews
{
    [self addSubview:self.scannerMaskView];
    
    [self addSubview:self.tipStrLable];
    if (self.delegate && [self.delegate respondsToSelector:@selector(scannerView:interfaceSetupForTipStrLabel:)]) {
        [self.delegate scannerView:self interfaceSetupForTipStrLabel:self.tipStrLable];
    }
    
    [self addSubview:self.photoBtn];
    if (self.delegate && [self.delegate respondsToSelector:@selector(scannerView:interfaceSetupForPhotoBtn:)]) {
        [self.delegate scannerView:self interfaceSetupForPhotoBtn:self.photoBtn];
    }
    
    [self addSubview:self.lightBtn];
    if (self.delegate && [self.delegate respondsToSelector:@selector(scannerView:interfaceSetupForLightBtn:)]) {
        [self.delegate scannerView:self interfaceSetupForLightBtn:self.lightBtn];
    }
    
#if TARGET_IPHONE_SIMULATOR
    return;
#else
    [self updateLightBtn];
    
    [self checkCaptureAuthorization];
#endif
}

- (UIViewController *)viewController
{
    UIResponder *nextResponder = self.nextResponder;
    while (nextResponder) {
        if (nextResponder && [nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        } else {
            nextResponder = nextResponder.nextResponder;
        }
    }
    
    return nil;
}

// 检查相机权限
- (void)checkCaptureAuthorization
{
    __weak typeof (self) weakSelf = self;
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authorizationStatus) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler: ^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        [weakSelf initAVCapture];
                    } else {
                        [weakSelf authorizationStatusDenied];
                    }
                });
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            [weakSelf initAVCapture];
            break;
        }
        case AVAuthorizationStatusRestricted:
        case AVAuthorizationStatusDenied: {
            [self authorizationStatusDenied];
            break;
        }
        default: {
            break;
        }
    }
}

- (void)initAVCapture
{
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:nil];
    
    if (!_input) {
        [self cameraError];
        return;
    }
    
    _output = [[AVCaptureMetadataOutput alloc]init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    /**
     *设置聚焦区域
     CGSize size = parentView.bounds.size;
     CGRect cropRect = CGRectMake((size.width - _transparentAreaSize.width)/2, (size.height - _transparentAreaSize.height)/2, _transparentAreaSize.width, _transparentAreaSize.height);
     _output.rectOfInterest = CGRectMake(cropRect.origin.y/size.width,
     cropRect.origin.x/size.height,
     cropRect.size.height/size.height,
     cropRect.size.width/size.width);
     */
    
    // Session
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetPhoto];
    if ([_session canAddInput:_input])
    {
        [_session addInput:_input];
    }
    
    if ([_session canAddOutput:_output])
    {
        [_session addOutput:_output];
    }
    
    // 条码类型 AVMetadataObjectTypeQRCode
    //_output.metadataObjectTypes =@[AVMetadataObjectTypeQRCode];
    
    //增加条形码扫描
    _output.metadataObjectTypes = self.codeTypes;
    
    // Preview
    _preview =[AVCaptureVideoPreviewLayer layerWithSession:_session];
    _preview.videoGravity =AVLayerVideoGravityResizeAspectFill;
    [_preview setFrame:self.bounds];
    [self.layer insertSublayer:_preview atIndex:0];
    
    [_session startRunning];
    [self startTimer];
}

- (void)clearAVCapture
{
    [_session stopRunning];
    _session = nil;
}

- (void)updateLightBtn
{
#if TARGET_IPHONE_SIMULATOR
    return;
#else
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device.hasTorch) {
        [self.lightBtn setSelected: (device.torchMode == AVCaptureTorchModeOff)];
    } else {
        _lightBtn.hidden = YES;
    }
#endif
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *resultStr = nil;
    NSString *type = nil;
    //设置界面显示扫描结果
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        resultStr = obj.stringValue;
        type = obj.type;
    }
    
    if (!resultStr) {
        return;
    }
    [self pauseScanner];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.scanResultBlock ? weakSelf.scanResultBlock(resultStr, [QRCodeScannerView typeToZBWType:type], NO) : nil;
    });
}


#pragma mark- Event 事件

- (void)onPhotoBtnClicked:(UIButton *)sender
{
    UIImagePickerController *photoPicker = [[UIImagePickerController alloc] init];
    photoPicker.delegate = self;
    photoPicker.allowsEditing = YES;
    photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    photoPicker.view.backgroundColor = [UIColor whiteColor];
    
    self.photoPickerShowBlock ? self.photoPickerShowBlock(photoPicker) : [[self viewController] presentViewController:photoPicker animated:YES completion:nil];
    [self pauseScanner];
}

- (void)torchSwitch:(id)sender {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    if (device.hasTorch) {  // 判断设备是否有闪光灯
        BOOL b = [device lockForConfiguration:&error];
        if (!b) {
            if (error) {
//                NSLog(@"lock torch configuration error:%@", error.localizedDescription);
            }
            return;
        }
        device.torchMode =
        (device.torchMode == AVCaptureTorchModeOff ? AVCaptureTorchModeOn : AVCaptureTorchModeOff);
        [device unlockForConfiguration];
    }
    
    [self updateLightBtn];
}

#pragma mark - UIImagePickerControllerDelegate 相册

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.photoPickerDismissBlock ? self.photoPickerDismissBlock(picker) : [[self viewController] dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *srcImage = [info objectForKey:UIImagePickerControllerEditedImage];
    
    NSMutableArray *types = [NSMutableArray arrayWithCapacity:3];
    if (self.codeType != ZBWCodeType_Unkonwn) {
        if (self.codeType & ZBWCodeType_QRCode) {
            [types addObject:@(kBarcodeFormatQRCode)];
        }
        if (self.codeType & ZBWCodeType_EAN13) {
            [types addObject:@(kBarcodeFormatEan13)];
        }
    }
    ZXBarcodeFormat resultType;
    NSString *result = [QRCodeScannerUtility scQRReaderForImage:srcImage types:types resultType:&resultType];
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.scanResultBlock ? weakSelf.scanResultBlock(result, [QRCodeScannerView zxingTypeToZBWType:resultType] ,YES) : nil;
        });
    });
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    self.photoPickerDismissBlock ? self.photoPickerDismissBlock(picker) : [[self viewController] dismissViewControllerAnimated:YES completion:nil];
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.scanResultBlock ? weakSelf.scanResultBlock(nil, ZBWCodeType_Unkonwn, YES) : nil;
        });
    });
}

#pragma mark- 异常处理
- (void)authorizationStatusDenied
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(scannerView:authorizationStatusDenied:)]) {
        [self.delegate scannerView:self authorizationStatusDenied:@"没有相机权限"];
    } else {
        if (NSClassFromString(@"UIAlertController")) {
            if (![self viewController]) {
                return;
            }
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"获取相机权限失败" message:@"请到“设置”中开启相机权限" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:okAction];
            [[self viewController] presentViewController:alert animated:YES completion:nil];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"获取相机权限失败" message:@"请到“设置”中开启相机权限" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles: nil];
            [alert show];
#pragma clang diagnostic pop
        }
    }
}

- (void)cameraError
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(scannerView:cameraError:)]) {
        [self.delegate scannerView:self cameraError:@"摄像头初始化失败"];
    } else {
        if (NSClassFromString(@"UIAlertController")) {
            if (![self viewController]) {
                return;
            }
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"摄像头初始化失败" message:@"请检查您的设置" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:okAction];
            [[self viewController] presentViewController:alert animated:YES completion:nil];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"摄像头初始化失败" message:@"请检查您的设置" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
            [alert show];
#pragma clang diagnostic pop
        }
    }
}

#pragma mark - setter and getter

- (UIView *)scannerMaskView
{
    if (!_scannerMaskView) {
        _scannerMaskView = [[QRCScannerMaskView alloc] initWithFrame:self.bounds];
        _scannerMaskView.backgroundColor = [UIColor clearColor];
        _scannerMaskView.scannerRect = self.clearDrawRect;
        _scannerMaskView.cornerLineColor = self.cornerLineColor ? : QRCodeScannerView_DefaultColor;
        _scannerMaskView.lineType = self.lineType;
        _scannerMaskView.indicatorImage = self.indicatorImage;
        _scannerMaskView.indicatorLineColor = self.indicatorLineColor;
    }
    return _scannerMaskView;
}

- (UILabel *)tipStrLable
{
    if (!_tipStrLable) {
        CGSize size = self.bounds.size;
        _tipStrLable = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                 size.height/2 + _scanAreaSize.height / 2 + self.offsetY + QRCodeScannerView_V_Space,
                                                                 size.width,
                                                                 20)];
        [_tipStrLable setText: self.tipStr ? : @"请将二维码图案放置在取景框内"];
        _tipStrLable.font = [UIFont systemFontOfSize:13];
        [_tipStrLable setTextColor:[UIColor colorWithWhite:150/255.0 alpha:1.0]];
        _tipStrLable.textAlignment = NSTextAlignmentCenter;
    }
    return _tipStrLable;
}

- (UIButton *)photoBtn
{
    if (!_photoBtn) {
        _photoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = imageInQRCodeScannerBundle(@"scan_local_photo_button@2x");
        [_photoBtn setImage:image forState:UIControlStateNormal];
        [_photoBtn addTarget:self action:@selector(onPhotoBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        CGSize size = image.size;
        _photoBtn.frame = CGRectMake((CGRectGetWidth(self.bounds) - size.width) / 2,
                                     CGRectGetMaxY(self.tipStrLable.frame) + QRCodeScannerView_V_Space,
                                     size.width,
                                     size.height);
    }
    return _photoBtn;
}

- (UIButton *)lightBtn
{
    if (!_lightBtn) {
        _lightBtn = [[UIButton alloc] init];
        [_lightBtn addTarget:self action:@selector(torchSwitch:) forControlEvents:UIControlEventTouchUpInside];
        
        UIImage *image = imageInQRCodeScannerBundle(@"scan_flash_on@2x");
        [_lightBtn setImage:image forState:UIControlStateSelected];
        image = imageInQRCodeScannerBundle(@"scan_flash_off@2x");
        [_lightBtn setImage:image forState:UIControlStateNormal];
        [_lightBtn setSelected:NO];
        
        CGSize size = image.size;
        _lightBtn.frame = CGRectMake(CGRectGetWidth(self.bounds) - size.width - QRCodeScannerView_H_Space,
                                     QRCodeScannerView_V_Space + 100 + self.offsetY,
                                     size.width,
                                     size.height);
    }
    return _lightBtn;
}

- (dispatch_queue_t)queue
{
    if (!_queue) {
        _queue = dispatch_queue_create("com.taofen8.codeScanner.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _queue;
}

@end
