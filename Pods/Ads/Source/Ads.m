#import "Ads.h"
#import "AdsDelegate.h"

@interface ADPlacementView() <AdsDelegate>
{
    bool verbose;
    int timerCount;
    UILabel *timerLabel;
    NSTimer * timer1Sec;
    bool bannerClosed;
    CGFloat delayShowBaner;
    bool isCampaignID;
}

@property (nonatomic,strong) UIWebView *myWebView;
@property (nonatomic,strong) NSString *placementKey;
@property (nonatomic,strong) UIButton *closeButton;
@property (nonatomic,assign) float closeTimeout;
@property (strong, nonatomic) UIView* backView;
@property (strong, nonatomic) NSString* cityName;
@property (assign, nonatomic) CGRect rectBanner;
@property (retain, nonatomic) CLLocation* currentLocation;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSURL *adUrl;

@property (strong, nonatomic) NSString* adBannerKey;
@property (strong, nonatomic) NSURL* adBannerUrl;
@property (assign, nonatomic) int adBannerType;
@property (assign, nonatomic) CGRect adBannerRect;
@property (assign, nonatomic) CGRect adBannerCloseRect;
@property (assign, nonatomic) CLLocationCoordinate2D adBannerLocation;
@property (assign, nonatomic) BOOL adBannerSetVerbose;
@property (assign, nonatomic) CGFloat adBannerDelay;
@property (assign, nonatomic) NSInteger adBanerCityIndex;
@property (strong, nonatomic) NSURL *urlShift2mbiz;
@property (strong, nonatomic) NSString *carrierName;
@property (strong, nonatomic) NSString *networkType;
@property (strong, nonatomic) NSString *idfaString;
@property (assign, nonatomic) BOOL isEmptyZonesCount;
@property (assign, nonatomic) NSInteger hours;

@end

#define KEY_CITY_NAME   @"KEY_CITY_NAME"
#define KEY_LATITUDE    @"KEY_LATITUDE"
#define KEY_LONGITUDE   @"KEY_LONGITUDE"
#define KEY_RADIUS      @"KEY_RADIUS"
#define KEY_DATE_EXPIRY @"KEY_DATE_EXPIRY"

@implementation ADPlacementView

-(UIView*)initWithPlacementKey:(NSString *)key
                   adServerUrl:(NSURL*)url
                        adType:(int)type
                 placementRect:(CGRect)rect
               closeButtonRect:(CGRect)closeRect
                   geoLocation:(CLLocationCoordinate2D)location
                    setVerbose:(bool)setVerbose
                         delay:(CGFloat) delay {
    
    self.adBannerKey        = key;
    self.adBannerUrl        = url;
    self.adBannerType       = type;
    self.adBannerRect       = rect;
    self.adBannerCloseRect  = closeRect;
    self.adBannerLocation   = location;
    self.adBannerSetVerbose = setVerbose;
    self.adBannerDelay      = delay;
    
    isCampaignID = false;
    
    delayShowBaner = delay;
    self.currentLocation = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
    
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (!self) {
        [_delegate adPlacementViewDidFailLoadAd:self];
    } else {
        
        UITapGestureRecognizer *tapBack = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBack)];
        [tapBack setNumberOfTapsRequired:1]; // Set your own number here
        [tapBack setDelegate:self]; // Add the <UIGestureRecognizerDelegate> protocol
        [self addGestureRecognizer:tapBack];
        
        verbose = setVerbose;
        if (verbose) [self setBackgroundColor:[UIColor clearColor]];
        
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways]; // Accept cookies
        
        _myWebView = [[UIWebView alloc] initWithFrame:rect];
        _myWebView.layer.borderWidth = 1.0f;
        _myWebView.layer.borderColor = [UIColor blackColor].CGColor;
        _myWebView.scrollView.scrollEnabled = NO;
        _myWebView.tag = 100;
        
        // Set the webView tap recognized. Close banner on tap
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAd)];
        [tap setNumberOfTapsRequired:1]; // Set your own number here
        [tap setDelegate:self]; // Add the <UIGestureRecognizerDelegate> protocol
        [_myWebView addGestureRecognizer:tap];
        
        // Close banner also when user presses the Home button (applicationWillResignActive event)
        // applicationWillEnterForeground
        
        bannerClosed = NO;
        
        if (closeRect.size.height > 0) { // Make the close button
            _closeButton = [[UIButton alloc] initWithFrame:closeRect];
            [_closeButton setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
            [_closeButton setImage:[UIImage imageNamed:@"close.png"] forState:UIControlStateNormal];
            [_closeButton addTarget:self action:@selector(didTapClose) forControlEvents:UIControlEventTouchUpInside];
        }
        
        if (verbose)
            NSLog(@"Library: initWithPlacementKey");
        
        [self GetDeviceInfo];
        [self CheckExpiryDate];
        [self createBanner];
        
    } // self
    
    return self;
    
} // initWithPlacementKey

