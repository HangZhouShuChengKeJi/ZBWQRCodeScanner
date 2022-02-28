//
//  QRCodeScannerUtility.m
//  QRScannerDemo
//
//  Created by 朱博文 on 16/6/17.
//  Copyright © 2016年 zhangfei. All rights reserved.
//

#import "QRCodeScannerUtility.h"
#import <ZXingObjC/ZXingObjC.h>
#import <AVFoundation/AVFoundation.h>

@implementation QRCodeScannerUtility

+ (UIImage *)scQRCodeForString:(NSString *)qrString
                          size:(CGFloat)size
{
    return [self createQRCodeWithTargetString:qrString logoImage:NULL];
}

+ (UIImage *)scQRCodeForString:(NSString *)qrString
                          size:(CGFloat)size
                     fillColor:(UIColor *)fillColor
{
    return [self createQRCodeWithTargetString:qrString logoImage:NULL];
}

+ (UIImage *)scQRCodeForString:(NSString *)qrString
                          size:(CGFloat)size
                     fillColor:(UIColor *)fillColor
                      subImage:(UIImage *)subImage
{
    UIImage *qrImage = [self createQRCodeWithTargetString:qrString logoImage:subImage];
    return [self addSubImage:qrImage sub:subImage];
}

+(UIImage *)createQRCodeWithTargetString:(NSString *)targetString logoImage:(UIImage *)logoImage {
    // 1.创建一个二维码滤镜实例
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    
    // 2.给滤镜添加数据
    NSString *targetStr = targetString;
    NSData *targetData = [targetStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    [filter setValue:targetData forKey:@"inputMessage"];
    
    // 3.生成二维码
    CIImage *image = [filter outputImage];
    
    // 4.高清处理: size 要大于等于视图显示的尺寸
    UIImage *img = [self createNonInterpolatedUIImageFromCIImage:image size:[UIScreen mainScreen].bounds.size.width];
    
    //5.嵌入LOGO
    //5.1开启图形上下文
    UIGraphicsBeginImageContext(img.size);
    //5.2将二维码的LOGO画入
    [img drawInRect:CGRectMake(0, 0, img.size.width, img.size.height)];
    
    UIImage *centerImg = logoImage;
    CGFloat centerW=img.size.width*0.25;
    CGFloat centerH=centerW;
    CGFloat centerX=(img.size.width-centerW)*0.5;
    CGFloat centerY=(img.size.height -centerH)*0.5;
    [centerImg drawInRect:CGRectMake(centerX, centerY, centerW, centerH)];
    //5.3获取绘制好的图片
    UIImage *finalImg=UIGraphicsGetImageFromCurrentImageContext();
    //5.4关闭图像上下文
    UIGraphicsEndImageContext();

    //6.生成最终二维码
    return finalImg;
}

+ (UIImage *)createNonInterpolatedUIImageFromCIImage:(CIImage *)image size:(CGFloat)size {
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap
    size_t width = CGRectGetWidth(extent)*scale;
    size_t height = CGRectGetHeight(extent)*scale;
    
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    //2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    
    return [UIImage imageWithCGImage:scaledImage];
}

+ (NSString *)scQRReaderForImage:(UIImage *)qrimage types:(NSArray *)types resultType:(ZXBarcodeFormat *)resultType
{
    UIImage *loadImage= qrimage;
    CGImageRef imageToDecode = loadImage.CGImage;
    
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:imageToDecode];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    
    NSError *error = nil;
    
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    [types enumerateObjectsUsingBlock:^(NSNumber*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [hints addPossibleFormat:obj.integerValue];
    }];
    
    ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
    
    ZXResult *result = [reader decode:bitmap
                                hints:hints
                                error:&error];
    NSString *contents = result.text;
    if (resultType) {
        *resultType = result.barcodeFormat;
    }
    return contents;
    
//    NSString *result = nil;
//    if ([[UIDevice currentDevice] systemVersion].floatValue > 7.99) {
//        CIContext *context = [CIContext contextWithOptions:nil];
//        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:context options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
//        CIImage *image = [CIImage imageWithCGImage:qrimage.CGImage];
//        NSArray *features = [detector featuresInImage:image];
//        CIQRCodeFeature *feature = [features firstObject];
//        result = feature.messageString;
//    }
//    // System Version below 7.99 or CIDetector failed to find QRCode, we do it with ZXing
//    if (result && result.length > 0) {
//        return result;
//    } else {
//        UIImage *loadImage= qrimage;
//        CGImageRef imageToDecode = loadImage.CGImage;
//
//        ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:imageToDecode];
//        ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
//
//        NSError *error = nil;
//
//        ZXDecodeHints *hints = [ZXDecodeHints hints];
//
//        ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
//        ZXResult *result = [reader decode:bitmap
//                                    hints:hints
//                                    error:&error];
//        NSString *contents = result.text;
//        return contents;
//    }
}

+ (UIImage *)addSubImage:(UIImage *)img sub:(UIImage *) subImage
{
    //get image width and height
    int w = img.size.width;
    int h = img.size.height;
    int subWidth = subImage.size.width;
    int subHeight = subImage.size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //create a graphic context with CGBitmapContextCreate
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);
    CGContextDrawImage(context, CGRectMake( (w-subWidth)/2, (h - subHeight)/2, subWidth, subHeight), [subImage CGImage]);
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return [UIImage imageWithCGImage:imageMasked];
    //  CGContextDrawImage(contextRef, CGRectMake(100, 50, 200, 80), [smallImg CGImage]);
}


@end
