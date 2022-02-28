//
//  QRCodeScannerView.h
//  QRScannerDemo
//
//  Created by 朱博文 on 16/6/17.
//  Copyright © 2016年 zhangfei. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ZBWCodeType) {
    ZBWCodeType_Unkonwn = 0,
    ZBWCodeType_QRCode = 1 << 0,
    ZBWCodeType_EAN13 = 1 << 1
};


@class QRCodeScannerView;

/**
 *  UI配置 delegate
 */
@protocol QRCodeScannerInterfaceDelegate <NSObject>

@optional
// 手电筒。外部可以设置手电筒按钮的样式
- (void)scannerView:(QRCodeScannerView *)scannerView interfaceSetupForLightBtn:(UIButton *)btn;

// 本地相册按钮。外部可以设置。
- (void)scannerView:(QRCodeScannerView *)scannerView interfaceSetupForPhotoBtn:(UIButton *)btn;

// 提示标签。外部可设置。
- (void)scannerView:(QRCodeScannerView *)scannerView interfaceSetupForTipStrLabel:(UILabel *)label;

@end


/**
 *  设备权限异常 delegate
 */
@protocol QRCodeScannerDeviceExceptionDelegate <NSObject>

@optional
// 没有相机访问权限。 如果不实现，内部会使用Alert默认提示
- (void)scannerView:(QRCodeScannerView *)scannerView authorizationStatusDenied:(NSString *)tipStr;

// 摄像头初始化失败，没有摄像头。 如果不实现，内部会使用Alert默认提示
- (void)scannerView:(QRCodeScannerView *)scannerView cameraError:(NSString *)tipStr;

@end


/**
 *  扫描指示器类型
 */
typedef NS_ENUM(NSInteger, QRCScannerIndicatorType) {
    /**
     *  颜色的线
     */
    QRCScannerIndicatorType_Image = 0,
    /**
     *  图片
     */
    QRCScannerIndicatorType_ColorLine
};


@interface QRCodeScannerView : UIView

// 指示器
@property (nonatomic) QRCScannerIndicatorType       lineType;
@property (nonatomic) UIImage                       *indicatorImage;
@property (nonatomic) UIColor                       *indicatorLineColor;

// 扫描区域的偏移量。 默认为0;
@property (nonatomic) CGFloat                       offsetY;

// 扫描区域拐角线的颜色
@property (nonatomic) UIColor                       *cornerLineColor;

// 扫描区域。默认CGSizeMake(260, 260)
@property (nonatomic) CGSize                        scanAreaSize;

// 提示信息。默认@"请将二维码图案放置在取景框内"
@property (nonatomic, copy) NSString                *tipStr;

/**
 *  类构造函数
 *
 *  @param delegate     UI定制、设备异常delegate，可以为nil。
 *  @param showBlock    显示“相册”的block，可以为nil，内部会自动显示。
 *  @param dismissBlock 关闭“相册”的block，可以为nil，内部会自动关闭。
 *  @param resultBlock  结果回调block
 *
 *  @return 实例
 */
+ (instancetype)scannerViewWithDelegate:(id<QRCodeScannerInterfaceDelegate,
                                         QRCodeScannerDeviceExceptionDelegate>)delegate
                   photoPickerShowBlock:(void (^)(UIImagePickerController *viewcontroller))showBlock
                photoPickerdismissBlock:(void (^)(UIImagePickerController *viewcontroller))dismissBlock
                                 result:(void (^)(NSString *resultStr, ZBWCodeType type, BOOL isFromPhoto))resultBlock;

/**
*  类构造函数
*
*  @param delegate     UI定制、设备异常delegate，可以为nil。
*  @param types        扫码类型，nil默认为所有码
*  @param showBlock    显示“相册”的block，可以为nil，内部会自动显示。
*  @param dismissBlock 关闭“相册”的block，可以为nil，内部会自动关闭。
*  @param resultBlock  结果回调block
*
*  @return 实例
*/
+ (instancetype)scannerViewWithDelegate:(id<QRCodeScannerInterfaceDelegate,
                         QRCodeScannerDeviceExceptionDelegate>)delegate
                                   type:(ZBWCodeType)type
                   photoPickerShowBlock:(void (^)(UIImagePickerController *viewcontroller))showBlock
                photoPickerdismissBlock:(void (^)(UIImagePickerController *viewcontroller))dismissBlock
                                 result:(void (^)(NSString *resultStr, ZBWCodeType type, BOOL isFromPhoto))resultBlock;


/**
 *  开始扫描。进入其他页面时，会停止扫描，因此在viewWillAppear中要调用startScanner。
 */
- (void)startScanner;

- (void)startScannerDelay:(float)delayTime;

/**
 *  暂停扫描。离开页面的时候，建议调用。
 */
- (void)pauseScanner;

/**
 *  获取扫描区域
 */
- (CGRect)scannerRect;

@end
