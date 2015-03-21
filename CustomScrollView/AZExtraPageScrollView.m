//
//  CustomScrollView.m
//  CustomScrollView
//
//  Created by Ole Begemann on 16.04.14.
//  Copyright (c) 2014 Ole Begemann. All rights reserved.
//

#import "AZExtraPageScrollView.h"
#import <POP.h>

static const NSInteger ShadowViewTag = 4390470329;

@interface AZExtraPageScrollView ()

@property CGRect startBounds;
@property (nonatomic, strong) UIView *firstExtraPageView;
@property (nonatomic, strong) UIView *lastExtraPageView;

@end

@implementation AZExtraPageScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self == nil) {
        return nil;
    }
    
    [self commonInitForCustomScrollView];
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self == nil) {
        return nil;
    }
    
    [self commonInitForCustomScrollView];
    return self;
}

- (void)commonInitForCustomScrollView
{
    self.scrollHorizontal = YES;
    self.scrollVertical = YES;
    self.overshootFraction = 0.9;

    
    // Add a perspective transform
    CATransform3D transform = CATransform3DIdentity;
    
    transform.m34 = self.pageHorizontally ?  -0.005 : - 0.003;
    self.layer.sublayerTransform = transform;


    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:panGestureRecognizer];
}

- (POPAnimatableProperty *)boundsOriginProperty
{
    POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:@"com.rounak.bounds.origin" initializer:^(POPMutableAnimatableProperty *prop) {
        // read value
        prop.readBlock = ^(id obj, CGFloat values[]) {
            values[0] = [obj bounds].origin.x;
            values[1] = [obj bounds].origin.y;
        };
        // write value
        prop.writeBlock = ^(id obj, const CGFloat values[]) {
            CGRect tempBounds = [obj bounds];
            tempBounds.origin.x = values[0];
            tempBounds.origin.y = values[1];
            [obj setBounds:tempBounds];
        };
        // dynamics threshold
        prop.threshold = 0.01;
    }];

    return prop;
}


- (void)setOvershootFraction:(CGFloat)overshootFraction
{
    if (overshootFraction >= 1) {
        return;
    }
    
    _overshootFraction = overshootFraction;
}


- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            [self pop_removeAnimationForKey:@"bounce"];
            [self pop_removeAnimationForKey:@"decelerate"];
            self.startBounds = self.bounds;
            
            [self setupNewPageViews];

            
        }

        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [panGestureRecognizer translationInView:self];
            CGRect bounds = self.startBounds;

            if (!self.scrollHorizontal) {
                translation.x = 0.0;
            }
            if (!self.scrollVertical) {
                translation.y = 0.0;
            }

            CGFloat newBoundsOriginX = bounds.origin.x - translation.x;
            CGFloat minBoundsOriginX = 0.0;
            CGFloat maxBoundsOriginX = self.contentSize.width - bounds.size.width;
            CGFloat constrainedBoundsOriginX = fmax(minBoundsOriginX, fmin(newBoundsOriginX, maxBoundsOriginX));
            bounds.origin.x = constrainedBoundsOriginX + (newBoundsOriginX - constrainedBoundsOriginX) * self.overshootFraction;

            CGFloat newBoundsOriginY = bounds.origin.y - translation.y;
            CGFloat minBoundsOriginY = 0.0;
            CGFloat maxBoundsOriginY = self.contentSize.height - bounds.size.height;
            CGFloat constrainedBoundsOriginY = fmax(minBoundsOriginY, fmin(newBoundsOriginY, maxBoundsOriginY));
            bounds.origin.y = constrainedBoundsOriginY + (newBoundsOriginY - constrainedBoundsOriginY) * self.overshootFraction;

            self.bounds = bounds;
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            CGPoint velocity = [panGestureRecognizer velocityInView:self];

            if (!self.scrollHorizontal) {
                velocity.x = 0.0;
            }
            if (!self.scrollVertical) {
                velocity.y = 0.0;
            }

            velocity.x = -velocity.x;
            velocity.y = -velocity.y;
            NSLog(@"decelerating with velocity: %@", NSStringFromCGPoint(velocity));

            BOOL outsideBounds = [self outsideBounds];
            // if we are outside the bounds - use pop decay animation
            if (outsideBounds) {
                if ([self outsideBoundsMinimum]) {
                    CGFloat progress;
                    if (self.pageHorizontally) {
                        progress = -self.bounds.origin.x / self.bounds.size.width;
                    } else {
                        progress = -self.bounds.origin.y / self.bounds.size.height;
                    }
                    if (progress > 0.5 && fmin(velocity.x, velocity.y) < 0) {
                        [self includeFirstExtraPageWithVelocity:velocity];
                        return;
                    }
                }
                if ([self outsideBoundsMaximum]) {
                    CGFloat progress;
                    if (self.pageHorizontally) {
                        progress = (self.bounds.origin.x + self.bounds.size.width - self.contentSize.width) / self.bounds.size.width;
                    } else {
                        progress = (self.bounds.origin.y + self.bounds.size.height - self.contentSize.height) / self.bounds.size.height;
                    }
                    if (progress > 0.5 && fmax(velocity.x, velocity.y) > 0) {
                        [self includeLastExtraPageWithVelocity:velocity];
                        return;
                    }
                }
                
                POPDecayAnimation *decayAnimation = [POPDecayAnimation animation];
                decayAnimation.property = [self boundsOriginProperty];
                decayAnimation.velocity = [NSValue valueWithCGPoint:velocity];
                [self pop_addAnimation:decayAnimation forKey:@"decelerate"];
                
            // if we just did a normal scroll, stop to a page
            } else {
                [self animateToPageWithVelocity:velocity];
            }
        }
            break;

        default:
            break;
    }

}

