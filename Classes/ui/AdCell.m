// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
//
// AdCell.m
//

// Note:
//   AdSense : size = 320x50

#import "AdCell.h"

/////////////////////////////////////////////////////////////////////
// AdCell

@implementation AdCell

@synthesize parentViewController;

+ (CGFloat)adCellHeight
{
    return 50; // AdSense
}

+ (AdCell *)adCell:(UITableView *)tableView parentViewController:(UIViewController *)parentViewController
{
    NSString *identifier = @"AdCell";

    AdCell *cell = (AdCell*)[tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[[AdCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    }
    cell.parentViewController = parentViewController;

    return cell;
}

+ (NSDictionary *)adAttributes
{
    NSDictionary *attributes = 
        [NSDictionary dictionaryWithObjectsAndKeys:
         AFMA_CLIENT_ID, kGADAdSenseClientID,
         @"Takuya Murakami", kGADAdSenseCompanyName,
         @"CashFlow Free", kGADAdSenseAppName,
         AFMA_KEYWORDS, kGADAdSenseKeywords,
         [NSArray arrayWithObjects:AFMA_CHANNEL_IDS, nil], kGADAdSenseChannelIDs,
         [NSNumber numberWithInt:AFMA_IS_TEST], kGADAdSenseIsTestAdRequest,

         [UIColor brownColor], kGADAdSenseAdBackgroundColor,
         //[UIColor whiteColor], kGADAdSenseAdBackgroundColor,
         //[UIColor colorWithRed:153/255.0 green:169/255.0 blue:190/256.0 alpha:0], kGADAdSenseAdBackgroundColor,
         //[UIColor colorWithRed:129/255.0 green:149/255.0 blue:175/256.0 alpha:0], kGADAdSenseAdBackgroundColor,
         //[UIColor darkGrayColor], kGADAdSenseAdBackgroundColor,

         //[UIColor lightGrayColor], kGADAdSenseAdBorderColor,
         
         //[UIColor blackColor], kGADAdSenseAdTextColor,
         //[UIColor colorWithRed:0.0 green:0.0 blue:0.5 alpha:0], kGADAdSenseAdTextColor,
          
         //[UIColor colorWithRed:0.0 green:0.0 blue:0.5 alpha:0], kGADAdSenseAdLinkColor,
         //[UIColor colorWithRed:0.0 green:0.4 blue:0.0 alpha:0], kGADAdSenseAdURLColor,
         nil];
    return attributes;
}

- (UITableViewCell *)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier
{
    self = [super initWithStyle:style reuseIdentifier:identifier];

    // 広告を作成する
    adViewController= [[GADAdViewController alloc] initWithDelegate:self];
    adViewController.adSize = kGADAdSize320x50;
    
    NSDictionary *attributes = [AdCell adAttributes];
    [adViewController loadGoogleAd:attributes];
    
    UIView *v = adViewController.view;
    CGRect frame = v.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    v.frame = frame;
    [self.contentView addSubview:v];

    return self;
}

- (void)dealloc {
    [adViewController release];
    [super dealloc];
}


#pragma mark GADAdViewControllerDelegate

- (UIViewController *)viewControllerForModalPresentation:(GADAdViewController *)adController
{
    return self.parentViewController;
}

- (GADAdClickAction)adControllerActionModelForAdClick:(GADAdViewController *)adController
{
    return GAD_ACTION_DISPLAY_INTERNAL_WEBSITE_VIEW;
}

@end
