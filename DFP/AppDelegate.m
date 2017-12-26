//
//  AppDelegate.m
//  DFP
//
//  Created by Admin on 27.10.15.
//  Copyright © 2015 Minkov Inc. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // init plot
    [Plot initializeWithLaunchOptions:launchOptions delegate:self];
    
    return YES;
}

// method which the triggers come and add to database
-(void)plotHandleGeotriggers:(PlotHandleGeotriggers*)geotriggerHandler {
    
    // *************************************
    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"[Delegate](1): Trigger recieved" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    //[alert show];
    NSLog(@"[Delegate]: Trigger recieved");
    // *************************************
    
    NSMutableArray *dataArray = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"DB"]];
    BOOL flag = false;
    
    // for mutating object
    for (int i = 0; i < dataArray.count; i++) {
        
        NSArray * tempArray = dataArray[i];
        dataArray[i] = [tempArray mutableCopy];
    }
    
    for (PlotGeotrigger* geotrigger in geotriggerHandler.geotriggers) {
        
        // whether the database contains the trigger
        for (int i = 0; i < [dataArray count]; i++) {
            
            NSMutableDictionary *loadDict = [dataArray objectAtIndex:i];
            
            if ([[loadDict objectForKey:@"KEY_CITY_NAME"] isEqualToString:[geotrigger.userInfo objectForKey:PlotGeotriggerName]]) {
                
                flag = true;
                break;
            }
        }
        
        // if not => add to database
        if (!flag) {
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            
            // get radius and date
            NSString *str = [geotrigger.userInfo objectForKey:PlotGeotriggerDataKey];
            NSString *radius = [str substringFromIndex:11];
            NSString *date = [str substringToIndex:10];
            
            [dict setObject:[geotrigger.userInfo objectForKey:PlotGeotriggerName] forKey:@"KEY_CITY_NAME"];
            [dict setObject:[geotrigger.userInfo objectForKey:PlotGeotriggerGeofenceLatitude] forKey:@"KEY_LATITUDE"];
            [dict setObject:[geotrigger.userInfo objectForKey:PlotGeotriggerGeofenceLongitude] forKey:@"KEY_LONGITUDE"];
            [dict setObject:radius forKey:@"KEY_RADIUS"];
            [dict setObject:date forKey:@"KEY_DATE_EXPIRY"];
            
            [dataArray addObject:dict];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:dataArray forKey:@"DB"];
            
            // *************************************
            //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message" message:[NSString stringWithFormat:@"[Delegate]: %@ was added", [geotrigger.userInfo objectForKey:PlotGeotriggerName]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            //[alert show];
            NSLog(@"%@", [NSString stringWithFormat:@"[Delegate](2): %@ was added", [geotrigger.userInfo objectForKey:PlotGeotriggerName]]);
            // *************************************
            
        }
        
        flag = false;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
