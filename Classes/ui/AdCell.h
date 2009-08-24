// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
//
//  AdCell.h
//

#import <UIKit/UIKit.h>

#import "AdMobDelegateProtocol.h"
#import "AdMobView.h"

#define ADMOB_ID @"a14a925cd4c5c5f" // ItemShelf Lite

@interface AdMobDelegate : NSObject <AdMobDelegate> {
}
@end

@interface AdCell : UITableViewCell {
    AdMobView *adMobView;
}

@property(nonatomic,retain) AdMobView *adMobView;

+ (AdCell *)adCell:(UITableView *)tableView;
+ (CGFloat)adCellHeight;
- (void)refreshAd;

@end
