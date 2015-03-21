//
//  ViewController.m
//  CustomScrollView
//
//  Created by Ole Begemann on 16.04.14.
//  Copyright (c) 2014 Ole Begemann. All rights reserved.
//

#import "ViewController.h"
#import "AZExtraPageScrollView.h"

@interface ViewController ()

@property (nonatomic) AZExtraPageScrollView *customScrollView;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGSize s = self.view.bounds.size;

    BOOL horizontal = YES;
    
    self.customScrollView = [[AZExtraPageScrollView alloc] initWithFrame:self.view.bounds];
    self.customScrollView.delegate = self;
    
    UIView *redView, *greenView, *blueView, *yellowView;
    if (horizontal) {
        self.customScrollView.contentSize = CGSizeMake(s.width * 4, s.height);
        self.customScrollView.scrollVertical = NO;
        self.customScrollView.pageHorizontally = YES;
        
        redView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, s.width, s.height)];
        greenView = [[UIView alloc] initWithFrame:CGRectMake(s.width, 0, s.width, s.height)];
        blueView = [[UIView alloc] initWithFrame:CGRectMake(s.width * 2, 0, s.width, s.height)];
        yellowView = [[UIView alloc] initWithFrame:CGRectMake(s.width * 3, 0, s.width, s.height)];
    } else {
        self.customScrollView.contentSize = CGSizeMake(s.width, s.height * 4);
        self.customScrollView.scrollHorizontal = NO;
        self.customScrollView.pageHorizontally = NO;
        
        redView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, s.width, s.height)];
        greenView = [[UIView alloc] initWithFrame:CGRectMake(0, s.height, s.width, s.height)];
        blueView = [[UIView alloc] initWithFrame:CGRectMake(0, s.height * 2, s.width, s.height)];
        yellowView = [[UIView alloc] initWithFrame:CGRectMake(0, s.height * 3, s.width, s.height)];
    }
    
    redView.backgroundColor = [UIColor colorWithRed:0.815 green:0.007 blue:0.105 alpha:1];
    greenView.backgroundColor = [UIColor colorWithRed:0.494 green:0.827 blue:0.129 alpha:1];
    blueView.backgroundColor = [UIColor colorWithRed:0.29 green:0.564 blue:0.886 alpha:1];
    yellowView.backgroundColor = [UIColor colorWithRed:0.972 green:0.905 blue:0.109 alpha:1];

    
    [self.customScrollView addSubview:redView];
    [self.customScrollView addSubview:greenView];
    [self.customScrollView addSubview:blueView];
    [self.customScrollView addSubview:yellowView];

    [self.view addSubview:self.customScrollView];
    
}

#pragma mark - AZExtraPageScrollViewDelegate
- (UIView *)firstExtraPageViewForScrollView:(AZExtraPageScrollView *)scrollView
{
    return [self newView];
}

- (UIView *)lastExtraPageViewForScrollView:(AZExtraPageScrollView *)scrollView
{
    return [self newView];
}

- (void)scrollView:(AZExtraPageScrollView *)scrollView didScrollToPage:(NSInteger)toPageIndex fromPage:(NSInteger)fromPageIndex
{
    NSLog(@"Scrolled to page:%ld from page:%ld", (long)toPageIndex, (long)fromPageIndex);
}

- (void)scrollView:(AZExtraPageScrollView *)scrollView extraPageAddedToStart:(BOOL)toStart
{
    if (toStart) {
        NSLog(@"Added extra page at the beginning");
    } else {
        NSLog(@"Added extra page at the end");
    }
    
}

#pragma mark -

- (UIView *)newView
{
    CGSize s = self.view.bounds.size;
    
    UIView *newView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, s.width, s.height)];
    newView.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1];
    return newView;
}


@end
