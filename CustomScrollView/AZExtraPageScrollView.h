//
//  CustomScrollView.h
//  CustomScrollView
//
//  Created by Ole Begemann on 16.04.14.
//  Copyright (c) 2014 Ole Begemann. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    AZExtraPagePositionFirst,
    AZExtraPagePositionLast,
} AZExtraPagePosition;


@class AZExtraPageScrollView;

@protocol AZExtraPageScrollViewDelegate <NSObject>

@optional
- (UIView *)scrollView:(AZExtraPageScrollView *)scrollView extraPageViewAtPosition:(AZExtraPagePosition)position;
//- (UIView *)firstExtraPageViewForScrollView:(AZExtraPageScrollView *)scrollView;
//- (UIView *)lastExtraPageViewForScrollView:(AZExtraPageScrollView *)scrollView;

//- (void)scrollView:(AZExtraPageScrollView *)scrollView extraPageAddedToStart:(BOOL)toStart;
//- (void)scrollView:(AZExtraPageScrollView *)scrollView extraPageAddedAtPosition:(AZExtraPagePosition)position;
- (void)scrollView:(AZExtraPageScrollView *)scrollView extraPageView:(UIView *)pageView addedAtPosition:(AZExtraPagePosition)position;


- (void)scrollView:(AZExtraPageScrollView *)scrollView didScrollToPage:(NSInteger)toPageIndex fromPage:(NSInteger)fromPageIndex;
- (void)scrollView:(AZExtraPageScrollView *)scrollView willScrollFromPage:(NSInteger)fromPageIndex;

@end


@interface AZExtraPageScrollView : UIView

@property (nonatomic) CGSize contentSize;
@property (nonatomic) BOOL scrollVertical;
@property (nonatomic) BOOL scrollHorizontal;

@property (nonatomic, assign) BOOL pageHorizontally;
@property (nonatomic, assign) CGFloat bounceFraction;

@property (nonatomic, weak) id<AZExtraPageScrollViewDelegate>delegate;

- (void)setPageView:(UIView *)view atIndex:(NSInteger)pageIndex;
- (void)setPageCount:(NSInteger)pageCount;
- (void)setCurrentPagePosition:(NSInteger)pagePosition;
- (void)shiftAllPageViewsByPageDelta:(NSInteger)pageDelta;

@end
