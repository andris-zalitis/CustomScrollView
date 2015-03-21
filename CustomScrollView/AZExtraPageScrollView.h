//
//  CustomScrollView.h
//  CustomScrollView
//
//  Created by Ole Begemann on 16.04.14.
//  Copyright (c) 2014 Ole Begemann. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AZExtraPageScrollView;

@protocol AZExtraPageScrollViewDelegate <NSObject>

@optional
- (UIView *)firstExtraPageViewForScrollView:(AZExtraPageScrollView *)scrollView;
- (UIView *)lastExtraPageViewForScrollView:(AZExtraPageScrollView *)scrollView;

- (void)scrollView:(AZExtraPageScrollView *)scrollView extraPageAddedToStart:(BOOL)toStart;
- (void)scrollView:(AZExtraPageScrollView *)scrollView didScrollToPage:(NSInteger)toPageIndex fromPage:(NSInteger)fromPageIndex;


@end


@interface AZExtraPageScrollView : UIView

@property (nonatomic) CGSize contentSize;
@property (nonatomic) BOOL scrollVertical;
@property (nonatomic) BOOL scrollHorizontal;

@property (nonatomic, assign) BOOL pageHorizontally;
@property (nonatomic, assign) CGFloat overshootFraction;


@property (nonatomic, weak) id<AZExtraPageScrollViewDelegate>delegate;

@end
