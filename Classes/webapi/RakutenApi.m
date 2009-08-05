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
#import "RakutenApi.h"
#import "dom.h"

///////////////////////////////////////////////////////////////////////////////////////////////
// Rakuten API
	
@implementation RakutenApi

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
    return [NSArray arrayWithObjects:@"All", @"Books", @"DVD", @"Music", @"Game", @"Software", nil];
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
#if 0
    if (searchKeyType == SearchKeyCode) {
        // バーコード検索は対応しない
        if (delegate) {
            [delegate webApiDidFailed:self reason:WEBAPI_ERROR_BADPARAM
                      message:@"楽天はバーコード検索に対応していません"];
        }
        return;
    }
#endif
	
    [itemArray removeAllObjects];
    [responseData setLength:0];

    //NSString *baseURI = @"http://itemshelf.com/cgi-bin/rakutensearch.cgi?";
    NSString *baseURI = @"http://itemshelf.com/cgi-bin/rakutensearch2.cgi?";
    URLComponent *comp = [[[URLComponent alloc] initWithURLString:baseURI] autorelease];

    NSString *operation = nil;
    NSString *param = nil;

    if (searchKeyType == SearchKeyCode) {
        // バーコード検索
        // ここでは書籍のみを検索する (カテゴリが不明なので
        operation = @"BooksBookSearch";
        param = @"isbn";
    } else {
        // キーワード検索

        // カテゴリ別に operation を決定
        if ([searchIndex isEqualToString:@"Books"]) {
            operation = @"BooksBookSearch";
        }
        else if ([searchIndex isEqualToString:@"DVD"]) {
            operation = @"BooksDVDSearch";
        }
        else if ([searchIndex isEqualToString:@"Music"]) {
            operation = @"BooksCDSearch";
        }
        else if ([searchIndex isEqualToString:@"Game"]) {
            operation = @"BooksGameSearch";
        }
        else if ([searchIndex isEqualToString:@"Software"]) {
            operation = @"BooksSoftwareSearch";
        } else {
            operation = @"BooksTotalSearch";
            param = @"keyword"; // keyword 固定
        }

        // パラメータを設定
        if (param == nil) {
            switch (searchKeyType) {
            case SearchKeyAuthor:
            case SearchKeyArtist:
                if ([searchIndex isEqualToString:@"CD"] ||
                    [searchIndex isEqualToString:@"DVD"]) {
                    param = @"artistName";
                } else {
                    param = @"author";
                }
                break;

            case SearchKeyAll:
            case SearchKeyTitle:
            default:
                param = @"title";
                break;
            }
        }
    }
    [comp setQuery:@"operation" value:operation];
    [comp setQuery:param value:searchKey];

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

    XmlNode *itemNode;
    for (itemNode = [root findNode:@"Item"]; itemNode; itemNode = [itemNode findSibling]) {
        Item *item = [[Item alloc] init];
        [itemArray addObject:item];
        [item release];

        item.serviceId = serviceId;
        item.category = @"Other"; // とりあえず

        XmlNode *n;
        n = [itemNode findNode:@"isbn"];
        if (n) {
            item.idString = n.text;
        } else {
            n = [itemNode findNode:@"jan"];
            if (n) item.idString = n.text;
        }
    
        item.name = [itemNode findNode:@"title"].text;
        item.author = [itemNode findNode:@"author"].text;
        if (item.author == nil) {
            item.author = [itemNode findNode:@"artistName"].text;
        }
        item.manufacturer = [itemNode findNode:@"publisherName"].text;
        if (item.manufacturer == nil) {
            item.manufacturer = [itemNode findNode:@"label"].text;
        }
        item.detailURL = [itemNode findNode:@"itemUrl"].text;
        item.imageURL = [itemNode findNode:@"mediumImageUrl"].text;
        n = [itemNode findNode:@"itemPrice"];
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
        NSString *message = [root findNode:@"Status"].text;
        if (message == nil) {
            message = @"No items";
        }
        [delegate webApiDidFailed:self reason:WEBAPI_ERROR_NOTFOUND message:message]; //###
    }
}

//@}

@end
