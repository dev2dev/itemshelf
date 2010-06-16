// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
//
//  AdCell.h
//

#import <UIKit/UIKit.h>

#import "GADAdViewController.h"
#import "GADAdSenseParameters.h"

#define AFMA_CLIENT_ID  @"ca-mb-app-pub-4621925249922081"
#define AFMA_APPID @"GUJYY5S9D5" // ItemShelf Lite

#define AFMA_CHANNEL_IDS @"3548046115"
#define AFMA_CHANNEL_IDS_IPAD @"6436993045"
#define AFMA_KEYWORDS  @"本,書籍,コミック,CD,DVD,book,comics" // shopping
#define AFMA_IS_TEST 0

@interface AdCell : UITableViewCell <GADAdViewControllerDelegate> {
    GADAdViewController *adViewController;
    UIViewController *parentViewController;
}

@property(nonatomic,assign) UIViewController *parentViewController;

+ (AdCell *)adCell:(UITableView *)tableView parentViewController:(UIViewController *)parentViewController;
+ (CGFloat)adCellHeight;

+ (NSDictionary *)adAttributes;

@end
