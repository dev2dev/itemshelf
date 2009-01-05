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

// Amazon API

#import <UIKit/UIKit.h>
#import "Common.h"
#import "Item.h"
#import "HttpClient.h"

@class AmazonApi;
@class AmazonXmlState;

#define AMAZON_MAX_SEARCH_ITEMS 25

#define AMAZON_ERROR_NETWORK	0
#define AMAZON_ERROR_NOTFOUND	1
#define AMAZON_ERROR_BADREPLY   2

@protocol AmazonApiDelegate
-(void)amazonApiDidFinish:(AmazonApi*)amazonApi items:(NSMutableArray*)items;
-(void)amazonApiDidFailed:(AmazonApi*)amazonApi reason:(int)reason message:(NSString *)message;
@end

@interface AmazonApi : NSObject <HttpClientDelegate> {
    id<AmazonApiDelegate> delegate;

    NSString *baseURI;
	
    NSString *searchKeyword;    // Keyword to search (barcode, isbn, etc.)
    NSString *searchTitle;      // Title to search
    NSString *searchIndex;

    NSMutableArray *itemArray;  // Searched items array

    // For XML parser
    int itemCounter;
    NSMutableData *responseData;
    NSMutableString *curString;	  // current string in XML element
    AmazonXmlState *xmlState;
}

@property(nonatomic, assign) id<AmazonApiDelegate> delegate;

@property(nonatomic, retain) NSString *searchKeyword;
@property(nonatomic, retain) NSString *searchTitle;
@property(nonatomic, retain) NSString *searchIndex;

+ (NSString *)normalUrl:(Item *)item;
+ (NSString *)mobileUrl:(Item *)item;
- (void)itemSearch;

- (void)setCountry:(NSString*)country;

@end

// XML state
@interface AmazonXmlState : NSObject {
    BOOL isLargeImage, isMediumImage, isOffers, isError;
    NSString *errorMessage;
    NSString *indexName; 
};

@property(nonatomic, assign) BOOL isLargeImage;
@property(nonatomic, assign) BOOL isMediumImage;
@property(nonatomic, assign) BOOL isOffers;
@property(nonatomic, assign) BOOL isError;
@property(nonatomic, retain) NSString *errorMessage;
@property(nonatomic, retain) NSString *indexName;
@end
