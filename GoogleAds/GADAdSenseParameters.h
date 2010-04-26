//
//  GADAdSenseParameters.h
//  Google Ads iPhone publisher SDK.
//
//  Copyright 2009 Google Inc. All rights reserved.
//

// AdSense ad types
extern NSString* const kGADAdSenseTextAdType;
extern NSString* const kGADAdSenseImageAdType;
extern NSString* const kGADAdSenseTextImageAdType;

///////////////////////////////////////////////////////////////////////////////
// AdSense ad attributes
///////////////////////////////////////////////////////////////////////////////

// Google AdSense client ID (required).
extern NSString* const kGADAdSenseClientID;

// Your company name (required).
extern NSString* const kGADAdSenseCompanyName;

// Your application name (required).
extern NSString* const kGADAdSenseAppName;

// Keywords to target the ad. Defaults to none. Use "," to separate multiple
// keywords and "+" to separate multiple words in a phrase, e.g.
// "car+insurance,car+loans".
extern NSString* const kGADAdSenseKeywords;

// If your application content is loaded from iPhone-customized webpage content,
// set kGADAdSenseAppWebContentURL to the iPhone-customized web content URL.
extern NSString* const kGADAdSenseAppWebContentURL;  // NSURL

// Channel IDs. Channels are optional but strongly recommended. Specify up to
// five custom channels to track the performance of this ad unit.
extern NSString* const kGADAdSenseChannelIDs;  // NSArray of NSStrings

// Indicates whether this is a test ad request. Defaults to 1. When you are
// done testing, contact us so that we can review your test app. If everything
// looks good, then you can set to 0.
extern NSString* const kGADAdSenseIsTestAdRequest;  // NSNumber

// Ad type is text or image (default is kGADAdSenseTextImageAdType)
extern NSString* const kGADAdSenseAdType;

// When doing 3-way rev-sharing, this is the ID of the host (aggregator).
// This is only applicable to publishers that share their revenue with someone
// else like content providers.
extern NSString* const kGADAdSenseHostID;

// The default background color of the ad is 000000.
extern NSString* const kGADAdSenseAdBackgroundColor;  // UIColor

// The default border color of the ad is 000000.
extern NSString* const kGADAdSenseAdBorderColor;  // UIColor

// The default color of the hyperlinked title of the ad is FFFFFF.
extern NSString* const kGADAdSenseAdLinkColor;  // UIColor

// The default color of the ad description is FFFFFF.
extern NSString* const kGADAdSenseAdTextColor;  // UIColor

// The default color of the ad url is 33FF33.
extern NSString* const kGADAdSenseAdURLColor;  // UIColor

// The direction that expandable ads should grow.  If you don't want to support
// expandable ads, do not set this attribute.  Allowed values "b" or "t" which
// indicate that the growth should be towards the bottom or top of the screen,
// respectively.
extern NSString* const kGADExpandDirection;  // NSString

// When there are no relevant Google ads to show, Google displays public service
// ads. You can override this behavior by setting kGADAdsenseAlternateAdColor
// to a color that is used to fill in the ad slot, or kGADAdSenseAlternateAdURL
// to a URL that shows non-Google ads.
extern NSString* const kGADAdSenseAlternateAdColor;  // UIColor
extern NSString* const kGADAdSenseAlternateAdURL;  // NSURL

// The following key is returned in the dictionary parameter in
// |loadFailed:withResults:| and |showFailed:withResults:|. The associated
// object contains an error description as an |NSString|.
extern NSString* const kGADAdSenseError;