- (void)setupNewPageViews
{
    
    if (!self.firstExtraPageView && [self.delegate respondsToSelector:@selector(firstExtraPageViewForScrollView:)]) {
        // ask the delegate for the new view and also add shadow to it
        self.firstExtraPageView = [self addShadowToView:[self.delegate firstExtraPageViewForScrollView:self] reverse:NO];
        
        CGRect f = CGRectZero;
        f.size = self.bounds.size;
        if (self.pageHorizontally) {
            f.origin.x = -f.size.width;
        } else {
            f.origin.y = -f.size.height;
        }
        self.firstExtraPageView.frame = f;
        
        [self addSubview:self.firstExtraPageView];
        
        if (self.pageHorizontally) {
            // position is in superlayer's coordinate space, thus self.view.layer coordinate space, therefore position X at 0
            self.firstExtraPageView.layer.position = CGPointMake(0, f.size.height/2);
            self.firstExtraPageView.layer.anchorPoint = CGPointMake(1, 0.5);
        } else {
            self.firstExtraPageView.layer.position = CGPointMake(f.size.width/2, 0);
            self.firstExtraPageView.layer.anchorPoint = CGPointMake(0.5, 1);
        }
        
    }
    
    if (!self.lastExtraPageView && [self.delegate respondsToSelector:@selector(lastExtraPageViewForScrollView:)]) {
        self.lastExtraPageView = [self addShadowToView:[self.delegate lastExtraPageViewForScrollView:self] reverse:YES];
        
        CGRect f = CGRectZero;
        f.size = self.bounds.size;
        if (self.pageHorizontally) {
            f.origin.x = self.contentSize.width;
        } else {
            f.origin.y = self.contentSize.height;
        }
        self.lastExtraPageView.frame = f;
        
        [self addSubview:self.lastExtraPageView];
        
        if (self.pageHorizontally) {
            self.lastExtraPageView.layer.position = CGPointMake(self.contentSize.width, f.size.height/2);
            self.lastExtraPageView.layer.anchorPoint = CGPointMake(0, 0.5);
        } else {
            self.lastExtraPageView.layer.position = CGPointMake(f.size.width / 2, self.contentSize.height);
            self.lastExtraPageView.layer.anchorPoint = CGPointMake(0.5, 0);
        }
        
    }
}


