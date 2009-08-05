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

#import "AmazonApi.h"
#import "DataModel.h"
#import "URLComponent.h"
#import "HttpClient.h"
#import "dom.h"

// XML State

///////////////////////////////////////////////////////////////////////////////////////////////
// Amazon API
	
@implementation AmazonApi

- (id)init
{
    self = [super init];
    if (self) {
        itemArray = [[NSMutableArray alloc] initWithCapacity:10];
        curString = [[NSMutableString alloc] initWithCapacity:20];
        responseData = [[NSMutableData alloc] initWithCapacity:256];
        baseURI = nil;
    }
    return self;
}

/**
   Set service ID
*/
- (void)setServiceId:(int)sid
{
    [super setServiceId:sid];

    [baseURI release];

    NSString *suffix;

    switch (sid) {
    case AmazonUS: suffix = @"com"; break;
    case AmazonCA: suffix = @"ca"; break;
    case AmazonUK: suffix = @"co.uk"; break;
    case AmazonFR: suffix = @"fr"; break;
    case AmazonDE: suffix = @"de"; break;
    default: ASSERT(NO); // fallthrough
    case AmazonJP: suffix = @"jp"; break;
    }

    baseURI = [[NSString alloc]
                  initWithFormat:@"http://itemshelf.com/cgi-bin/awsitemsearch.cgi?Country=%@",
                  suffix];
}

- (void)dealloc
{
    [responseData release];
    [itemArray release];

    [baseURI release];
    [curString release];
    [xmlState release];

    [super dealloc];
}

/////////////////////////////////////////////////////////////////////////////////////

/**
   Get detail URL of the Item

   @param[in] item Item
   @return URL string
*/
+ (NSString *)detailUrl:(Item *)item isMobile:(BOOL)isMobile
{
    URLComponent *comp = [[[URLComponent alloc]
                              initWithURLString:item.detailURL]
                             autorelease];

    NSRange range = [comp.host rangeOfString:@"amazon"];
    if (range.location == NSNotFound) {
        // not amazon URL
        return nil;
    }

    NSString *url;
    if (!isMobile) {
        // SubscriptionId と tag (associate id) を抜く
        [comp removeQuery:@"SubscriptionId"];
        [comp removeQuery:@"tag"];
	
        url = [NSString
                stringWithFormat:@"http://itemshelf.com/cgi-bin/amazonredirect.cgi/%@",
                [comp absoluteString]];
    } else {
        url = [NSString
                stringWithFormat:@"http://itemshelf.com/cgi-bin/amazonmobile.cgi?host=%@&asin=%@",
                comp.host, item.asin];
    }

    return url;
}


/////////////////////////////////////////////////////////////////////////////////////
// カテゴリ

- (NSArray *)categoryStrings
{
    return [NSArray
               arrayWithObjects:@"Apparel", @"Baby", @"Beauty", @"Books",
               @"Classical", @"DVD", @"Electronics", @"ForeignBooks", @"Grocery",
               @"HealthPersonalCare", @"Hobbies", @"Kitchen", @"Music",
               @"MusicTracks", @"Software", @"SportingGoods", @"Toys", @"VHS", @"Video",
               @"VideoGames", @"Watches", nil];
}

/**
   Get default category (should be override)
*/
- (int)defaultCategoryIndex
{
    return 3; // Books
}


/////////////////////////////////////////////////////////////////////////////////////
// 検索処理

/**
   Execute item search

   @note you must set searchKey / searchKeyType property before call this.
   And you can set searchIndex.
*/
- (void)itemSearch
{
    [itemArray removeAllObjects];

    [responseData setLength:0];

    if (searchIndex == nil) {
        searchIndex = @"Blended";
    }

    URLComponent *comp = [[[URLComponent alloc] initWithURLString:baseURI] autorelease];
    [comp setQuery:@"SearchIndex" value:searchIndex];
    switch (searchKeyType) {
    case SearchKeyTitle:
        [comp setQuery:@"Title" value:searchKey];
        break;
    case SearchKeyAuthor:
        [comp setQuery:@"Author" value:searchKey];
        break;
    case SearchKeyArtist:
        [comp setQuery:@"Artist" value:searchKey];
        break;
    case SearchKeyAll:
    default:
        [comp setQuery:@"Keywords" value:searchKey];
        break;
    }
    //[comp setQuery:@"Debug" value:@"1"];
    [comp log];

    NSURL *uri = [comp url];
    [super sendHttpRequest:uri];
}

/////////////////////////////////////////////////////////////////////////////////////
// HttpClientDelegate

/**
   @name HttpClientDelegate
*/
//@{

// 読み込み完了時の処理
- (void)httpClientDidFinish:(HttpClient*)client
{
    [super httpClientDidFinish:client];
    
    // DOM TEST
    DomParser *domParser = [[[DomParser alloc] init] autorelease];
    XmlNode *root = [domParser parse:client.receivedData];
    //[root dump];

    if (!root) {
        // XML error
        [delegate webApiDidFailed:self reason:WEBAPI_ERROR_BADREPLY message:nil];
    }

    // Search index
    NSString *indexName = [root findNode:@"IndexName"].text;
    if (indexName == nil) {
        indexName = [root findNode:@"SearchIndex"].text;
    }
    if (indexName == nil) {
        indexName = @"Other";
    }

    //
    // Item Node
    //
    XmlNode *itemNode;
    itemCounter = 0;
    for (itemNode = [root findNode:@"Item"]; itemNode; itemNode = [itemNode findSibling]) {
        itemCounter++;
        if (itemCounter >= AMAZON_MAX_SEARCH_ITEMS) break;
        
        Item *item = [[Item alloc] init];
        [itemArray addObject:item];
        [item release];

        item.serviceId = serviceId;
        item.category = indexName;

        if (searchKeyType == SearchKeyCode) {
            item.idString = searchKey;
        } else {
            item.idString = nil;
        }
        
        item.asin = [itemNode findNode:@"ASIN"].text;
        item.name = [itemNode findNode:@"Title"].text;
        item.author = [itemNode findNode:@"Author"].text;
        item.manufacturer = [itemNode findNode:@"Manufacturer"].text;
        item.detailURL = [itemNode findNode:@"DetailPageURL"].text;

        XmlNode *offers = [itemNode findNode:@"Offers"];
        if (offers) {
            // 金額は、Offers の中のものだけを見る。
            // (OfferSummary の中にも FormattedPrice があるので)
            item.price = [offers findNode:@"FormattedPrice"].text;
        }
        XmlNode *mediumImage = [itemNode findNode:@"MediumImage"];
        if (mediumImage) {
            // MediumImage の URL だけを見る
            // かつ、最初の1個目だけ見る
            item.imageURL = [mediumImage findNode:@"URL"].text;
        }
    }

    if (itemArray.count > 0) {
        // success
        [delegate webApiDidFinish:self items:itemArray];
    } else {
        // no data
        NSString *message = nil;
        XmlNode *err = [root findNode:@"Error"];
        if (err) {
            message = [err findNode:@"Message"].text;
        }
        if (message == nil) {
            message = @"No items";
        }
        [delegate webApiDidFailed:self reason:WEBAPI_ERROR_NOTFOUND message:message]; //###
    }
}

//@}

@end
