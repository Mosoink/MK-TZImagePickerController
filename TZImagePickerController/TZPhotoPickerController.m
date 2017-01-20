//
//  TZPhotoPickerController.m
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import "TZPhotoPickerController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "TZImagePickerController.h"
#import "TZPhotoPreviewController.h"
#import "TZAssetCell.h"
#import "TZAssetModel.h"
#import "UIView+Layout.h"
#import "TZImageManager.h"
#import "TZVideoPlayerController.h"
#import "TZLoadingLabel.h"

static CGFloat margin = 4;
@interface TZPhotoPickerController ()<UICollectionViewDataSource,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout> {
    UICollectionView *_collectionView;
    NSMutableArray *_photoArr;
    
    UIButton *_previewButton;
    UIButton *_okButton;
    UIImageView *_numberImageView;
    UILabel *_numberLable;
    UIButton *_originalPhotoButton;
    TZLoadingLabel *_originalPhotoLable;
    
    BOOL _isSelectOriginalPhoto;
    BOOL _shouldScrollToBottom;
    
    BOOL _willRotate;
    UIView *_bottomToolBar;
    UIView *_divide;
}
@property (nonatomic, strong) NSMutableArray *selectedPhotoArr;
@property CGRect previousPreheatRect;
@end

static CGSize AssetGridThumbnailSize;

@implementation TZPhotoPickerController

- (NSMutableArray *)selectedPhotoArr {
    if (_selectedPhotoArr == nil) _selectedPhotoArr = [NSMutableArray array];
    return _selectedPhotoArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _shouldScrollToBottom = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = _model.name;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    [[TZImageManager manager] getAssetsFromFetchResult:_model.result allowPickingVideo:imagePickerVc.allowPickingVideo completion:^(NSArray<TZAssetModel *> *models) {
        _photoArr = [NSMutableArray arrayWithArray:models];
        [self configCollectionView];
        [self configBottomToolBar];
    }];
    [self resetCachedAssets];
}

- (void)configCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat itemWH = (SCREEN_PW - 2 * margin - 4) / 4 - margin;
    layout.itemSize = CGSizeMake(itemWH, itemWH);
    layout.minimumInteritemSpacing = margin;
    layout.minimumLineSpacing = margin;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.alwaysBounceHorizontal = NO;
    if (iOS7Later) _collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 2);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, -2);
    [self.view addSubview:_collectionView];
    [_collectionView registerNib:[UINib nibWithNibName:@"TZAssetCell" bundle:nil] forCellWithReuseIdentifier:@"TZAssetCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    if (_shouldScrollToBottom && _photoArr.count > 0) {
//        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:(_photoArr.count - 1) inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
//        _shouldScrollToBottom = NO;
//    }
    // Determine the size of the thumbnails to request from the PHCachingImageManager
//    CGFloat scale = [UIScreen mainScreen].scale;
//    CGSize cellSize = ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).itemSize;
//    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (iOS8Later) {
        // [self updateCachedAssets];
    }
}

