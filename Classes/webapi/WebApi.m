// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
/*
  ItemShelf for iPhone/iPod touch

  Copyright (c) 2008, ItemShelf Development Team. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer. 

  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution. 

  3. Neither the name of the project nor the names of its contributors
  may be used to endorse or promote products derived from this software
  without specific prior written permission. 

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WebApi.h"
#import "DataModel.h"
#import "URLComponent.h"
#import "HttpClient.h"

#import "AmazonApi.h"
#import "RakutenApi.h"
#import "KakakuCom.h"

@implementation WebApiFactory
@synthesize serviceId;

/**
   create WebApiFactory instance
*/
+ (WebApiFactory *)webApiFactory
{
    return [[[WebApiFactory alloc] init] autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self loadDefaults];
        isCodeSearch = NO;
    }
    return self;
}

/**
   Select service id for code search

   @note Only amazon supports code search
*/
- (void)setCodeSearch
{
    isCodeSearch = YES;

    switch (serviceId) {
    case AmazonUS:
    case AmazonCA:
    case AmazonUK:
    case AmazonFR:
    case AmazonDE:
    case AmazonJP:
        /* ok */
        break;

    default:
        serviceId = [self _fallbackServiceId];
        break;
    }
}

/**
   Load settings
*/
- (void)loadDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    serviceId = [defaults integerForKey:@"ServiceId"] - 1;

    if (serviceId < 0 || MaxServiceId <= serviceId) {  // no default settings or error...
        serviceId = [self _fallbackServiceId];
    }
}

/**
   Save settings
*/
- (void)saveDefaults
{
    ASSERT(0 <= serviceId && serviceId < MaxServiceId);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:serviceId + 1 forKey:@"ServiceId"];
}    

/**
   Get fallback service id from current region
*/
- (int)_fallbackServiceId
{
    NSString *country = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    return [self serviceIdFromCountryCode:country];
}

/**
   Get service id from country code
*/
- (int)serviceIdFromCountryCode:(NSString*)country
{
    int sid = AmazonUS; // default
    
    if ([country isEqualToString:@"CA"]) sid = AmazonCA;
    else if ([country isEqualToString:@"UK"]) sid = AmazonUK;
    else if ([country isEqualToString:@"FR"]) sid = AmazonFR;
    else if ([country isEqualToString:@"DE"]) sid = AmazonDE;
    else if ([country isEqualToString:@"JP"]) sid = AmazonJP;

    return sid;
}

/**
   Create WebApi instance
*/
- (WebApi*)createWebApi
{
    WebApi *api;

    switch (serviceId) {
        case AmazonUS:
        case AmazonCA:
        case AmazonUK:
        case AmazonFR:
        case AmazonDE:
        case AmazonJP:
            api = [[AmazonApi alloc] init];
            break;
#if ENABLE_RAKUTEN
        case Rakuten:
            api = [[RakutenApi alloc] init];
            break;
#endif
#if ENABLE_KAKAKUCOM
        case KakakuCom:
            api = [[KakakuComApi alloc] init];
            break;
#endif
        default:
            ASSERT(NO);
    }

    [api setServiceId:serviceId];
    return api;
}

/**
   Get service id strings
*/
- (NSArray *)serviceIdStrings
{
    NSMutableArray *ary = [[[NSMutableArray alloc] init] autorelease];
    
    // This array must be same order with enum values.
    [ary addObject:@"Amazon (US)"];
    [ary addObject:@"Amazon (CA)"];
    [ary addObject:@"Amazon (UK)"];
    [ary addObject:@"Amazon (FR)"];
    [ary addObject:@"Amazon (DE)"];
    [ary addObject:@"Amazon (JP)"];

    if (!isCodeSearch) {
        // title search
#if ENABLE_RAKUTEN
        [ary addObject:@"楽天 (JP)"];
#endif
#if ENABLE_KAKAKUCOM
        [ary addObject:@"価格.com (JP)"];
#endif
    }
    return ary;
}

/**
   Get service id string
*/
- (NSString *)serviceIdString
{
    NSArray *ary = [self serviceIdStrings];
    return [ary objectAtIndex:serviceId];
}

/**
   Get detail URL of the Item

   @param[in] item Item
   @return URL string
*/
+ (NSString *)detailUrl:(Item *)item isMobile:(BOOL)isMobile
{
    NSString *url = nil;
    url = [AmazonApi detailUrl:item isMobile:isMobile];
    if (url != nil) return url;
    
    return item.detailURL;
}

@end

////////////////////////////////////////////////////////////////////////
// WebApi

@implementation WebApi
@synthesize delegate;
@synthesize searchKey, searchKeyType, searchIndex;

- (id)init
{
    self = [super init];
    if (self) {
        delegate = nil;
        searchKey = nil;
        searchKeyType = SearchKeyCode;
        searchIndex = nil;
    }
    return self;
}

- (void)dealloc
{
    [searchKey release];
    [searchIndex release];

    [super dealloc];
}

/**
   Set Service ID
*/
- (void)setServiceId:(int)sid
{
    serviceId = sid;
}

/**
   Execute item search
*/
- (void)itemSearch
{
    ASSERT(NO); // must be override
}

/**
   Get category list (should be override)
*/
- (NSArray *)categoryStrings
{
    return [NSArray arrayWithObjects:@"All", nil];
}

/**
   Get default category (should be override)
*/
- (int)defaultCategoryIndex
{
    return 0;
}

/**
   Start http request
*/
- (void)sendHttpRequest:(NSURL*)url
{
    HttpClient *httpClient = [[HttpClient alloc] init:self];
    [httpClient requestGet:url];
    [httpClient release];
}

/**
   @name HttpClientDelegate
*/
//@{

- (void)httpClientDidFailed:(HttpClient*)client error:(NSError*)err
{
    // show error : TBD
    if (delegate) {
        [delegate webApiDidFailed:self reason:WEBAPI_ERROR_NETWORK message:nil];
    }
}

// 読み込み完了時の処理
- (void)httpClientDidFinish:(HttpClient*)client
{
    // You must override this method
#if 0
    NSString *response = [[[NSString alloc] initWithData:client.receivedData encoding:NSUTF8StringEncoding] autorelease];
    LOG(@"response = %@", response);
    //const char *utf8 = [response UTF8String];
#endif
}

//@}

@end