- (void) CheckExpiryDate {
    
    if (verbose)
        NSLog(@"Library: CheckExpiryDate");

    BOOL isExpiry = false;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    NSMutableArray *dataBase = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"DB"]];
    
    // for mutating object
    for (int i = 0; i < dataBase.count; i++) {
        
        NSArray * tempArray = dataBase[i];
        dataBase[i] = [tempArray mutableCopy];
    }
    
    for (int i = 0; i < [dataBase count]; i++) {
        
        NSDictionary *dict = [dataBase objectAtIndex:i];
        NSString *expiryDate = [dict objectForKey:KEY_DATE_EXPIRY];
        NSString *expiryDay = [expiryDate substringToIndex:2];
        NSString *expiryMonth = [expiryDate substringWithRange:NSMakeRange(3, 2)];
        NSString *expiryYear = [expiryDate substringFromIndex:6];
        
        if ([expiryYear intValue] < [components year])
            isExpiry = true;
        else if ([expiryYear intValue] == [components year]) {
            
            if ([expiryMonth intValue] < [components month])
                isExpiry = true;
            else if ([expiryMonth intValue] == [components month]) {
                
                if ([expiryDay intValue] <= [components day])
                    isExpiry = true;
            }
        }
        
        if (isExpiry) {
            
            if (verbose)
                NSLog(@"Library: object %@ was deleted", [dataBase objectAtIndex:i]);
            
            [dataBase removeObjectAtIndex:i];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:dataBase forKey:@"DB"];
        }
    }
    
    NSDate *now = [NSDate date];
    NSDate *startOfDay = [[NSUserDefaults standardUserDefaults] objectForKey:@"StartOfDay"];
    
    if ([now compare:startOfDay] == NSOrderedDescending )
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Show_BR_Today"];
}

NSString* deviceName()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

- (void) GetDeviceInfo {
    
    if (verbose)
        NSLog(@"Library: GetDeviceInfo");
    
    // get carrier name
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    self.carrierName = [carrier carrierName];
    
    // for my carrier
    if ([[carrier mobileCountryCode] isEqualToString:@"255"] && [[carrier mobileNetworkCode] isEqualToString:@"01"])
        self.carrierName = @"Vodafone";
    
    // get network type
    NSArray *subviews = [[[[UIApplication sharedApplication] valueForKey:@"statusBar"] valueForKey:@"foregroundView"]subviews];
    NSNumber *dataNetworkItemView = nil;
    
    for (id subview in subviews) {
        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
            dataNetworkItemView = subview;
            break;
        }
    }
    
    switch ([[dataNetworkItemView valueForKey:@"dataNetworkType"]integerValue]) {
        case 0:
            if (verbose)
                NSLog(@"Library: No wifi or cellular");
            break;
            
        case 1:
            if (verbose)
                NSLog(@"Library: Network -> 2G");
            break;
            
        case 2:
            if (verbose)
                NSLog(@"Library: Network -> 3G");
            self.networkType = @"3/4G";
            break;
            
        case 3:
            if (verbose)
                NSLog(@"Library: Network -> 4G");
            self.networkType = @"3/4G";
            break;
            
        case 4:
            NSLog(@"LTE");
            break;
            
        case 5:
            if (verbose)
                NSLog(@"Library: Network -> Wifi");
            self.networkType = @"wifi";
            break;
            
        default:
            break;
    }
    
    // get idfa
    self.idfaString = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

