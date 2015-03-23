//
//  ModelController.h
//  SamplePageBasedProj
//
//  Created by Andris Zalitis on 22/03/15.
//  Copyright (c) 2015 POLLEO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AZExtraPageViewController.h"

@class DataViewController;

@interface ModelController : NSObject <AZExtraPageViewControllerDataSource>

- (DataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
- (NSUInteger)indexOfViewController:(DataViewController *)viewController;

@end

