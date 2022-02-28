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
#import "UIImage+MDQRCode.h"

@implementation QRCodeScannerUtility

+ (UIImage *)scQRCodeForString:(NSString *)qrString
                          size:(CGFloat)size
{
    return [UIImage mdQRCodeForString:qrString size:size];
}

+ (UIImage *)scQRCodeForString:(NSString *)qrString
                          size:(CGFloat)size
                     fillColor:(UIColor *)fillColor
{
    return [UIImage mdQRCodeForString:qrString size:size fillColor:fillColor];
}

+ (UIImage *)scQRCodeForString:(NSString *)qrString
                          size:(CGFloat)size
                     fillColor:(UIColor *)fillColor
                      subImage:(UIImage *)subImage
{
    UIImage *qrImage = [UIImage mdQRCodeForString:qrString size:size fillColor:fillColor];
    return [self addSubImage:qrImage sub:subImage];
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
