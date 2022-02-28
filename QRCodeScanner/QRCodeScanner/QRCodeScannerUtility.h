//
//  QRCodeScannerUtility.h
//  QRScannerDemo
//
//  Created by 朱博文 on 16/6/17.
//  Copyright © 2016年 zhangfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ZXingObjC/ZXingObjC.h>

/**
 *  字符串转二维码图片； 二维码图片识别
 */
@interface QRCodeScannerUtility : NSObject

+ (UIImage *)scQRCodeForString:(NSString *)qrString
                          size:(CGFloat)size;

+ (UIImage *)scQRCodeForString:(NSString *)qrString
                          size:(CGFloat)size
                     fillColor:(UIColor *)fillColor;

+ (UIImage *)scQRCodeForString:(NSString *)qrString
                          size:(CGFloat)size
                     fillColor:(UIColor *)fillColor
                      subImage:(UIImage *)subImage;

+ (NSString *)scQRReaderForImage:(UIImage *)qrimage types:(NSArray *)types resultType:(ZXBarcodeFormat *)resultType;

@end
