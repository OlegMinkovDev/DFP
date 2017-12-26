#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdsDelegate.h"
#import <CoreLocation/CoreLocation.h> 

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#import <sys/utsname.h>

#import <AdSupport/ASIdentifierManager.h>

@class ADPlacementView;

@interface ADPlacementView : UIView<UIWebViewDelegate, UIGestureRecognizerDelegate>

// delegate accessor
@property (readwrite, assign) id<AdsDelegate> delegate;

- (UIView *)initWithPlacementKey:(NSString *)key
                    adServerUrl:(NSURL*)url
                         adType:(int)type
                  placementRect:(CGRect)rect
                closeButtonRect:(CGRect)closeRect
                    geoLocation:(CLLocationCoordinate2D)location
                     setVerbose:(bool)setVerbose
                          delay:(CGFloat) delay;

+ (NSArray*)getShift2mCampaignIDsArrayWithCoordinates:(CLLocationCoordinate2D)geoLocation;

@end
