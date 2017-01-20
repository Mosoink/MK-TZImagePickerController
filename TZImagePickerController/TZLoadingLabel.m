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
    _loadingView.frame  = CGRectMake(0, 0, self.height, self.height);
    if (self.textAlignment == NSTextAlignmentLeft) {
        _loadingView.centerX = self.height/2.;
    }else if (self.textAlignment == NSTextAlignmentCenter) {
        _loadingView.centerX = self.width/2.;
    }else if (self.textAlignment == NSTextAlignmentRight) {
        _loadingView.centerX = self.width-self.height/2.;
    }
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