- (NSMutableArray *) GetScenario:(int)priority {
    
    if (verbose)
        NSLog(@"Library: GetScenario");
    
    NSMutableArray *scenarioArray = [NSMutableArray array];
    
    if (priority == 0)
        scenarioArray = [NSMutableArray arrayWithObjects:@"Epom", nil];
    
    if (priority == 1000000)
        scenarioArray = [NSMutableArray arrayWithObjects:@"shift2mbiz", nil];
    
    if (priority == 1000)
        scenarioArray = [NSMutableArray arrayWithObjects:@"Epom", @"shift2mbiz", nil];
    
    if (priority == 2000)
        scenarioArray = [NSMutableArray arrayWithObjects:@"shift2mbiz", @"Epom", nil];
    
    if (priority > 1000 && priority <= 1010) {
        
        int epom_count = priority - 1000;
        for (int i = 0; i < epom_count; i++)
            [scenarioArray addObject:@"Epom"];
        
        [scenarioArray addObject:@"shift2mbiz"];
        
        return scenarioArray;
    }
    
    if (priority > 2000 && priority <= 2010) {
        
        int shift2mbiz_count = priority - 2000;
        for (int i = 0; i < shift2mbiz_count; i++)
            [scenarioArray addObject:@"shift2mbiz"];
        
        [scenarioArray addObject:@"Epom"];
        
        return scenarioArray;
    }
    
    if (priority == 3000)
        scenarioArray = [NSMutableArray arrayWithObjects:@"Epom", @"Rest shift2mbiz", nil];
    
    if (priority == 4000)
        scenarioArray = [NSMutableArray arrayWithObjects:@"shift2mbiz", @"Rest epom",  nil];
    
    if (priority > 3000 && priority <= 3010) {
        
        int epom_count = priority - 3000;
        for (int i = 0; i < epom_count; i++)
            [scenarioArray addObject:@"Epom"];
        
        [scenarioArray addObject:@"Rest shift2mbiz"];
        
        return scenarioArray;
    }
    
    if (priority > 4000 && priority <= 4010) {
        
        int shift2mbiz_count = priority - 4000;
        for (int i = 0; i < shift2mbiz_count; i++)
            [scenarioArray addObject:@"shift2mbiz"];
        
        [scenarioArray addObject:@"Rest epom"];
        
        return scenarioArray;
    }
    
    return scenarioArray;
}

