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

// Web API

#import <UIKit/UIKit.h>
#import "Common.h"
#import "Item.h"
#import "HttpClient.h"

@class WebApi;

// error codes
#define WEBAPI_ERROR_NETWORK	0
#define WEBAPI_ERROR_NOTFOUND	1
#define WEBAPI_ERROR_BADREPLY   2
#define WEBAPI_ERROR_BADPARAM   3

// service ids
enum {
    AmazonUS = 0,
    AmazonCA,
    AmazonUK,
    AmazonFR,
    AmazonDE,
    AmazonJP,
    KakakuCom,

    MaxServiceId
};

/**
   Web API delegate protocol
*/
@protocol WebApiDelegate
/**
   Called when web API is successfully finished

   @param[in] webApi webApi instance
   @param[in] items Found items array
*/
-(void)webApiDidFinish:(WebApi*)webApi items:(NSMutableArray*)items;

/**
   Called when web API is failed.

   @param[in] webApi WebApi instance
   @param[in] reason Reason code
   @param[in] message Error message
*/
-(void)webApiDidFailed:(WebApi*)amazonApi reason:(int)reason message:(NSString *)message;
@end

/**
   Web API

   Base class of web api (amazon, kakaku.com etc.)

   To search items, create the instance of derived class of WebApi.
   set delegate, set parameters, then call itemSearch.

   The result will be passed with webApiDelegate protocol.
*/
@interface WebApi : NSObject <HttpClientDelegate> {
    id<WebApiDelegate> delegate;

    NSString *searchKeyword;    ///< Keyword to search (barcode, isbn, etc.)
    NSString *searchTitle;      ///< Title to search
    NSString *searchIndex;      ///< Search index (category)
}

@property(nonatomic, assign) id<WebApiDelegate> delegate;
@property(nonatomic, retain) NSString *searchKeyword;
@property(nonatomic, retain) NSString *searchTitle;
@property(nonatomic, retain) NSString *searchIndex;

+ (int)defaultServiceId;
+ (int)fallbackServiceId;
+ (void)setDefaultServiceId;
+ (WebApi*)createWebApi:(int)serviceId;

//+ (NSString *)normalUrl:(Item *)item;
//+ (NSString *)mobileUrl:(Item *)item;

- (void)itemSearch;
- (void)setCountry:(NSString*)country;

// used by derived class
- (void)sendHttpRequest:(NSURL*)url;

@end
