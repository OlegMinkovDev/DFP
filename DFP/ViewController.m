//
//  ViewController.m
//  DFP
//
//  Created by Admin on 27.10.15.
//  Copyright © 2015 Minkov Inc. All rights reserved.
//

#import "ViewController.h"

#define KEY_CITY_NAME   @"KEY_CITY_NAME"
#define KEY_LATITUDE    @"KEY_LATITUDE"
#define KEY_LONGITUDE   @"KEY_LONGITUDE"
#define KEY_RADIUS      @"KEY_RADIUS"
#define KEY_DATE_EXPIRY @"KEY_DATE_EXPIRY"

@interface ViewController () <UIGestureRecognizerDelegate, UITextFieldDelegate>
{
    ADPlacementView *adMobPlacementView;
    UITextField *latTF;
    UITextField *lonTF;
    CLLocationManager *locationManager;
    NSData *jsonData;
}

@property (nonatomic,strong) UIButton *bannerButton;
@property (assign, nonatomic) CGFloat latValue;
@property (assign, nonatomic) CGFloat lonValue;
@property (strong, nonatomic) NSString *latitude;
@property (strong, nonatomic) NSString *longitude;

@end

@implementation ViewController

@synthesize latitudeLabel;
@synthesize longitudeLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    
    self.latValue = 33.0300;
    self.lonValue = 35.2569;
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(20, 30, CGRectGetWidth(self.view.frame) - 20, 30)];
    label.font = [UIFont systemFontOfSize:28];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"APP EXAMPLE";
    [self.view addSubview:label];
    
    latTF = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame) - 140, CGRectGetMaxY(label.frame) + 20, 130, 30)];
    latTF.placeholder = @"Latitude";
    latTF.delegate = self;
    latTF.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    latTF.backgroundColor = [UIColor whiteColor];
    latTF.layer.cornerRadius = 10;
    latTF.tag = 0;
    latTF.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:latTF];
    
    lonTF = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame) + 10, CGRectGetMaxY(label.frame) + 20, 130, 30)];
    lonTF.placeholder = @"Longitude";
    lonTF.delegate = self;
    lonTF.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    lonTF.backgroundColor = [UIColor whiteColor];
    lonTF.layer.cornerRadius = 10;
    lonTF.tag = 1;
    lonTF.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:lonTF];
    
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame) - 100, CGRectGetMidY(self.view.frame) - 100, 200, 80)];
    [button setTitle:@"Create Banner" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClick) forControlEvents:UIControlEventTouchUpInside];
    [button.layer setBorderWidth:1.0f];
    [button.layer setBorderColor:[UIColor blackColor].CGColor];
    [button.layer setCornerRadius:10];
    [self.view addSubview:button];
    
    NSLog(@"adPlacementView");
}

-(void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation *currentLocation = [locations lastObject];
    
    latitudeLabel.text = [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude];
    longitudeLabel.text = [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude];
}

- (void)buttonClick {
    
    [self createBanner];
}

- (void) createBanner {
    
    // Close banner also when user presses the Home button (applicationWillResignActive event)
    
    NSLog(@"\r\n ******************** CREATE BANNER ******************** \r\n");
    
    // *************************************
    //[[[UIAlertView alloc] initWithTitle:@"Message" message:@"[App]: Click Create Button" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    NSLog(@"[App](1): Click Create Button");
    // *************************************
    
    if (latTF.text.length == 0 && lonTF.text.length == 0) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Please input coordinate (Latitude, Longtitude)" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil]show];
    } else {
        
        CGFloat lat = [latTF.text floatValue];
        CGFloat lon = [lonTF.text floatValue];
        if (!adMobPlacementView) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(willResign)
                                                         name:UIApplicationWillResignActiveNotification
                                                       object:NULL];
            
            NSURL *adsServerUrl = [NSURL URLWithString: [NSString stringWithFormat:@"http://www.shift2m.net/"]];
            CGRect placementRect = CGRectMake(CGRectGetMidX(self.view.frame) - 300/2, CGRectGetMidY(self.view.frame) - 250/2, 300, 250); // For interstitial: CGRectMake(0.0, 20.0, 320, 480.0);
            CGRect closeRect = CGRectMake(0.0, 0.0, 25.0, 25.0);
            CLLocationCoordinate2D geoLocation = CLLocationCoordinate2DMake(lat, lon); // No location support 32.162413, 34.84467  32.1, 34.8
            int type = 0; // 0: banner, 1: interstitial, 2: strip
            
            /*adMobPlacementView = [[ADPlacementView alloc]                                                                                        initWithPlacementKey:@"82cb1c0fa7a36c125a0ebb795dd71326"
                                                                                                                                                          adServerUrl:adsServerUrl
                                                                                                                                                               adType:type
                                                                                                                                                        placementRect:placementRect
                                                                                                                                                      closeButtonRect:closeRect
                                                                                                                                                          geoLocation:geoLocation
                                                                                                                                                           setVerbose:YES
                                                                                                                                                                delay:10];
            
            
            adMobPlacementView.delegate = self;*/
            
            NSArray *array = [ADPlacementView getShift2mCampaignIDsArrayWithCoordinates:geoLocation];
            
            // check whether there are the coordinates in the database
            if ([array count] == 0) {
                
                [adMobPlacementView removeFromSuperview];
                adMobPlacementView = nil;
            }
        }
    }
}

-(void) willResign {
    
    //NSLog(@"TestApp: willResign");
    
    [adMobPlacementView removeFromSuperview];
    adMobPlacementView = nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
}

// Notification: Ad provided by ADPlacementView will be shown
-(void)adPlacementViewWillShowAd:(ADPlacementView *)adPlacementView1 {
    
    NSLog(@"TestApp: ADPlacementView will show ad");
    [self.view addSubview:adPlacementView1];
}

// Notification: Placement ad failed to load.
// Error code/type is output to debug console
-(void)adPlacementViewDidFailLoadAd:(ADPlacementView *)adPlacementView {
    
    NSLog(@"TestApp: ADPlacementView fail load");
    
    [adMobPlacementView removeFromSuperview];
    adMobPlacementView = nil;
}

// Notification: Banner closed
-(void)adPlacementViewDidClose:(ADPlacementView *)placementView {
    
    //NSLog(@"TestApp: adPlacementViewDidClose");
    
    adMobPlacementView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (BOOL)shouldAutorotate {
    
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [latTF resignFirstResponder];
    [lonTF resignFirstResponder];
    
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
