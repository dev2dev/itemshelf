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

///////////////////////////////////////////////////////////////////////////////////////////////
// KakakuCom API
	
@implementation KakakuComApi
@synthesize searchKeyword;

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
// 検索処理

/**
   Execute item search

   @note you must set searchKeyword or searchCode property before call this.
   And you can set searchIndex.
*/
- (void)itemSearch
{
    if (searchCode != nil) {
        // バーコード検索は対応しない
        if (delegate) {
            [delegate webApiDidFailed:self reason:WEBAPI_ERROR_BADPARAM
                      message:@"価格.com はバーコード検索に対応していません"];
        }
        return;
    }

    [itemArray removeAllObjects];
    [responseData setLength:0];

    NSString *baseURI = @"http://itemshelf.com/cgi-bin/kakakucomsearch.cgi";
    URLComponent *comp = [[[URLComponent alloc] initWithURLString:baseURI] autorelease];

    // タイトル検索のみ
    [comp setQuery:@"keyword" value:searchKeyword];
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

    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:client.receivedData];
	
    itemCounter = -1;
	
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:YES];
    BOOL result = [parser parse];
    [parser release];
	
    if (delegate) {
        if (!result) {
            // XML error
            [delegate webApiDidFailed:self reason:WEBAPI_ERROR_BADREPLY message:nil];
        } else if (itemArray.count > 0) {
            // success
            [delegate webApiDidFinish:self items:itemArray];
        } else {
            // no data
            [delegate webApiDidFailed:self reason:WEBAPI_ERROR_NOTFOUND message:@"No items"]; //###
        }
    }
}

//@}

/////////////////////////////////////////////////////////////////////////////////////
// パーサ delegate

/**
   @name NXSMLParser delegate
*/
//@{

// 開始タグの処理
- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elem namespaceURI:(NSString *)nspace qualifiedName:(NSString *)qname attributes:(NSDictionary *)attributes
{
    [curString setString:@""];
	
    if ([elem isEqualToString:@"Item"]) {
        itemCounter++;

        Item *item = [[Item alloc] init];

        item.serviceId = serviceId;
        item.category = @"Other"; // とりあえず

        [itemArray addObject:item];
        [item release];
    }
}

// 文字列処理
- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string
{
    [curString appendString:string];
}

// 終了タグの処理
- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elem namespaceURI:(NSString *)nspace qualifiedName:(NSString *)qname
{
    LOG(@"%@ = %@", elem, curString);

    if (itemCounter < 0) {
        [curString setString:@""];
        return;
    }
    Item *item = [itemArray objectAtIndex:itemCounter];
	
    if ([elem isEqualToString:@"ProductID"]) {
        item.idString = [NSString stringWithString:curString];
    } else if ([elem isEqualToString:@"ProductName"]) {
        item.name = [NSString stringWithString:curString];
//    } else if ([elem isEqualToString:@"Author"]) {
//        item.author = [NSString stringWithString:curString];
    } else if ([elem isEqualToString:@"MakerName"]) {
        item.manufacturer = [NSString stringWithString:curString];
    } else if ([elem isEqualToString:@"ItemPageUrl"]) {
        item.detailURL = [NSString stringWithString:curString];
    } else if ([elem isEqualToString:@"LowestPrice"]) {
        double price = [[NSString stringWithString:curString] doubleValue];
        item.price = [Common currencyString:price withLocaleString:@"ja_JP"];
    } else if ([elem isEqualToString:@"ImageUrl"]) {
        item.imageURL = [NSString stringWithString:curString];
    }

    // カテゴリはどうするか？
    // 一応、CategoryName はあるけど、Amazon とのマッピングは面倒

    [curString setString:@""];
}

//@}

@end
