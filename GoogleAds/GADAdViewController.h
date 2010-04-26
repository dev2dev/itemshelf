//
//  GADAdViewController.h
//  Google Ads iPhone publisher SDK.
//  Version: 2.0
//
//  Copyright 2009 Google Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GADAdViewControllerDelegate;

typedef struct {
  NSUInteger width;
  NSUInteger height;
} GADAdSize;

// Supported ad sizes.
static GADAdSize const kGADAdSize320x50 = { 320, 50 };
static GADAdSize const kGADAdSize300x250 = { 300, 250 };

// Ad click actions
typedef enum {
  // Launch the advertiser's website in Safari
  GAD_ACTION_LAUNCH_SAFARI,
  // Display the advertiser's website in the app (as a subview of the window)
  GAD_ACTION_DISPLAY_INTERNAL_WEBSITE_VIEW,
} GADAdClickAction;

///////////////////////////////////////////////////////////////////////////////
// View controller for displaying an ad
///////////////////////////////////////////////////////////////////////////////
@interface GADAdViewController : UIViewController

@property(nonatomic, assign) GADAdSize adSize;  // default: kGADAdSize320x50
@property(nonatomic, assign) id<GADAdViewControllerDelegate> delegate;

// Specify the time (in seconds) for automatic refreshing of the ad.  Set to 0
// or any negative value to disable.  Otherwise, set to 180 or larger (non-zero
// values less than 180 will be increased to 180). The default is 0 (no auto
// refresh).
@property(nonatomic, assign) NSInteger autoRefreshSeconds;

// Initialize with the application delegate
- (id)initWithDelegate:(id<GADAdViewControllerDelegate>)delegate;

// Loads the ad from the Google Ad Server.
// Normally, the ad will display immediately. AdSense for audio ads are not
// displayed until a call to |showLoadedGoogleAd|.
- (void)loadGoogleAd:(NSDictionary *)attributes;

// Shows a loaded ad. Needed only for AdSense for audio ads. Has no effect
// otherwise.
- (void)showLoadedGoogleAd;

// Dismiss the website view
- (void)dismissWebsiteView;

@end

///////////////////////////////////////////////////////////////////////////////
// Delegate for receiving GADAdViewController messages
///////////////////////////////////////////////////////////////////////////////
@protocol GADAdViewControllerDelegate <NSObject>

// It's required to provide the "top" UIViewController of the window where the
// Google Ad view resides as the SDK will present the Website view using the
// UIViewController's presentModalViewController:animated: method.
- (UIViewController *)viewControllerForModalPresentation:
    (GADAdViewController *)adController;

@optional

// Invoked when |loadGoogleAd| succeeds. For AdSense for audio ads, |results|
// will contain a |kGADAdSenseAdDuration| key containing the duration of the ad
// in milliseconds.
- (void)loadSucceeded:(GADAdViewController *)adController
          withResults:(NSDictionary *) results;

// Invoked when |loadGoogleAd| fails.  If loadGoogleAd: is invoked or the
// auto-refresh timer fires when the application is inactive, this method will
// be called with an NSError in the kGADErrorDomain domain.
- (void)loadFailed:(GADAdViewController *)adController
         withError:(NSError *) error;

// |adControllerActionModelForAdClick:| will be called when a user taps on an
// ad. The delegate can override the default behavior (opening in Safari).
- (GADAdClickAction)adControllerActionModelForAdClick:
    (GADAdViewController *)adController;

// Invoked when the website view has been closed.
- (void)adControllerDidCloseWebsiteView:(GADAdViewController *)adController;

// For AdSense for audio ads:
// Invoked when |showLoadedGoogleAd| fails.
- (void)showFailed:(GADAdViewController *)adController
         withError:(NSError *) error;

// For AdSense for audio ads:
// Invoked when |showLoadedGoogleAd| is complete.
- (void)showSucceeded:(GADAdViewController *)adController
          withResults:(NSDictionary *) results;

// DEPRECATED: Use |loadSucceeded:withResults:| instead to be notified when the
// ad load completes.
- (void)adControllerDidFinishLoading:(GADAdViewController *)adController;

// Expandable ad support:
// Invoked just after an expandable ad has expanded.
- (void)adControllerDidExpandAd:(GADAdViewController *)controller;

// Invoked just after an expandable ad has collapsed.
- (void)adControllerDidCollapseAd:(GADAdViewController *)controller;

@end
