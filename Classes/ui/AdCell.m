// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
//
// AdCell.m
//

// Note:
//   AdSense : size = 320x50

#import "AdCell.h"
#import "Common.h"

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
         @"ItemShelf Lite", kGADAdSenseAppName,
         AFMA_KEYWORDS, kGADAdSenseKeywords,
         [NSNumber numberWithInt:AFMA_IS_TEST], kGADAdSenseIsTestAdRequest,
         nil];

    NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
    [md setDictionary:attributes];
    
    if (!IS_IPAD) {
        [md setObject:[NSArray arrayWithObjects:AFMA_CHANNEL_IDS, nil] forKey:kGADAdSenseChannelIDs];
        //[md setObject:[UIColor colorWithRed:175/255.0 green:140/255.0 blue:105/256.0 alpha:0.0] forKey:kGADAdSenseAdBackgroundColor];
        [md setObject:[UIColor whiteColor] forKey:kGADAdSenseAdBackgroundColor];         
    } else {
        [md setObject:[NSArray arrayWithObjects:AFMA_CHANNEL_IDS_IPAD, nil] forKey:kGADAdSenseChannelIDs];
        [md setObject:[UIColor whiteColor] forKey:kGADAdSenseAdBackgroundColor];         
    }
        //[UIColor brownColor], kGADAdSenseAdBackgroundColor,
        //[UIColor colorWithRed:235/255.0 green:205/255.0 blue:180/256.0 alpha:0], kGADAdSenseAdBackgroundColor,
        //[UIColor colorWithRed:185/255.0 green:145/255.0 blue:113/256.0 alpha:0], kGADAdSenseAdBackgroundColor,

        //[UIColor darkGrayColor], kGADAdSenseAdBackgroundColor,

        //[UIColor lightGrayColor], kGADAdSenseAdBorderColor,
         
        //[UIColor blackColor], kGADAdSenseAdTextColor,
        //[UIColor colorWithRed:0.0 green:0.0 blue:0.5 alpha:0], kGADAdSenseAdTextColor,
          
        //[UIColor colorWithRed:0.0 green:0.0 blue:0.5 alpha:0], kGADAdSenseAdLinkColor,
        //[UIColor colorWithRed:0.0 green:0.4 blue:0.0 alpha:0], kGADAdSenseAdURLColor,

    return md;
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
    frame.origin.x = (self.frame.size.width - frame.size.width) / 2;
    frame.origin.y = 0;
    v.frame = frame;
    v.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
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
