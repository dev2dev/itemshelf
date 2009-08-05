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
#import "WebApi.h"
#import "KakakuCom.h"
#import "dom.h"

///////////////////////////////////////////////////////////////////////////////////////////////
// KakakuCom API
	
@implementation KakakuComApi

- (id)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
    [super dealloc];
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
    if (searchKeyType == SearchKeyCode) {
        // バーコード検索は対応しない
        if (delegate) {
            [delegate webApiDidFailed:self reason:WEBAPI_ERROR_BADPARAM
                      message:@"価格.com はバーコード検索に対応していません"];
        }
        return;
    }

    NSString *baseURI = @"http://itemshelf.com/cgi-bin/kakakucomsearch.cgi";
    URLComponent *comp = [[[URLComponent alloc] initWithURLString:baseURI] autorelease];

    // すべてキーワード検索
    [comp setQuery:@"keyword" value:searchKey];
    [comp log];
    
    // カテゴリ指定はしない、オーダは固定
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
        return;
    }

    NSMutableArray *itemArray = [[[NSMutableArray alloc] init] autorelease];
    XmlNode *itemNode;
    for (itemNode = [root findNode:@"Item"]; itemNode; itemNode = [itemNode findSibling]) {
        Item *item = [[Item alloc] init];
        [itemArray addObject:item];
        [item release];

        item.serviceId = serviceId;
        item.category = @"Other"; // とりあえず

        item.idString = [itemNode findNode:@"ProductID"].text;
        item.name = [itemNode findNode:@"ProductName"].text;
        //item.author = [itemNode findNode:@"author"].text;
        item.manufacturer = [itemNode findNode:@"MakerName"].text;
        item.detailURL = [itemNode findNode:@"ItemPageUrl"].text;
        item.imageURL = [itemNode findNode:@"ImageUrl"].text;
        item.price = [itemNode findNode:@"LowestPrice"].text;
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
