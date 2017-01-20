//
//  TZAssetModel.m
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import "TZAssetModel.h"
#import "MIUtils.h"

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
    MLog(@"1");
    __block UIImage *thumbImage;
    dispatch_semaphore_t sema_done = dispatch_semaphore_create(0);
    [self imageWithType:TZPhotoTypeThumb completion:^(UIImage *image, NSDictionary *info) {
        thumbImage = image;
        MLog(@"2");
        dispatch_semaphore_signal(sema_done);
        MLog(@"3");
    }];
    MLog(@"4");
    // We can't return until the async block has returned.
    // So we wait until it's done. If we wait on the main queue
    // then our UI will be "frozen".
    dispatch_semaphore_wait(sema_done, DISPATCH_TIME_FOREVER);
    MLog(@"5");
    return thumbImage;
}

- (UIImage *)fullImage{
    UIImage *image;
    ALAsset *asset = (ALAsset *)_asset;
    if (_isOriginal) {
        CGImageRef imageRef = [asset.defaultRepresentation fullResolutionImage];
        image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:(UIImageOrientation)asset.defaultRepresentation.orientation];
        image = [image imageFixOrientation];
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