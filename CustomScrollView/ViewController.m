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
    
    self.customScrollView = [[AZExtraPageScrollView alloc] initWithFrame:self.view.bounds];
    self.customScrollView.contentSize = CGSizeMake(s.width * 4, s.height);
    self.customScrollView.scrollVertical = NO;
    self.customScrollView.pageHorizontally = YES;
    self.customScrollView.delegate = self;
    
    UIView *redView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, s.width, s.height)];
    UIView *greenView = [[UIView alloc] initWithFrame:CGRectMake(s.width, 0, s.width, s.height)];
    UIView *blueView = [[UIView alloc] initWithFrame:CGRectMake(s.width * 2, 0, s.width, s.height)];
    UIView *yellowView = [[UIView alloc] initWithFrame:CGRectMake(s.width * 3, 0, s.width, s.height)];
    
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

- (UIView *)firstExtraPageViewForScrollView:(AZExtraPageScrollView *)scrollView
{
    return [self newView];
}

- (UIView *)lastExtraPageViewForScrollView:(AZExtraPageScrollView *)scrollView
{
    return [self newView];
}

- (UIView *)newView
{
    CGSize s = self.view.bounds.size;
    
    UIView *newView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, s.width, s.height)];
    newView.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1];
    return newView;
}


@end
