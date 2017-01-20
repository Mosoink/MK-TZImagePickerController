//
//  TZAssetModel.m
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import "TZAssetModel.h"

@interface UIImage (_TZ)

@end

@implementation UIImage (_TZ)

- (instancetype)_tz_imageFixOrientation{
    UIImage *aImage = self;
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

@end




#pragma mark -
@interface TZAssetModel ()

@end
@implementation TZAssetModel


+ (instancetype)modelWithAsset:(id)asset type:(TZAssetModelMediaType)type{
    TZAssetModel *model = [[TZAssetModel alloc] init];
    model.asset = asset;
    model.isSelected = NO;
    model.type = type;
    return model;
}

+ (instancetype)modelWithAsset:(id)asset type:(TZAssetModelMediaType)type timeLength:(NSString *)timeLength {
    TZAssetModel *model = [self modelWithAsset:asset type:type];
    model.timeLength = timeLength;
    return model;
}

- (UIImage *)thumbImage{
    __block UIImage *thumbImage;
    dispatch_semaphore_t sema_done = dispatch_semaphore_create(0);
    [self imageWithType:TZPhotoTypeThumb completion:^(UIImage *image, NSDictionary *info) {
        thumbImage = image;
        dispatch_semaphore_signal(sema_done);
    }];
    // We can't return until the async block has returned.
    // So we wait until it's done. If we wait on the main queue
    // then our UI will be "frozen".
    dispatch_semaphore_wait(sema_done, DISPATCH_TIME_FOREVER);
    return thumbImage;
}

- (UIImage *)fullImage{
    UIImage *image;
    ALAsset *asset = (ALAsset *)_asset;
    if (_isOriginal) {
        CGImageRef imageRef = [asset.defaultRepresentation fullResolutionImage];
        image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:(UIImageOrientation)asset.defaultRepresentation.orientation];
        image = [image _tz_imageFixOrientation];
    }else{
        NSInteger max = 1024;
        CGImageRef imageRef = [asset.defaultRepresentation fullScreenImage];
        image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationUp];
        image = [[TZImageManager manager] scaleImage:image toMaxSize:CGSizeMake(max, max)];
        
//        int h = image.size.height*image.scale;
//        int w = image.size.width*image.scale;
//        if(h > max || w > max)
//        {
//            float b = (float)max/w < (float)max/h ? (float)max/w : (float)max/h;
//            CGSize itemSize = CGSizeMake(b*w*image.scale, b*h*image.scale);
//            UIGraphicsBeginImageContext(itemSize);
//            CGContextRef context = UIGraphicsGetCurrentContext();
//            CGAffineTransform transform = CGAffineTransformIdentity;
//            
//            transform = CGAffineTransformScale(transform, b, b);
//            CGContextConcatCTM(context, transform);
//            
//            // Draw the image into the transformed context and return the image
//            [image drawAtPoint:CGPointMake(0.0f, 0.0f)];
//            UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
//            UIGraphicsEndImageContext();
//            image = newimg;
//        }

    }
    return image;
}


- (void)fullImage:(void (^)(UIImage *image, NSDictionary *info))completion{
    TZPhotoType type = _isOriginal ? TZPhotoTypeOriginal : TZPhotoTypeDefault;
    [self imageWithType:type completion:completion];
}

#pragma mark - Private
- (void)imageWithType:(TZPhotoType)type completion:(void (^)(UIImage *image, NSDictionary *info))completion{
    if (type == TZPhotoTypeOriginal) {
        [[TZImageManager manager] getOriginalPhotoWithAsset:_asset completion:completion];
        return;
    }
    NSInteger photoWidth;
    switch (type) {
        case TZPhotoTypeDefault:
            photoWidth = 1024;
            break;
        case TZPhotoTypeThumb:
            photoWidth = 60;
            break;
        case TZPhotoTypeOriginal:
            break;
            
        default:
            break;
    }
    [[TZImageManager manager] getPhotoWithAsset:_asset photoWidth:photoWidth completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if (completion && !isDegraded) {
            completion(photo, info);
        }
    }];
}

@end


@implementation TZAlbumModel


@end
