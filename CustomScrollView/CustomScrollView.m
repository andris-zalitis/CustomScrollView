//
//  CustomScrollView.m
//  CustomScrollView
//
//  Created by Ole Begemann on 16.04.14.
//  Copyright (c) 2014 Ole Begemann. All rights reserved.
//

#import "CustomScrollView.h"
#import <POP.h>

@interface CustomScrollView ()
@property CGRect startBounds;
@end

@implementation CustomScrollView

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

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            [self pop_removeAnimationForKey:@"bounce"];
            [self pop_removeAnimationForKey:@"decelerate"];
            self.startBounds = self.bounds;
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
            bounds.origin.x = constrainedBoundsOriginX + (newBoundsOriginX - constrainedBoundsOriginX) / 2;

            CGFloat newBoundsOriginY = bounds.origin.y - translation.y;
            CGFloat minBoundsOriginY = 0.0;
            CGFloat maxBoundsOriginY = self.contentSize.height - bounds.size.height;
            CGFloat constrainedBoundsOriginY = fmax(minBoundsOriginY, fmin(newBoundsOriginY, maxBoundsOriginY));
            bounds.origin.y = constrainedBoundsOriginY + (newBoundsOriginY - constrainedBoundsOriginY) / 2;

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
            // if paging is not enabled or we are outside the bounds - use pop decay animation
            if (! self.pagingEnabled || outsideBounds) {
                POPDecayAnimation *decayAnimation = [POPDecayAnimation animation];
                decayAnimation.property = [self boundsOriginProperty];
                decayAnimation.velocity = [NSValue valueWithCGPoint:velocity];
                [self pop_addAnimation:decayAnimation forKey:@"decelerate"];
                
            // if we just
            } else {
                [self animateToPageWithVelocity:velocity];
            }
        }
            break;

        default:
            break;
    }

}



- (void)animateToPageWithVelocity:(CGPoint)velocity
{
    CGFloat animationDuration = 0.35;
    
    // calculate projected bounds origin
    CGFloat projectedX = self.bounds.origin.x + velocity.x * animationDuration;
    CGFloat projectedY = self.bounds.origin.y + velocity.y * animationDuration;
    
    // check that we don't overshoot with our projected bounds origin coordinates
    projectedX = fmax(0, fmin(projectedX, self.contentSize.width - self.bounds.size.width));
    projectedY = fmax(0, fmin(projectedY, self.contentSize.height - self.bounds.size.height));
    
    // calculate the target number of page
    CGFloat projectedXPageNo = roundf(projectedX / self.bounds.size.width);
    CGFloat projectedYPageNo = roundf(projectedY / self.bounds.size.height);
    
    CGFloat startXPageNo = roundf(self.startBounds.origin.x / self.bounds.size.width);
    CGFloat startYPageNo = roundf(self.startBounds.origin.y / self.bounds.size.height);
    
    // don't allow moving past 1 page at any time
    projectedXPageNo = fmin(startXPageNo + 1, fmax(projectedXPageNo, startXPageNo - 1));
    projectedYPageNo = fmin(startYPageNo + 1, fmax(projectedYPageNo, startYPageNo - 1));
    
    // calc the actual bounds
    CGRect pagedBounds = self.bounds;
    pagedBounds.origin.x = projectedXPageNo * self.bounds.size.width;
    pagedBounds.origin.y = projectedYPageNo * self.bounds.size.height;
    
    [self animateToBounds:pagedBounds
             withVelocity:velocity
                 duration:animationDuration];
}


- (void)animateToBounds:(CGRect)bounds
           withVelocity:(CGPoint)velocity
               duration:(CGFloat)animationDuration
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
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.bounds = bounds;
                     }
                     completion:nil];
    
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
}

@end
