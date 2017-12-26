//
//  ViewController.h
//  DFP
//
//  Created by Admin on 27.10.15.
//  Copyright © 2015 Minkov Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Ads/Ads.h>
#import <Ads/AdsDelegate.h>

@interface ViewController : UIViewController <AdsDelegate, CLLocationManagerDelegate>

@property (retain, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (retain, nonatomic) IBOutlet UILabel *longitudeLabel;

@end

