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

#import "DataModel.h"
#import "URLComponent.h"
#import "WebApi.h"
#import "Yahoo.h"
#import "dom.h"

///////////////////////////////////////////////////////////////////////////////////////////////
// Yahoo shopping api
	
@implementation YahooApi

- (id)init
{
    self = [super init];
    if (self) {
        itemArray = [[NSMutableArray alloc] initWithCapacity:10];
        curString = [[NSMutableString alloc] initWithCapacity:20];
        responseData = [[NSMutableData alloc] initWithCapacity:256];
    }
    return self;
}

- (void)dealloc
{
    [responseData release];
    [itemArray release];
    [curString release];

    [super dealloc];
}

/////////////////////////////////////////////////////////////////////////////////////
// カテゴリ

- (NSArray *)categoryStrings
{
    return [NSArray arrayWithObjects:@"All", nil];
}

/**
   Get default category (should be override)
*/
- (int)defaultCategoryIndex
{
    return 0; // all
}

/////////////////////////////////////////////////////////////////////////////////////
// 検索処理

/**
   Execute item search

   @note you must set searchKey/searchKeyType property before call this.
   And you can set searchIndex.
*/
- (void)itemSearch
{
    [itemArray removeAllObjects];
    [responseData setLength:0];

    NSString *baseURI = @"http://itemshelf.com/cgi-bin/yahoojp.cgi?";
    URLComponent *comp = [[[URLComponent alloc] initWithURLString:baseURI] autorelease];

    NSString *param = nil;

    if (searchKeyType == SearchKeyCode) {
        // バーコード検索
        param = @"jan";
    } else {
        // キーワード検索
        param = @"keyword";
    }
    [comp setQuery:param value:searchKey];

    [comp log];
    
    NSURL *url = [comp url];
    [super sendHttpRequest:url];
}

/////////////////////////////////////////////////////////////////////////////////////
// HttpClientDelegate

/**
   @name HttpClientDelegate
*/
//@{

- (void)httpClientDidFinish:(HttpClient*)client
{
    [super httpClientDidFinish:client];

    // Parse XML
    DomParser *domParser = [[[DomParser alloc] init] autorelease];
    XmlNode *root = [domParser parse:client.receivedData];
    //[root dump];

    if (!root) {
        // XML error
        [delegate webApiDidFailed:self reason:WEBAPI_ERROR_BADREPLY message:nil];
    }

    XmlNode *hit;
    for (hit = [root findNode:@"Hit"]; hit; hit = [hit findSibling]) {
        NSString *hitIndex = [hit.attributes objectForKey:@"index"];
        if (hitIndex == nil || [hitIndex isEqualToString:@"0"]) {
            continue;
        }

        Item *item = [[Item alloc] init];
        [itemArray addObject:item];
        [item release];

        item.serviceId = serviceId;
        item.category = @"Other"; // とりあえず

        XmlNode *n;
        n = [hit findNode:@"IsbnCode"];
        if (n) {
            item.idString = n.text;
        } else {
            n = [hit findNode:@"JanCode"];
            if (n) item.idString = [NSString stringWithString:n.text];
        }
    
        item.name = [hit findNode:@"Name"].text;
        item.detailURL = [hit findNode:@"Url"].text;
        item.imageURL = [hit findNode:@"Medium"].text;
        n = [hit findNode:@"Price"];
        if (n) {
            double price = [n.text doubleValue];
            item.price = [Common currencyString:price withLocaleString:@"ja_JP"];
        }
    }

    if (itemArray.count > 0) {
        // success
        [delegate webApiDidFinish:self items:itemArray];
    } else {
        // no data
        [delegate webApiDidFailed:self reason:WEBAPI_ERROR_NOTFOUND message:@"No items"]; //###
    }
}

//@}

@end
