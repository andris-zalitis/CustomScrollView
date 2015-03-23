//
//  DataViewController.h
//  SamplePageBasedProj
//
//  Created by Andris Zalitis on 22/03/15.
//  Copyright (c) 2015 POLLEO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *dataLabel;
@property (strong, nonatomic) id dataObject;

@end

