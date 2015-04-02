//
//  AZExtraPageViewController.m
//  CustomScrollView
//
//  Created by Andris Zalitis on 22/03/15.
//  Copyright (c) 2015 Ole Begemann. All rights reserved.
//

#import "AZExtraPageViewController.h"

@interface AZExtraPageViewController ()

@property (nonatomic, strong) AZExtraPageScrollView *scrollView;

@end

@implementation AZExtraPageViewController
{
    NSMutableArray *_viewControllers;
    NSInteger _currentViewControllerNo;
//    UIViewController *_firstExtraPageViewController;
//    UIViewController *_lastExtraPageViewController;
}
//
//- (id)initWithCoder:(NSCoder *)aDecoder
//{
//    
//}
//
//- (void)commonInit
//{
//    
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.scrollView = [[AZExtraPageScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.pageHorizontally = self.navigationOrientation == AZExtraPageViewControllerNavigationOrientationHorizontal;
    if (self.scrollView.pageHorizontally) {
        self.scrollView.scrollVertical = NO;
    } else {
        self.scrollView.scrollHorizontal = NO;
    }
    self.scrollView.delegate = self;
    
    [self.view addSubview:self.scrollView];
    
    _viewControllers = [NSMutableArray array];
}

- (NSArray *)gestureRecognizers
{
    return [self.scrollView gestureRecognizers];
}

/**
 Sets the view controller that will be shown in the UI.
 Does not have a backing instance variable because we keep previous and next view controllers preloaded (if possible)
 and use _viewControllers array to store all three.
 */
- (void)setCurrentViewController:(UIViewController *)currentViewController
{

    // remove currently loaded view controllers
    for (NSInteger i = 0; i < [_viewControllers count]; i++) {
        [self removeViewControllerAtIndex:i];
    }
    
    if (! currentViewController) {
        return;
    }

    NSInteger viewControllerNo = 0;
    
    // add previous vc
    UIViewController *previousVC = [self.dataSource pageViewController:self viewControllerBeforeViewController:currentViewController];
    if (previousVC) {
        [self addChildViewController:previousVC atIndex:viewControllerNo];
//        _viewControllers[viewControllerNo] = previousVC;
        ++viewControllerNo;
    }
    
    
    // add current vc
    [self addChildViewController:currentViewController atIndex:viewControllerNo];
//    [self addChildViewController:currentViewController];
//    [self.scrollView setPageView:currentViewController.view atIndex:viewControllerNo];
//    [currentViewController didMoveToParentViewController:self];
//    _viewControllers[viewControllerNo] = currentViewController;
    _currentViewControllerNo = viewControllerNo;
    ++viewControllerNo;
    

    // add next vc
    UIViewController *nextVC = [self.dataSource pageViewController:self viewControllerAfterViewController:currentViewController];
    if (nextVC) {
        [self addChildViewController:nextVC atIndex:viewControllerNo];
//        _viewControllers[viewControllerNo] = nextVC;
        ++viewControllerNo;
    }

    [self.scrollView setPageCount:viewControllerNo];
    [self.scrollView setCurrentPagePosition:_currentViewControllerNo];
    
}

- (UIViewController *)currentViewController
{
    return _viewControllers[_currentViewControllerNo];
}


- (void)addChildViewController:(UIViewController *)childController atIndex:(NSInteger)index
{
    if (! childController) {
        return;
    }
    
    [self addChildViewController:childController];
    
    [self.scrollView setPageView:childController.view atIndex:index];
    
    [childController didMoveToParentViewController:self];

    [_viewControllers insertObject:childController atIndex:index];
}


- (void)removeViewControllerAtIndex:(NSInteger)index
{
    if (index < [_viewControllers count]) {
        UIViewController *vc = _viewControllers[index];
        [vc.view removeFromSuperview];
        [vc removeFromParentViewController];
        [_viewControllers removeObjectAtIndex:index];
    }
}

#pragma mark - 

- (void)removeCurrentViewControllerWithAnimation
{
    UIViewController *viewController = [self currentViewController];
    
    [self.scrollView deletePageViewWithAnimation:viewController.view];

    [viewController removeFromParentViewController];

}

#pragma mark - AZExtraPageScrollViewDelegate

- (void)scrollView:(AZExtraPageScrollView *)scrollView willScrollFromPage:(NSInteger)fromPageIndex
{
    NSLog(@"willScrollFromPage:%ld", fromPageIndex);
    
    [self ensurePrevNextForPageIndex:fromPageIndex];
}

- (void)scrollView:(AZExtraPageScrollView *)scrollView didScrollToPage:(NSInteger)toPageIndex fromPage:(NSInteger)fromPageIndex
{
    NSLog(@"didScrollToPage:%ld fromPage:%ld", toPageIndex, fromPageIndex);

    _currentViewControllerNo = toPageIndex;
    
    [self ensurePrevNextForPageIndex:toPageIndex];
    
    if ([self.delegate respondsToSelector:@selector(pageViewController:scrolledToViewController:)]) {
        [self.delegate pageViewController:self scrolledToViewController:_viewControllers[toPageIndex]];
    }
}

- (UIView *)scrollView:(AZExtraPageScrollView *)scrollView extraPageViewAtPosition:(AZExtraPagePosition)position
{
    if (position == AZExtraPagePositionFirst) {
        if (! [self.dataSource respondsToSelector:@selector(pageViewController:extraViewBeforeViewController:)]) {
            return nil;
        }
        
        UIView *view = [self.dataSource pageViewController:self
                             extraViewBeforeViewController:_viewControllers[0]];
        
        return view;
//        
//        vc.view.frame = CGRectMake(0, 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
//        UIView *snapshotView = [vc.view snapshotViewAfterScreenUpdates:YES];
//        
//        _firstExtraPageViewController = vc;
//        
//        return snapshotView;
    } else if (position == AZExtraPagePositionLast) {
        if (! [self.dataSource respondsToSelector:@selector(pageViewController:extraViewAfterViewController:)]) {
            return nil;
        }
        
        UIView *view = [self.dataSource pageViewController:self
                              extraViewAfterViewController:_viewControllers[[_viewControllers count] - 1]];
        
        return view;
//        
//        vc.view.frame = CGRectMake(0, 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
//        UIView *snapshotView = [vc.view snapshotViewAfterScreenUpdates:YES];
//        
//        _lastExtraPageViewController = vc;
//        
//        return snapshotView;
    }
    
    return nil;
}

- (void)scrollView:(AZExtraPageScrollView *)scrollView extraPageView:(UIView *)pageView addedAtPosition:(AZExtraPagePosition)position
{
    if (position == AZExtraPagePositionFirst) {
        // remove the snapshot view encapsulation, we'll replace that with the actual view of the view controller
        [pageView removeFromSuperview];

        if (! [self.dataSource respondsToSelector:@selector(pageViewController:extraViewControllerBeforeViewController:)]) {
            return;
        }

        UIViewController *vc = [self.dataSource pageViewController:self
                           extraViewControllerBeforeViewController:_viewControllers[0]];
        
        [self addChildViewController:vc atIndex:0];
        
        if ([_viewControllers count] > 3) {
            [self removeViewControllerAtIndex:[_viewControllers count] - 1];
            [self.scrollView setPageCount:[_viewControllers count]];
        }
        // update content size
        [self.scrollView setPageCount:[_viewControllers count]];
        
        _currentViewControllerNo = 0;
    } else if (position == AZExtraPagePositionLast) {
        [pageView removeFromSuperview];
        
        UIViewController *vc = [self.dataSource pageViewController:self
                            extraViewControllerAfterViewController:_viewControllers[[_viewControllers count] - 1]];

        [self addChildViewController:vc atIndex:[_viewControllers count]];
        
        if ([_viewControllers count] > 3) {
            [self removeViewControllerAtIndex:0];
            // removed 0th, so shift back
            [self.scrollView shiftAllPageViewsByPageDelta:-1];
        }
        [self.scrollView setPageCount:[_viewControllers count]];
        
        _currentViewControllerNo = [_viewControllers count] - 1;
        // if we shifted the views back, we would need to update the bounds origin too
        [self.scrollView setCurrentPagePosition:_currentViewControllerNo];
    }
}

- (void)scrollView:(AZExtraPageScrollView *)scrollView rubberBandDraggedAtRelativePosition:(float)rubbedBandRelativePosition
{
    if ([self.delegate respondsToSelector:@selector(pageViewController:rubberBandDraggedAtRelativePosition:)]) {
        [self.delegate pageViewController:self rubberBandDraggedAtRelativePosition:rubbedBandRelativePosition];
    }
}


#pragma mark - 

- (void)ensurePrevNextForPageIndex:(NSInteger)pageIndex
{
    
    // if we moved to the first page, then rearrange so that it is in the middle again
    if (pageIndex == 0) {
        UIViewController *newPreviousVC = [self.dataSource pageViewController:self viewControllerBeforeViewController:_viewControllers[pageIndex]];
        
        // only if we are not at the beginning of view controllers from our data source, it makes sense to delete the 3rd and reshift
        if (newPreviousVC) {
            
            // if we already have 3 viewcontrolls, then remove the third since we'll add one at the beginning
            if ([_viewControllers count] > 2) {
                [self removeViewControllerAtIndex:2];
            }
            
            // move all pages by 1 forward so that we had space for new 0th page
            [self.scrollView shiftAllPageViewsByPageDelta:1];
            
            
            [self addChildViewController:newPreviousVC atIndex:0];
            
            _currentViewControllerNo = 1;
            
            [self.scrollView setPageCount:[_viewControllers count]];
            [self.scrollView setCurrentPagePosition:_currentViewControllerNo];
            
        } else {
            _currentViewControllerNo = 0;
        }
        
    } else if (pageIndex == [_viewControllers count] - 1) {
        
        UIViewController *nextVC = [self.dataSource pageViewController:self viewControllerAfterViewController:_viewControllers[pageIndex]];
        
        // only if we are not at the beginning of view controllers from our data source, it makes sense to delete the 3rd and reshift
        if (nextVC) {
            
            // if we already have 3 viewcontrollers, then remove the first since we'll add one at the beginning
            if ([_viewControllers count] > 2) {
                [self removeViewControllerAtIndex:0];
                
                // move all pages by 1 backwards because we deleted the 0th page
                [self.scrollView shiftAllPageViewsByPageDelta:-1];
            }
            
            
            [self addChildViewController:nextVC atIndex:[_viewControllers count]];
            _currentViewControllerNo = [_viewControllers count] - 2;
            
            [self.scrollView setPageCount:[_viewControllers count]];
            [self.scrollView setCurrentPagePosition:_currentViewControllerNo];
            
        } else {
            _currentViewControllerNo = [_viewControllers count] - 1;
        }
        
    }

}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