- (void) Check_BR {
    
    BOOL showBRToday = [[NSUserDefaults standardUserDefaults] boolForKey:@"Show_BR_Today"];
    
    NSDate *currentDate = [NSDate date];
    NSDate *getConfigDate = [[NSUserDefaults standardUserDefaults] valueForKey:@"getConfigDataSent"];
    _hours = -1;
    
    // get difference between old config date and current date
    if (getConfigDate != nil) {
        
        NSCalendar *gregorian = [[NSCalendar alloc]
                                 initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        
        NSUInteger unitFlags = NSCalendarUnitHour | NSCalendarUnitSecond;
        
        NSDateComponents *components = [gregorian components:unitFlags
                                                    fromDate:getConfigDate
                                                      toDate:currentDate options:0];
        
        _hours = [components hour];
        if (verbose)
            NSLog(@"Library: hours -> %li", (long)_hours);
    }
    
    if (!showBRToday) {
        
        if (_hours == -1 || _hours >= 24) {
         
            
            [self Send_BR_GetConfig];
        }
        
        else {
            
            NSString *supportedNetwork = [[NSUserDefaults standardUserDefaults] valueForKey:@"supported_network"];
            NSArray *supportedCarriers = [[NSUserDefaults standardUserDefaults] valueForKey:@"supported_carrier_list"];
            
            
            
            if ([self.networkType isEqualToString:supportedNetwork] || [supportedNetwork isEqualToString:@"any"]) {
                
                for (NSString *carrier in supportedCarriers) {
                    
                    if ([carrier isEqualToString:self.carrierName] || [carrier isEqualToString:@"any"]) {
                        
                        [self Send_BR_GetAd];
                        return;
                    
                    } else {
                    
                        if (verbose)
                            NSLog(@"Library: carriar is't supported");
                        
                        [self SendEpomRequest];
                    }
                    
                }
            
            } else {
            
                if (verbose)
                    NSLog(@"Library: network is't supported");
                
                [self SendEpomRequest];
            }
        }
    }
}

- (void) createBanner {
    
    if (verbose)
        NSLog(@"Library: createBanner");
    
    NSArray *zoneNames = [ADPlacementView getShift2mCampaignIDsArrayWithCoordinates:self.adBannerLocation];
    NSString *strBR = @"";
    
    NSString * locationTag = @"";
    NSString * endOfRequest = @"&geozone=";
    for (int i = 0; i < [zoneNames count]; i++) {
        
        NSString *name = [zoneNames objectAtIndex:i];
        locationTag = name;
        
        if (i != [zoneNames count] - 1)
            endOfRequest = [endOfRequest stringByAppendingString:[NSString stringWithFormat:@"'%@',", name]];
        else endOfRequest = [endOfRequest stringByAppendingString:[NSString stringWithFormat:@"'%@'", name]];
    }
    
    if ([zoneNames count] == 0) {
        
        if (verbose) {
         
            
            NSLog(@"Library: zoneNames is empty");
        }
        
        self.isEmptyZonesCount = true;
        
        strBR = [NSString stringWithFormat:@"https://shift2m.biz/sdk/advertising/getad?publisher_id=%@&location_tag=%@&carrier_name=%@&os=IOS&device_model=%@&network=%@&idfa=%@", self.adBannerKey, @"", self.carrierName, deviceName(), self.networkType, self.idfaString];
        self.urlShift2mbiz = [NSURL URLWithString:[strBR stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
        [self Check_BR];
        
    } else if ([zoneNames count] != 0) {
        
        
        self.isEmptyZonesCount = false;
        
        NSString *str = [NSString stringWithFormat:@"%@ads-api-v3?key=%@%@&format=json", self.adBannerUrl, self.adBannerKey, endOfRequest];
        self.adUrl = [NSURL URLWithString:[str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        
        strBR = [NSString stringWithFormat:@"https://shift2m.biz/sdk/advertising/getad?publisher_id=%@&location_tag=%@&carrier_name=%@&os=IOS&device_model=%@&network=%@&idfa=%@", self.adBannerKey, locationTag, self.carrierName, deviceName(), self.networkType, self.idfaString];
        self.urlShift2mbiz = [NSURL URLWithString:[strBR stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        
        [self Check_BR];
    }
}

- (void) Send_BR_GetConfig {
    
    // Response getconfig
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://shift2m.biz/sdk/config/getconfig?uid=%@", self.idfaString]]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                
                
                if (verbose)
                    NSLog(@"Library: Send_BR_GetConfig");
                
                if (data == nil) {
                    
                    if (verbose)
                        NSLog(@"Library: data is empty");
                    
                    _hours = -1;
                    [_delegate adPlacementViewDidFailLoadAd:self];
                    return;
                }
                
                NSError *parseError = nil;
                NSDictionary *directory = nil;
                
                if (data != nil)
                    directory = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                
                if (directory == nil) {
                    
                    if (verbose)
                        NSLog(@"Library: The requested resource is not available");
                    
                    _hours = -1;
                    [_delegate adPlacementViewDidFailLoadAd:self];
                    return;
                }
                
                NSDate *now = [NSDate date];
                [[NSUserDefaults standardUserDefaults] setValue:now forKey:@"getConfigDataSent"];
                
                NSString *supportedNetwork = [directory objectForKey:@"supported_network"];
                NSArray *supportedCarriers = [directory objectForKey:@"supported_carrier_list"];
                
                [[NSUserDefaults standardUserDefaults] setValue:supportedNetwork forKey:@"supported_network"];
                [[NSUserDefaults standardUserDefaults] setValue:supportedCarriers forKey:@"supported_carrier_list"];
                
                if ([self.networkType isEqualToString:supportedNetwork] || [supportedNetwork isEqualToString:@"any"]) {
                    
                    for (NSString *carrier in supportedCarriers) {
                        
                        if ([carrier isEqualToString:self.carrierName] || [carrier isEqualToString:@"any"]) {
                            
                            [self Send_BR_GetAd];
                            return;
                        }
                    }
                }
                
                if (verbose)
                    NSLog(@"Warning: Current network or carrier not supported");
                
                // Send request to Epom
                [self SendEpomRequest];
                
            } ] resume];
    
}

- (void) Send_BR_GetAd {
    
    if (verbose)
        NSLog(@"%@", [NSString stringWithFormat:@"Lybrary: BR GetAd Request -> %@", [self.urlShift2mbiz absoluteString]]);
    
    // Response getad
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:self.urlShift2mbiz
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                
                if ([data length] > 0 && error == nil) {
                    
                    // 1. Get priority and status
                    NSError *parseError = nil;
                    NSDictionary *directory = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                    
                    NSString * BR_PRIORITY = [directory objectForKey:@"BR_PRIORITY"];
                    NSString * BR_STATUS = [directory objectForKey:@"BR_STATUS"];
                    
                    if (verbose) {
                        
                        NSLog(@"Lybrary: priority -> %@", BR_PRIORITY);
                        NSLog(@"Lybrary: status -> %@", BR_STATUS);
                        
                    }
                    
                    // Check status
                    if ([BR_STATUS intValue] == 1) { // Don't show BR
                        
                        if (!self.isEmptyZonesCount) {
                            
                            [self SendEpomRequest];
                            return;
                        }
                    }
                    
                    if ([BR_STATUS intValue] == 2) { // Show Epom banner and don't show BR today
                        
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Show_BR_Today"];
                        
                        NSDate *now = [NSDate date];
                        int daysToAdd = 1;
                        NSDate *newDate = [now dateByAddingTimeInterval:60*60*24*daysToAdd];
                        
                        NSDate *startOfDay = [[NSCalendar currentCalendar] startOfDayForDate:newDate];
                        [[NSUserDefaults standardUserDefaults] setObject:startOfDay forKey:@"StartOfDay"];
                        
                        if (!self.isEmptyZonesCount) {
                            
                            [self SendEpomRequest];
                            return;
                        }
                    }
                    
                    // Implementation main logic
                    
                    // 2. Get new scenario and compare this with older scenario
                    NSArray *scenarioArray = [self GetScenario:[BR_PRIORITY intValue]];
                    NSArray *oldScenario = [[NSUserDefaults standardUserDefaults] objectForKey:@"ScenarioArray"];
                    
                    // 3. If scenaries is equal
                    if ([oldScenario isEqualToArray:scenarioArray]) {
                        
                        // 3.1. Increment index
                        NSNumber *index = [[NSUserDefaults standardUserDefaults] objectForKey:@"Index"];
                        
                        int i = [index intValue];
                        if (i < [oldScenario count] - 1)
                            i++;
                        else i = 0;
                        
                        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:i] forKey:@"Index"];
                    
                    } else { // 4. If scenarios is not equal
                        
                        // 4.1. Reset variables
                        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:@"Index"];
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Rest epom"];
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Rest shift2mbiz"];
                    }
                    
                    
                    for ( ; ; ) {
                        
                        BOOL rest_epom = [[NSUserDefaults standardUserDefaults] boolForKey:@"Rest epom"];
                        BOOL rest_shift2mbiz = [[NSUserDefaults standardUserDefaults] boolForKey:@"Rest shift2mbiz"];
                        
                        // 5. If we met word "Rest"
                        if (rest_epom) { // send request to Epom and leave from cycle
                            
                            if (!self.isEmptyZonesCount) {
                                
                                [self SendEpomRequest];
                                return;
                            }
                            
                            break;
                        
                        } else if (rest_shift2mbiz) { // send request to BR and leave from cycle
                            
                            break;
                        }
                        
                        // 6. Get current index
                        int i = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Index"] intValue];
                        
                        // 7. If current server is Epom
                        if ([[scenarioArray objectAtIndex:i] isEqualToString:@"Epom"]) {
                            
                            // 7.1. Save scenario and current index
                            [[NSUserDefaults standardUserDefaults] setObject:scenarioArray forKey:@"ScenarioArray"];
                            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:i] forKey:@"Index"];
                            
                            // 7.2. Send Epom request and leave from current funk
                            if (!self.isEmptyZonesCount) {
                                
                                [self SendEpomRequest];
                                return;
                            }
                            
                            break;
                        }
                        
                        // 8. If current server is BR
                        else if ([[scenarioArray objectAtIndex:i] isEqualToString:@"shift2mbiz"]) {
                            
                            // 8.1. Save scenario and current index and leave from cycle
                            [[NSUserDefaults standardUserDefaults] setObject:scenarioArray forKey:@"ScenarioArray"];
                            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:i] forKey:@"Index"];
                            
                            break;
                        }
                        
                        // 9. If we met word "Rest epom"
                        else if ([[scenarioArray objectAtIndex:i] isEqualToString:@"Rest epom"]) {
                            
                            // 9.1. Save this
                            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Rest epom"];
                            
                            // 9.2. Send Epom request and leave from current funk
                            if (!self.isEmptyZonesCount) {
                                
                                [self SendEpomRequest];
                                return;
                            }
                            
                            break;
                        }
                        
                        // 10. If we met word "Rest shift2mbiz"
                        else if ([[scenarioArray objectAtIndex:i] isEqualToString:@"Rest shift2mbiz"]) {
                            
                            // 10.1. Save this and leave from current cycle
                            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Rest shift2mbiz"];
                            break;
                        }
                    }
                    
                    // Create correct html string and get timer
                    NSString * bannerLink = [directory objectForKey:@"banner_link"];
                    NSString * bannerImage = [directory objectForKey:@"banner_image"];
                    NSString * impressionImage = [directory objectForKey:@"impression_track_url"];
                    NSString * t = [directory objectForKey:@"timer"];
                    
                    timerCount = [t intValue] + delayShowBaner;
                    
                    NSString * htmlString = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@", @"<html><head>\n\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, maximum-scale=1\"></head>\n", @"<body>\n\t<div id=\"place\" style=\" position:fixed; width:100%; height:100%; left:0px; top:0px; background-color: transparent; opacity: 1;\">\n", @"\t\t<div style=\"text-align:center; height:100%; width:100%; position:absolute; left:0px; top:0px; border-collapse: collapse; border:0px; margin:0px; padding:0px;\">\n\t\t", @"<a href=\"", bannerLink, @"\"><img src=\"", bannerImage, @"\"><\a>", @"\n\t</div></div>\n", @"<img src=\"", impressionImage, @"\">", @"\n</body></html>"];
                    
                    NSData *contentData = [htmlString dataUsingEncoding:NSUTF8StringEncoding]; // The HTML content
                    
                    // 11. Load data to _myWebView
                    
                    if (![bannerLink isEqualToString:@""] && ![bannerImage isEqualToString:@""]) {
                    
                        [_myWebView setDelegate:self];
                        [_myWebView loadData:contentData MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:[NSURL URLWithString:@"emptyURL"]];
                    
                    } else {
                        
                        if (verbose)
                            NSLog(@"Lybrary: banner link or banner image is empty");
                            
                        [_delegate adPlacementViewDidClose:self];
                    }
                }
                if (data == nil || error != nil) {
                    
                    if (verbose)
                        NSLog(@"Lybrary: BR_GetAd -> data is empty");
                    
                    if (!self.isEmptyZonesCount)
                        [self SendEpomRequest];
                    else [_delegate adPlacementViewDidClose:self];
                }
                
            }] resume];
}