- (void)configBottomToolBar {
    _bottomToolBar = [[UIView alloc] initWithFrame:CGRectZero];
    CGFloat rgb = 253 / 255.0;
    _bottomToolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
    
    _previewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _previewButton.frame = CGRectMake(0, 0, 52, 49);
    [_previewButton addTarget:self action:@selector(previewButtonClick) forControlEvents:UIControlEventTouchUpInside];
    _previewButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_previewButton setTitle:@"预览" forState:UIControlStateNormal];
    [_previewButton setTitle:@"预览" forState:UIControlStateDisabled];
    [_previewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_previewButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    _previewButton.backgroundColor = [UIColor clearColor];
    _previewButton.enabled = NO;
    
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    if (imagePickerVc.allowPickingOriginalPhoto) {
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, -15, 0, 0);
        _originalPhotoButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_originalPhotoButton setTitle:@"原图" forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:@"原图" forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        [_originalPhotoButton setImage:[UIImage imageNamed:@"photo_original_def"] forState:UIControlStateNormal];
        [_originalPhotoButton setImage:[UIImage imageNamed:@"photo_original_sel"] forState:UIControlStateSelected];
        _originalPhotoButton.backgroundColor = [UIColor clearColor];
        _originalPhotoButton.enabled = _selectedPhotoArr.count > 0;
        
        _originalPhotoLable = [[TZLoadingLabel alloc] init];
        _originalPhotoLable.frame = CGRectMake(65, 0, 75, 49);
        _originalPhotoLable.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLable.font = [UIFont systemFontOfSize:16];
        _originalPhotoLable.textColor = [UIColor blackColor];
        if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
    }
    
    _okButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _okButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_okButton addTarget:self action:@selector(okButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_okButton setTitle:@"确定" forState:UIControlStateNormal];
    [_okButton setTitle:@"确定" forState:UIControlStateDisabled];
    [_okButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -15)];
    [_okButton setTitleColor:imagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
    [_okButton setTitleColor:imagePickerVc.oKButtonTitleColorDisabled forState:UIControlStateDisabled];
    _okButton.backgroundColor = [UIColor clearColor];
    _okButton.enabled = NO;
    
    _numberImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photo_number_icon"]];
    _numberImageView.hidden = _selectedPhotoArr.count <= 0;
    _numberImageView.backgroundColor = [UIColor clearColor];
    
    _numberLable = [[UILabel alloc] init];
    _numberLable.font = [UIFont systemFontOfSize:16];
    _numberLable.textColor = [UIColor whiteColor];
    _numberLable.textAlignment = NSTextAlignmentCenter;
    _numberLable.text = [NSString stringWithFormat:@"%zd",_selectedPhotoArr.count];
    _numberLable.hidden = _selectedPhotoArr.count <= 0;
    _numberLable.backgroundColor = [UIColor clearColor];
    
    _divide = [[UIView alloc] init];
    CGFloat rgb2 = 222 / 255.0;
    _divide.backgroundColor = [UIColor colorWithRed:rgb2 green:rgb2 blue:rgb2 alpha:1.0];

    [_bottomToolBar addSubview:_divide];
    [_bottomToolBar addSubview:_previewButton];
    [_bottomToolBar addSubview:_okButton];
    [_bottomToolBar addSubview:_numberImageView];
    [_bottomToolBar addSubview:_numberLable];
    [self.view addSubview:_bottomToolBar];
    [self.view addSubview:_originalPhotoButton];
    [_originalPhotoButton addSubview:_originalPhotoLable];
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    
    CGFloat top = margin + 44;
    if (iOS7Later) top += 20;
    _collectionView.frame = CGRectMake(margin, top, self.view.tz_width - 2 * margin, self.view.tz_height - 50 - top);
    _collectionView.contentSize = CGSizeMake(self.view.tz_width, ((_model.count + 3) / 4) * self.view.tz_width);
    _bottomToolBar.frame        = CGRectMake(0, self.view.tz_height - 49, self.view.tz_width, 49);
    _originalPhotoButton.frame  = CGRectMake(62, self.view.tz_height - 49, 67, 49);
    _okButton.frame             = CGRectMake(self.view.tz_width - 68, 0, 68, 49);
    _numberImageView.frame      = CGRectMake(self.view.tz_width - 42 - 26, 11.5, 26, 26);
    _numberLable.frame          = _numberImageView.frame;
    _divide.frame               = CGRectMake(0, 0, self.view.tz_width, 1);
    if (_shouldScrollToBottom && _photoArr.count > 0) {
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:(_photoArr.count - 1) inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        _shouldScrollToBottom = NO;
    }
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize cellSize = ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).itemSize;
    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
}

- (BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Click Event

- (void)cancel {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
        [imagePickerVc.pickerDelegate tz_imagePickerControllerDidCancel:imagePickerVc];
    }
    if (imagePickerVc.imagePickerControllerDidCancelHandle) {
        imagePickerVc.imagePickerControllerDidCancelHandle();
    }
}

- (void)previewButtonClick {
    TZPhotoPreviewController *photoPreviewVc = [[TZPhotoPreviewController alloc] init];
    photoPreviewVc.photoArr = [NSArray arrayWithArray:self.selectedPhotoArr];
    [self pushPhotoPrevireViewController:photoPreviewVc];
}

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _isSelectOriginalPhoto = _originalPhotoButton.isSelected;
    _originalPhotoLable.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
}