- (void)includeFirstExtraPageWithVelocity:(CGPoint)velocity
{
    CGRect newBounds = self.bounds;
    if (self.pageHorizontally) {
        newBounds.origin.x = -self.bounds.size.width;
    } else {
        newBounds.origin.y = -self.bounds.size.height;
    }
    
    [self animateToBounds:newBounds
             withVelocity:velocity
                 duration:0.35
         allowInteraction:NO
               completion:^(BOOL finished) {
                   [self moveAllPageViewsByPageDelta:+1];
                   
                   [self increaseContentSizeByPageDelta:1];
                   
                   // reset the origin to 0
                   CGRect bounds = self.bounds;
                   if (self.pageHorizontally) {
                       bounds.origin.x = 0;
                   } else {
                       bounds.origin.y = 0;
                   }
                   self.bounds = bounds;
                   
                   [self normalizeLayerForPageView:self.firstExtraPageView];

                   self.firstExtraPageView = nil;
                   
                   if ([self.delegate respondsToSelector:@selector(scrollView:extraPageAddedToStart:)]) {
                       [self.delegate scrollView:self extraPageAddedToStart:YES];
                   }
                   
                   [self notifyOfPageChange];
               }];
}

- (void)includeLastExtraPageWithVelocity:(CGPoint)velocity
{
    CGRect newBounds = self.bounds;
    if (self.pageHorizontally) {
        newBounds.origin.x = self.contentSize.width;
    } else {
        newBounds.origin.y = self.contentSize.height;
    }
    
    [self animateToBounds:newBounds
             withVelocity:velocity
                 duration:0.35
         allowInteraction:NO
               completion:^(BOOL finished) {
                   [self increaseContentSizeByPageDelta:1];
                   [self normalizeLayerForPageView:self.lastExtraPageView];
                   self.lastExtraPageView = nil;
                   
                   if ([self.delegate respondsToSelector:@selector(scrollView:extraPageAddedToStart:)]) {
                       [self.delegate scrollView:self extraPageAddedToStart:NO];
                   }
                   
                   [self notifyOfPageChange];
               }];
}


- (void)moveAllPageViewsByPageDelta:(NSInteger)pageDelta
{
    // move all subviews forward by one page
    for (UIView *subview in self.subviews) {
        CGRect f = subview.frame;
        if (self.pageHorizontally) {
            f.origin.x += self.bounds.size.width * pageDelta;
        } else {
            f.origin.y += self.bounds.size.height * pageDelta;
        }
        subview.frame = f;
    }
}

- (void)increaseContentSizeByPageDelta:(NSInteger)pageDelta
{
    if (self.pageHorizontally) {
        self.contentSize = CGSizeMake(self.contentSize.width + self.bounds.size.width * pageDelta, self.contentSize.height);
    } else {
        self.contentSize = CGSizeMake(self.contentSize.width, self.contentSize.height + self.bounds.size.height * pageDelta);
    }
}

- (void)normalizeLayerForPageView:(UIView *)pageView
{
    CGRect f = pageView.frame;
    pageView.layer.anchorPoint = CGPointMake(0.5, 0.5);
    pageView.layer.position = CGPointMake(f.origin.x + f.size.width / 2, f.origin.y + f.size.height / 2);
    [pageView.layer setTransform:CATransform3DIdentity];
}

- (void)animateToPageWithVelocity:(CGPoint)velocity
{
    CGFloat animationDuration = 0.35;
    
    // calculate projected bounds origin
    
    CGFloat projectedCoordinate;
    NSInteger projectedPageNo;
    NSInteger startPageNo;
    if (self.pageHorizontally) {
        projectedCoordinate = self.bounds.origin.x + velocity.x * animationDuration;
        // check that we don't overshoot with our projected bounds origin coordinates
        projectedCoordinate = fmax(0, fmin(projectedCoordinate, self.contentSize.width - self.bounds.size.width));
        
        // calculate the target number of page
        projectedPageNo = roundf(projectedCoordinate / self.bounds.size.width);

        startPageNo = roundf(self.startBounds.origin.x / self.bounds.size.width);
    } else {
        projectedCoordinate = self.bounds.origin.y + velocity.y * animationDuration;
        projectedCoordinate = fmax(0, fmin(projectedCoordinate, self.contentSize.height - self.bounds.size.height));
        
        projectedPageNo = roundf(projectedCoordinate / self.bounds.size.height);

        startPageNo = roundf(self.startBounds.origin.y / self.bounds.size.height);
    }
    
    // don't allow moving past 1 page at any time
    projectedPageNo = fmin(startPageNo + 1, fmax(projectedPageNo, startPageNo - 1));
    
    
    // calc the actual bounds
    CGRect pagedBounds = self.bounds;
    if (self.pageHorizontally) {
        pagedBounds.origin.x = projectedPageNo * self.bounds.size.width;
    } else {
        pagedBounds.origin.y = projectedPageNo * self.bounds.size.height;
    }
    
    [self animateToBounds:pagedBounds
             withVelocity:velocity
                 duration:animationDuration
         allowInteraction:YES
               completion:^(BOOL finished) {
                   if (startPageNo != projectedPageNo) {
                       [self notifyOfPageChange];
                   }
               }];
}


