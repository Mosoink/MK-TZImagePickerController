//
//  TZLoadingLabel.m
//  MosoTeach
//
//  Created by C on 5/19/16.
//  Copyright © 2016 XiaoLei. All rights reserved.
//

#import "TZLoadingLabel.h"

@interface TZLoadingLabel ()
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@end
@implementation TZLoadingLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _loadingView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
        _loadingView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [self addSubview:_loadingView];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat centerX;
    _loadingView.frame  = CGRectMake(0, 0, self.frame.size.height, self.frame.size.height);
    if (self.textAlignment == NSTextAlignmentLeft) {
        centerX = self.frame.size.height/2.;
    }else if (self.textAlignment == NSTextAlignmentCenter) {
        centerX = self.frame.size.width/2.;
    }else if (self.textAlignment == NSTextAlignmentRight) {
        centerX = self.frame.size.width-self.frame.size.height/2.;
    }
    _loadingView.center = CGPointMake(centerX, _loadingView.center.y);
}

- (void)setLoading:(BOOL)loading{
    _loading = loading;
    if (_loading) {
        self.text = nil;
        [_loadingView startAnimating];
    }else{
        [_loadingView stopAnimating];
    }
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)activityIndicatorViewStyle{
    _activityIndicatorViewStyle = activityIndicatorViewStyle;
    _loadingView.activityIndicatorViewStyle = _activityIndicatorViewStyle;
}

@end