- (void)okButtonClick {
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    [imagePickerVc showProgressHUD];
    [TZImageManager manager].shouldFixOrientation = YES;
    
    
//    NSMutableArray *assets = [NSMutableArray array];
//    NSMutableArray *photos = [NSMutableArray array];
//    for (NSInteger i = 0; i < _selectedPhotoArr.count; i++) {
//        TZAssetModel *model = _selectedPhotoArr[i];
//        [assets addObject:model.asset];
//        
//        ALAsset *alAsset = (ALAsset *)model.asset;
//        CGImageRef thumbnailImageRef = alAsset.aspectRatioThumbnail;
//        UIImage *thumbnailImage = [UIImage imageWithCGImage:thumbnailImageRef scale:1.0 orientation:UIImageOrientationUp];
//        [photos addObject:thumbnailImage];
//    }
//    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(tz_imagePickerController:didFinishPickingPhotos:sourceAssets:)]) {
//        [imagePickerVc.pickerDelegate tz_imagePickerController:imagePickerVc didFinishPickingPhotos:photos sourceAssets:assets];
//    }
//    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(tz_imagePickerController:didFinishPickingPhotos:sourceAssets:infos:)]) {
//        [imagePickerVc.pickerDelegate tz_imagePickerController:imagePickerVc didFinishPickingPhotos:photos sourceAssets:assets infos:nil];
//    }
//    if (imagePickerVc.didFinishPickingPhotosHandle) {
//        imagePickerVc.didFinishPickingPhotosHandle(photos,assets);
//    }
//    if (imagePickerVc.didFinishPickingPhotosWithInfosHandle) {
//        imagePickerVc.didFinishPickingPhotosWithInfosHandle(photos,assets,nil);
//    }
//    [imagePickerVc hideProgressHUD];
//    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    //*
    
    for (NSInteger i = 0; i < _selectedPhotoArr.count; i++) {
        TZAssetModel *model = _selectedPhotoArr[i];
        model.isOriginal = _isSelectOriginalPhoto;
    }
    
    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(tz_imagePickerController:didFinishPickingAssets:)]) {
        [imagePickerVc.pickerDelegate tz_imagePickerController:imagePickerVc didFinishPickingAssets:_selectedPhotoArr];
    }
    
    if (imagePickerVc.didFinishPickingPhotosHandle) {
        imagePickerVc.didFinishPickingPhotosHandle(nil, _selectedPhotoArr);
    }
    if (imagePickerVc.didFinishPickingPhotosWithInfosHandle) {
        imagePickerVc.didFinishPickingPhotosWithInfosHandle(nil, _selectedPhotoArr, nil);
    }
    [imagePickerVc hideProgressHUD];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
     //*/
}

#pragma mark - UICollectionViewDataSource && Delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photoArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TZAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZAssetCell" forIndexPath:indexPath];
    TZAssetModel *model = _photoArr[indexPath.row];
    cell.model = model;
    
    __weak typeof(cell) weakCell = cell;
    __weak typeof(self) weakSelf = self;
    __weak typeof(_numberImageView.layer) weakLayer = _numberImageView.layer;
    cell.didSelectPhotoBlock = ^(BOOL isSelected) {
        // 1. cancel select / 取消选择
        if (isSelected) {
            weakCell.selectPhotoButton.selected = NO;
            model.isSelected = NO;
            [weakSelf.selectedPhotoArr removeObject:model];
            [weakSelf refreshBottomToolBarStatus];
        } else {
            // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
            TZImagePickerController *imagePickerVc = (TZImagePickerController *)weakSelf.navigationController;
            if (weakSelf.selectedPhotoArr.count < imagePickerVc.maxImagesCount) {
                weakCell.selectPhotoButton.selected = YES;
                model.isSelected = YES;
                [weakSelf.selectedPhotoArr addObject:model];
                [weakSelf refreshBottomToolBarStatus];
            } else {
                if(imagePickerVc.maxImagesCount == 1)
                {
                    TZAssetModel *lastModel = (TZAssetModel *)[weakSelf.selectedPhotoArr firstObject];
                    NSInteger lastIndex = (NSInteger)[_photoArr indexOfObject:lastModel];
                    TZAssetCell *lastCell = (TZAssetCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:lastIndex inSection:0]];
                    lastModel.isSelected = NO;
                    lastCell.model = lastModel;
                    [weakSelf.selectedPhotoArr removeObject:lastModel];
                    
                    weakCell.selectPhotoButton.selected = YES;
                    model.isSelected = YES;
                    [weakSelf.selectedPhotoArr addObject:model];
                    [weakSelf refreshBottomToolBarStatus];
                }
                else
                {
                    [imagePickerVc showAlertWithTitle:[NSString stringWithFormat:@"你最多只能选择%zd张照片",imagePickerVc.maxImagesCount]];
                }
            }
        }
         [UIView showOscillatoryAnimationWithLayer:weakLayer type:TZOscillatoryAnimationToSmaller];
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    TZAssetModel *model = _photoArr[indexPath.row];
    if (model.type == TZAssetModelMediaTypeVideo) {
        if (_selectedPhotoArr.count > 0) {
            TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
            [imagePickerVc showAlertWithTitle:@"选择照片时不能选择视频"];
        } else {
            TZVideoPlayerController *videoPlayerVc = [[TZVideoPlayerController alloc] init];
            videoPlayerVc.model = model;
            [self.navigationController pushViewController:videoPlayerVc animated:YES];
        }
    } else {
        TZPhotoPreviewController *photoPreviewVc = [[TZPhotoPreviewController alloc] init];
        photoPreviewVc.photoArr = _photoArr;
        photoPreviewVc.currentIndex = indexPath.row;
        [self pushPhotoPrevireViewController:photoPreviewVc];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (iOS8Later) {
        // [self updateCachedAssets];
    }
}