- (void)notifyOfPageChange
{
    if ([self.delegate respondsToSelector:@selector(scrollView:didScrollToPage:fromPage:)]) {
        NSInteger startPageNo;
        NSInteger endPageNo;
        if (self.pageHorizontally) {
            startPageNo = roundf(self.startBounds.origin.x / self.bounds.size.width);
            endPageNo = roundf(self.bounds.origin.x / self.bounds.size.width);
        } else {
            startPageNo = roundf(self.startBounds.origin.y / self.bounds.size.height);
            endPageNo = roundf(self.bounds.origin.y / self.bounds.size.height);
        }
        
        [self.delegate scrollView:self didScrollToPage:endPageNo fromPage:startPageNo];
    }
}

- (void)animateToBounds:(CGRect)bounds
           withVelocity:(CGPoint)velocity
               duration:(CGFloat)animationDuration
       allowInteraction:(BOOL)allowInteraction
             completion:(void (^)(BOOL finished))completion
{
    
    CGFloat xDelta = self.bounds.origin.x - bounds.origin.x;
    CGFloat yDelta = self.bounds.origin.y - bounds.origin.y;
    
    // springVelocity 1 means - velocity of full animation distance travelled in one second
    // calculate springVelocity as velocity.x / xDelta to make animation start velocity the same as gesture velocity
    // Example: xDelta = 200, velocity.x = 20 p/s
    // 1 second 200px, springVelocity = 200 / 20 = 0.1, thus 20 points per 1 second
    
    CGFloat springVelocity = 0;
    // take the maximum of yVelocity and xVelocity. Maybe that would not be geometrically correct
    // but at this point it'll be alright, since normally we scroll in one direction only
    if (xDelta > 0) {
        springVelocity = velocity.x / xDelta;
    }
    if (yDelta > 0) {
        springVelocity = fmax(springVelocity, velocity.y / yDelta);
    }
    
    // use spring animation just because of it's velocity param (thus damping : 1)
    [UIView animateWithDuration:animationDuration
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:springVelocity
                        options:allowInteraction ? UIViewAnimationOptionAllowUserInteraction : 0
                     animations:^{
                         self.bounds = bounds;
                     }
                     completion:completion];
    
}

- (BOOL)outsideBoundsMinimum
{
    CGRect bounds = self.bounds;
    return bounds.origin.x < 0.0 || bounds.origin.y < 0.0;
}

- (BOOL)outsideBoundsMaximum
{
    CGRect bounds = self.bounds;
    return bounds.origin.x > self.contentSize.width - bounds.size.width || bounds.origin.y > self.contentSize.height - bounds.size.height;
}

- (BOOL)outsideBounds
{
    return [self outsideBoundsMinimum] || [self outsideBoundsMaximum];
}


- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];

    BOOL outsideBoundsMinimum = [self outsideBoundsMinimum];
    BOOL outsideBoundsMaximum = [self outsideBoundsMaximum];

    if (outsideBoundsMaximum || outsideBoundsMinimum) {
        POPDecayAnimation *decayAnimation = [self pop_animationForKey:@"decelerate"];
        if (decayAnimation) {
            CGPoint target = bounds.origin;
            if (outsideBoundsMinimum) {
                target.x = fmax(target.x, 0.0);
                target.y = fmax(target.y, 0.0);
            } else if (outsideBoundsMaximum) {
                target.x = fmin(target.x, self.contentSize.width - bounds.size.width);
                target.y = fmin(target.y, self.contentSize.height - bounds.size.height);
            }

            NSLog(@"bouncing with velocity: %@", decayAnimation.velocity);

            POPSpringAnimation *springAnimation = [POPSpringAnimation animation];
            springAnimation.property = [self boundsOriginProperty];
            springAnimation.velocity = decayAnimation.velocity;
            springAnimation.toValue = [NSValue valueWithCGPoint:target];
            springAnimation.springBounciness = 0.0;
            springAnimation.springSpeed = 5.0;
            [self pop_addAnimation:springAnimation forKey:@"bounce"];

            [self pop_removeAnimationForKey:@"decelerate"];
        }
    }
    
    if (outsideBoundsMinimum && self.firstExtraPageView) {
        // we don't start at -90 degrees because that would render the view behind our first view due to the perspective
        // this constant is related to self.layer.sublayerTransform.m34
        CGFloat startAngle = self.pageHorizontally ? -M_PI_2 * 0.55 : M_PI_2 * 0.55;
        
        CGFloat progress;
        if (self.pageHorizontally) {
            progress = -self.bounds.origin.x / self.bounds.size.width;
        } else {
            progress = -self.bounds.origin.y / self.bounds.size.height;
        }
        CGFloat reverseProgress = 1 - progress;
        if (self.pageHorizontally) {
            self.firstExtraPageView.layer.transform = CATransform3DMakeRotation(startAngle * reverseProgress, 0.0, 1.0, 0.0);
        } else {
            self.firstExtraPageView.layer.transform = CATransform3DMakeRotation(startAngle * reverseProgress, 1.0, 0.0, 0.0);
        }

        // animate shadow
        UIView *shadowView = [self.firstExtraPageView viewWithTag:ShadowViewTag];
        [shadowView setAlpha:reverseProgress];
    }
    
    
    
    if (outsideBoundsMaximum && self.lastExtraPageView) {
        // we don't start at -90 degrees because that would render the view behind our first view due to the perspective
        // this constant is related to self.layer.sublayerTransform.m34
        CGFloat startAngle = self.pageHorizontally ? M_PI_2 * 0.55 : -M_PI_2 * 0.55;
        
        CGFloat progress;
        if (self.pageHorizontally) {
            progress = (self.bounds.origin.x + self.bounds.size.width - self.contentSize.width) / self.bounds.size.width;
        } else {
            progress = (self.bounds.origin.y + self.bounds.size.height - self.contentSize.height) / self.bounds.size.height;
        }
        CGFloat reverseProgress = 1 - progress;
        if (self.pageHorizontally) {
            self.lastExtraPageView.layer.transform = CATransform3DMakeRotation(startAngle * reverseProgress, 0.0, 1.0, 0.0);
        } else {
            self.lastExtraPageView.layer.transform = CATransform3DMakeRotation(startAngle * reverseProgress, 1.0, 0.0, 0.0);
        }
        
        
        // animate shadow
        UIView *shadowView = [self.lastExtraPageView viewWithTag:ShadowViewTag];
        [shadowView setAlpha:reverseProgress];
    }

}


#pragma mark - Create Shadow


// Source: http://blog.scottlogic.com/2013/09/26/tabbar-custom-transitions.html

// adds a gradient to an image by creating a containing UIView with both the given view
// and the gradient as subviews
- (UIView *)addShadowToView:(UIView *)view reverse:(BOOL)reverse {
    
    // create a view with the same frame
    UIView *viewWithShadow = [[UIView alloc] initWithFrame:view.frame];
    
    // create a shadow
    UIView *shadowView = [[UIView alloc] initWithFrame:viewWithShadow.bounds];
    shadowView.tag = ShadowViewTag;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = shadowView.bounds;
    gradient.colors = @[(id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor,
                        (id)[UIColor colorWithWhite:0.0 alpha:1.0].CGColor];
    gradient.startPoint = CGPointMake(reverse ? 0.0 : 1.0, reverse ? 0.2 : 0.0);
    gradient.endPoint = CGPointMake(reverse ? 1.0 : 0.0, reverse ? 0.0 : 1.0);
    [shadowView.layer insertSublayer:gradient atIndex:1];
    
    // add the original view into our new view
    view.frame = view.bounds;
    [viewWithShadow addSubview:view];
    
    // place the shadow on top
    [viewWithShadow addSubview:shadowView];
    
    return viewWithShadow;
}

@end
