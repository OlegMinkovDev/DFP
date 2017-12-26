//
//  AdsDelegate.h
//  Ads
//
//  Created by Shai Rotem on 3/30/15.
//  Copyright (c) 2015 startappist. All rights reserved.
//

#ifndef Ads_AdsDelegate_h
#define Ads_AdsDelegate_h


#endif


////////////////


#import <Foundation/Foundation.h>

@class ADPlacementView;

// Protocol for ADPlacementView notifications

@protocol AdsDelegate<NSObject>

@optional

// Notification: Placement ad started loading.
//-(void)adPlacementViewDidStartLoadAd:(ADPlacementView *)adPlacementView;

// Notification: Placement ad failed to load.
// Error code/type is output to debug console
-(void)adPlacementViewDidFailLoadAd:(ADPlacementView *)adPlacementView;

// Notification: Placement ad successfully loaded.
//-(void)adPlacementViewDidLoadAd:(ADPlacementView *)adPlacementView;

// Notification: Ad provided by ADPlacementView will be shown
-(void)adPlacementViewWillShowAd:(ADPlacementView *)adPlacementView;

// Notification: Banner closed
-(void)adPlacementViewDidClose:(ADPlacementView *)adPlacementView;

// Notification: Ad provided by ADPlacementView is shown
//-(void)adPlacementViewDidShowAd:(ADPlacementView *)adPlacementView;

// Notification: Ad provided by ADPlacementView has been tapped
//-(void)adPlacementViewAdHasBeenTapped:(ADPlacementView *)adPlacementView;

// Notification: Ad provided by ADPlacementView will enter modal mode when opening embedded screen view controller
//-(void)adPlacementViewWillEnterModalMode:(ADPlacementView *)adPlacementView;

// Notification: Ad provided by ADPlacementView did leave modal mode
//-(void)adPlacementViewDidLeaveModalMode:(ADPlacementView *)adPlacementView;

// Notification: Ad provided by ADPlacementView causes to leave application to navigate to Safari, iTunes, etc.
//-(void)adPlacementViewWillLeaveApplication:(ADPlacementView *)adPlacementView;

@end

@interface AdsDelegate : NSObject
-(void)adPlacementViewWillShowAd:(ADPlacementView *)adPlacementView;
-(void)adPlacementViewDidFailLoadAd:(ADPlacementView *)adPlacementView;
-(void)adPlacementViewDidClose:(ADPlacementView *)adPlacementView;

@end