#pragma mark - Private Method

- (void)refreshBottomToolBarStatus {
    _previewButton.enabled = self.selectedPhotoArr.count > 0;
    _okButton.enabled = self.selectedPhotoArr.count > 0;
    
    _numberImageView.hidden = _selectedPhotoArr.count <= 0;
    _numberLable.hidden = _selectedPhotoArr.count <= 0;
    _numberLable.text = [NSString stringWithFormat:@"%zd",_selectedPhotoArr.count];
    
    _originalPhotoButton.enabled = _selectedPhotoArr.count > 0;
    _originalPhotoButton.selected = (_isSelectOriginalPhoto && _originalPhotoButton.enabled);
    _originalPhotoLable.hidden = (!_originalPhotoButton.isSelected);
    if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
}

- (void)pushPhotoPrevireViewController:(TZPhotoPreviewController *)photoPreviewVc {
    photoPreviewVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
    photoPreviewVc.selectedPhotoArr = self.selectedPhotoArr;
    photoPreviewVc.returnNewSelectedPhotoArrBlock = ^(NSMutableArray *newSelectedPhotoArr,BOOL isSelectOriginalPhoto) {
        _selectedPhotoArr = newSelectedPhotoArr;
        _isSelectOriginalPhoto = isSelectOriginalPhoto;
        [_collectionView reloadData];
        [self refreshBottomToolBarStatus];
    };
    photoPreviewVc.okButtonClickBlock = ^(NSMutableArray *newSelectedPhotoArr,BOOL isSelectOriginalPhoto){
        _selectedPhotoArr = newSelectedPhotoArr;
        _isSelectOriginalPhoto = isSelectOriginalPhoto;
        [self okButtonClick];
    };
    [self.navigationController pushViewController:photoPreviewVc animated:YES];
}

- (void)getSelectedPhotoBytes {
    _originalPhotoLable.loading = YES;
    [[TZImageManager manager] getPhotosBytesWithArray:_selectedPhotoArr completion:^(NSString *totalBytes) {
        _originalPhotoLable.loading = NO;
        _originalPhotoLable.text = [NSString stringWithFormat:@"(%@)",totalBytes];
    }];
}

#pragma mark - Asset Caching

- (void)resetCachedAssets {
    [[TZImageManager manager].cachingImageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect.
    CGRect preheatRect = _collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    /*
     Check if the collection view is showing an area that is significantly
     different to the last preheated area.
     */
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(_collectionView.bounds) / 3.0f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self aapl_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self aapl_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        // Update the assets the PHCachingImageManager is caching.
        [[TZImageManager manager].cachingImageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:AssetGridThumbnailSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:nil];
        [[TZImageManager manager].cachingImageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:AssetGridThumbnailSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:nil];
        
        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        TZAssetModel *model = _photoArr[indexPath.item];
        [assets addObject:model.asset];
    }
    
    return assets;
}

- (NSArray *)aapl_indexPathsForElementsInRect:(CGRect)rect {
    NSArray *allLayoutAttributes = [_collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

@end
