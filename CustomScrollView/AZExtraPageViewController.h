//
//  AZExtraPageViewController.h
//  CustomScrollView
//
//  Created by Andris Zalitis on 22/03/15.
//  Copyright (c) 2015 Ole Begemann. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AZExtraPageScrollView.h"


typedef enum : NSUInteger {
    AZExtraPageViewControllerNavigationOrientationHorizontal,
    AZExtraPageViewControllerNavigationOrientationVertical,
} AZExtraPageViewControllerNavigationOrientation;

@class AZExtraPageViewController;

@protocol AZExtraPageViewControllerDataSource <NSObject>

- (UIViewController *)pageViewController:(AZExtraPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController;

- (UIViewController *)pageViewController:(AZExtraPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController;


- (UIViewController *)pageViewController:(AZExtraPageViewController *)pageViewController
 extraViewControllerBeforeViewController:(UIViewController *)viewController;

- (UIViewController *)pageViewController:(AZExtraPageViewController *)pageViewController
  extraViewControllerAfterViewController:(UIViewController *)viewController;

@end


@protocol AZExtraPageViewControllerDelegate <NSObject>

- (void)pageViewController:(AZExtraPageViewController *)pageViewController
  addedExtraViewController:(UIViewController *)extraViewController
      beforeViewController:(UIViewController *)viewController;

- (void)pageViewController:(AZExtraPageViewController *)pageViewController
  addedExtraViewController:(UIViewController *)extraViewController
      afterViewController:(UIViewController *)viewController;

@end

@interface AZExtraPageViewController : UIViewController<AZExtraPageScrollViewDelegate>

@property (nonatomic, assign) AZExtraPageViewControllerNavigationOrientation navigationOrientation;

@property (nonatomic, weak) id<AZExtraPageViewControllerDataSource> dataSource;



- (void)setCurrentViewController:(UIViewController *)currentViewController;
- (UIViewController *)currentViewController;

- (NSArray *)gestureRecognizers;


@end
