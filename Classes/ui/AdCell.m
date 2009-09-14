// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
//
// AdCell.m
//

// Note:
//   AdMob : size = 320x48
//   TG ad : size = 320x60

#import "AdCell.h"

@implementation AdMobDelegate

+ (AdMobDelegate*)getInstance
{
    static AdMobDelegate *theInstance = nil;
    if (theInstance == nil) {
        theInstance = [[AdMobDelegate alloc] init];
    }
    return theInstance;
}

- (NSString*)publisherId
{
    return ADMOB_ID;
}

- (BOOL)useTestAd {
    return NO;
    //return YES;
}

- (void)didReceiveAd:(AdMobView *)adView {
    NSLog(@"AdMob:didReceiveAd");
}

- (void)didFailToReceiveAd:(AdMobView *)adView {
    NSLog(@"AdMob:didFailToReceiveAd");
}

@end

/////////////////////////////////////////////////////////////////////
// AdCell

@implementation AdCell

@synthesize adMobView;

+ (CGFloat)adCellHeight
{
    return 48; // admob
}

+ (AdCell *)adCell:(UITableView *)tableView
{
    NSString *identifier = @"AdCell";

    AdCell *cell = (AdCell*)[tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[[AdCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    }
    return cell;
}

- (UITableViewCell *)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier
{
    self = [super initWithStyle:style reuseIdentifier:identifier];
    if (self) {
        self.textLabel.text = @"Advertisement space";
        self.textLabel.textAlignment = UITextAlignmentCenter;
        self.textLabel.textColor = [UIColor grayColor];
    
        // AdMob
        AdMobDelegate *amd = [AdMobDelegate getInstance];
        self.adMobView = [AdMobView requestAdWithDelegate:amd];
        [self.contentView addSubview:self.adMobView];
    }

    return self;
}

- (void)dealloc {
    self.adMobView = nil;
    [super dealloc];
}

- (void)refreshAd
{
    [self.adMobView requestFreshAd];
}

@end