- (void)SendEpomRequest {
    
    if (verbose)
        NSLog(@"Library: SendEpomRequest -> %@",[self.adUrl absoluteString]);
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:self.adUrl];
    [req setHTTPMethod:@"POST"];
    NSString *post = [NSString stringWithFormat:@""];
    [req setHTTPBody: [post dataUsingEncoding:NSASCIIStringEncoding]];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // Response
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:self.adUrl
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                
                // handle response
                if ([data length] > 0 && error == nil) {
                    
                    NSError *parseError = nil;
                    NSDictionary *directory = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                    NSString *contentString = @"";
                    
                    if (directory[@"CONTENT"]) {
                        
                        if (self.adBannerType == 0) { // Banner
                            
                            NSString *content = directory[@"CONTENT"]; // Extract the HTML code
                            NSRange r1 = [content rangeOfString:@"Time to close <span>"];
                            
                            if (r1.location == NSNotFound) {
                                
                                //if (verbose) NSLog(@"String |Time to close | was not found");
                                [_delegate adPlacementViewDidFailLoadAd:self];
                                
                            } else { // Found timer value
                            
                                NSString *t = [content substringWithRange:NSMakeRange(r1.location+20,2)];
                                if ([[t substringFromIndex:1] isEqualToString:@"<"])
                                    t = [t substringToIndex:1];
                                timerCount = [t intValue] + delayShowBaner;
                            }
                            
                            // Fix the bug in the HTML code - place the ad at the top left
                            NSString *margin = [NSString stringWithFormat:@"<meta name=\"viewport\" content=\"width=device-width, user-scalable=no\">\n<style>* {margin: 0; padding: 0; border: 0;}</style>\n"];
                            contentString = [margin stringByAppendingString:directory[@"CONTENT"]]; // Extract the HTML code
                            
                        } else { // Interstitial
                            
                            NSString *content = directory[@"CONTENT"]; // Extract the HTML code
                            // Extract time from "Time to close <span>20</span>"
                            //NSRange r1 = [content rangeOfString:@"Time to close <span>20</span>"];
                            NSRange r1 = [content rangeOfString:@"Time to close <span>"];
                            
                            if (r1.location == NSNotFound) {
                                
                                //if (verbose) NSLog(@"String |Time to close | was not found");
                                [_delegate adPlacementViewDidFailLoadAd:self];
                                
                            } else { // Found timer value
                                
                                timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.adBannerRect.size.height-15, self.adBannerRect.size.width, 15)];
                                timerLabel.textAlignment = NSTextAlignmentCenter;
                                
                                NSString *cs = [content stringByReplacingOccurrencesOfString:@"\n" withString:@""]; // Remove all "\n"
                                NSError *error = nil;
                                // Find <a href=\"http://n129adserv.com/cr?b=59&p=204&ch=&cps=&c=5&l=IL&h=86034869af30bb28a4dd14c505a12ae3&t=1425451696186&u=http://one.co.il\" target=\"_block\"><img src=\"http://wac.A164.edgecastcdn.net/80A164/n129-cdn/files129/4/5/59/t/402/320x480.png\"
                                // Then find: </script><img src=\"http://n129adserv.com/impression.gif?b=59&p=204&ch=&ap=&cps=&c=5&l=IL&h=86034869af30bb28a4dd14c505a12ae3&t=1425451696187&s=1b119e18cbed99546c1a8f1d75fc197b\"
                                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".+href=([^\\s]+)[\\s]+target=\"_block\"><img src=([^\\s]+).+</script><img src=([^\\s]+).+" options:NSRegularExpressionCaseInsensitive error:&error];
                                
                                // NSString *margin = [NSString stringWithFormat:@"<meta name=\"viewport\" content=\"width=device-width, user-scalable=no\">\n<style>* {margin: 0; padding: 0; border: 0;}</style>\n"];
                                // contentString = [margin stringByAppendingString:directory[@"CONTENT"]]; // Extract the HTML code
                                
                                NSString *s1 = @"<html>\n<head>\n<meta name=""viewport"" content=""width=device-width, initial-scale=1, maximum-scale=1"">\n</head>\n<body>\n<div id=""place"" style="" position:fixed; width:100%; height:100%; left:0px; top:0px; background:#fff; opacity: 1;"">\n<div style=""text-align:center; height:100%; width:100%; position:absolute; left:0px; top:0px; border-collapse: collapse; border:0px; margin:0px; padding:0px;"">\n<a href="""; // $1 here (click Href)
                                NSString *s2 = @""" target=""_block"">\n<img src="""; // $2 here (image source)
                                NSString *s3 = @""" alt="" />\n</a>\n</div>\n</div>\n<img src="""; // $3 here (impression gif image source)
                                NSString *s4 = @""" alt="" style=""width:1px; height:1px; position:absolute; left:-10000px""/>\n</body>\n</html>";
                                contentString = [regex stringByReplacingMatchesInString:cs options:0 range:NSMakeRange(0, [cs length]) withTemplate:[NSString stringWithFormat:@"%@$1%@$2%@$3%@",s1,s2,s3,s4]];
                                //NSLog(@"script:\n%@",script);
                                
                            } // Found timer value
                        } // Interstitial
                        
                        if (contentString) {
                            
                            NSData *contentData = [contentString dataUsingEncoding:NSUTF8StringEncoding]; // The HTML content
                            
                            [_myWebView setDelegate:self];
                            [_myWebView loadData:contentData MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:[NSURL URLWithString:@"emptyURL"]];
                            
                            //[_myWebView loadHTMLString:testHTML baseURL:[NSURL URLWithString:@"emptyURL"]];
                            //if (verbose) NSLog(@"Library: _myWebView load initiated");
                            
                        } else {
                            
                            //if (verbose) NSLog(@"Library: empty contentString");
                            [_delegate adPlacementViewDidFailLoadAd:self];
                        }
                        
                    } else {
                        
                        //if (verbose) NSLog(@"Library: empty directory[CONTENT]");
                        [_delegate adPlacementViewDidFailLoadAd:self];
                    }
                }
                
                else if ([data length] == 0 && error == nil) {
                    
                    if (verbose)
                        NSLog(@"Library: no data returned");
                    
                    [_delegate adPlacementViewDidFailLoadAd:self];
                }
                else if (error != nil)
                {
                    if (verbose)
                        NSLog(@"Library: there was a download error: %@", error);
        
                    if (verbose)
                        NSLog(@"Library: Ad failed to load");
                    
                    [_delegate adPlacementViewDidFailLoadAd:self];
                }
                
            }] resume];
}

- (void)tapBack {
    [self closeBanner:YES];
}
- (void)closeBanner:(bool)notify
{
    if (verbose)
        NSLog(@"Library: close banner. bannerClosed: %d",bannerClosed);
    
    if (bannerClosed) return;
    bannerClosed = YES;
    [self removeFromSuperview];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (notify) [_delegate adPlacementViewDidClose:self];
} // closeBanner

- (void)handleTimer
{
    if (timerCount == 0) {
        [self closeBanner:YES];
        [timer1Sec invalidate];
        timer1Sec = nil;
        return;
    }
    timerCount--;
    timerLabel.text = [NSString stringWithFormat:@"Time to close: 00:%s%d",(timerCount < 10 ? "0" : ""),timerCount];
} // handleTimer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

-(void) didTapAd
{
    //if (verbose) NSLog(@"Library: didTapAd");
    [self closeBanner:NO];
}

-(void) didTapClose
{
    //if (verbose) NSLog(@"Library: didTapClose");
    [timer1Sec invalidate];
    [self closeBanner:YES];
}

#pragma mark UIWebViewDelegate Methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *u = [request.URL absoluteString];
    //if (verbose) NSLog(@"Library: shouldStartLoadWithRequest: URL: %@, bannerClosed: %d",u,bannerClosed);
    
    // Open URL in browser if it starts with "http"
    if ([[u substringToIndex:4] isEqualToString:@"http"]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        [self closeBanner:YES];
    }
    return ([u rangeOfString:@"emptyURL"].location != NSNotFound); // Load only the first time content into the webView
}


//This function will be called just after the webview starts loading the request
- (void)webViewDidStartLoad:(UIWebView *)webView {
    //if (verbose) NSLog(@"Library: webViewDidStartLoad");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

//This function will be called when the webview finishes loading the request
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    NSString *padding = @"document.body.style.margin='0';document.body.style.padding = '0'";
    [webView stringByEvaluatingJavaScriptFromString:padding];
    //if (verbose) NSLog(@"Library: webViewDidFinishLoad");
    if (bannerClosed) return;
    
    // Add the webView, button and timerLabel and call the delegate's adPlacementViewWillShowAd
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self addSubview:webView];
    if (_closeButton) [webView addSubview:_closeButton];
    
    timer1Sec = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(handleTimer) userInfo:nil repeats:YES];
    [self handleTimer];
    
    // if type strip or interstitial banner not shown
    if (self.adBannerType == 0/* && !isCampaignID*/)
        [_delegate adPlacementViewWillShowAd:self];
    
    [self adPlacementViewWillShowAd:self];
}



-(void)webview:(UIWebView *)webview didFailLoadWithError:(NSError *)error {
    // NSLog(@"Library: Failed to load webViewwith error:\nlocalizedDescription: %@\ndebugDescription: %@",[error localizedDescription],[error debugDescription]);
    
    [_delegate adPlacementViewDidFailLoadAd:self];
}

-(void) adPlacementViewWillShowAd:(ADPlacementView *)adPlacementView {
    
    CGRect frameOrigin ;
    UIView* viewWeb;
    
    for (UIView* view in [adPlacementView subviews]) {
        
        if (view.tag == 100) {
            frameOrigin = view.frame;
            viewWeb = view;
        }
    }
    
    CGRect frameStart = frameOrigin;
    frameStart.origin.y = -frameOrigin.size.height;
    
    viewWeb.frame = frameStart;
    
    CGRect f = frameOrigin;
    f.origin.y -= 70;
    
    [UIView animateWithDuration:0.5
                          delay:delayShowBaner
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         viewWeb.frame = frameOrigin;
                         adPlacementView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.55f];
                         
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:.2 delay:0.0
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              viewWeb.frame = f;
                                          }
                                          completion:^(BOOL finished) {
                                              
                                              [UIView animateWithDuration:.2 delay:0.0
                                                                  options:UIViewAnimationOptionCurveEaseIn
                                                               animations:^{
                                                                   viewWeb.frame = frameOrigin;
                                                               }
                                                               completion:^(BOOL finished) {
                                                                   
                                                               }];
                                          }];
                     }];
}

+ (NSArray*)getShift2mCampaignIDsArrayWithCoordinates:(CLLocationCoordinate2D)geoLocation {
    
    CLLocation* currentLocation = [[CLLocation alloc] initWithLatitude:geoLocation.latitude longitude:geoLocation.longitude];
    NSArray *shift2mDataBase = [[NSUserDefaults standardUserDefaults] objectForKey:@"DB"];
    NSMutableArray *campaignIdsArr = [NSMutableArray array];
    
    if (shift2mDataBase != nil) {
        
        for (NSDictionary* dict in shift2mDataBase) {
            
            CLLocation *dataBaseLoc = [[CLLocation alloc] initWithLatitude:[[dict objectForKey:KEY_LATITUDE] doubleValue] longitude:[[dict objectForKey:KEY_LONGITUDE] doubleValue]];
            CLLocationDistance meters = [dataBaseLoc distanceFromLocation:currentLocation];
            CGFloat distance = meters/1000;
            CGFloat radius = [[dict objectForKey:KEY_RADIUS] floatValue];
            
            if (distance <= (radius / 1000))
                [campaignIdsArr addObject:[dict objectForKey:KEY_CITY_NAME]];
        }
    }
    
    return campaignIdsArr;
}

@end
