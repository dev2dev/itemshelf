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
    return [NSArray arrayWithObjects:@"All", @"Books", @"DVD", @"Music", nil];
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
    if (searchKeyType == SearchKeyCode) {
        // バーコード検索は対応しない
        if (delegate) {
            [delegate webApiDidFailed:self reason:WEBAPI_ERROR_BADPARAM
                      message:@"楽天はバーコード検索に対応していません"];
        }
        return;
    }

    [itemArray removeAllObjects];
    [responseData setLength:0];

    //NSString *baseURI = @"http://itemshelf.com/cgi-bin/rakutensearch.cgi?";
    NSString *baseURI = @"http://itemshelf.com/cgi-bin/rakutensearch2.cgi?";
    URLComponent *comp = [[[URLComponent alloc] initWithURLString:baseURI] autorelease];

    // キーワード検索のみ
    [comp setQuery:@"keyword" value:searchKey];

    // operation を searchIndex から決定する
    //NSString *operation = @"ItemSearch";
    NSString *operation = @"BooksTotalSearch";
    if ([searchIndex isEqualToString:@"Books"]) {
        //operation = @"BookSearch";
        operation = @"BooksBookSearch";
    }
    else if ([searchIndex isEqualToString:@"DVD"]) {
        //operation = @"DVDSearch";
        operation = @"BooksDVDSearch";
    }
    else if ([searchIndex isEqualToString:@"Music"] ||
             [searchIndex isEqualToString:@"Classical"]) {
        //operation = @"CDSearch";
        operation = @"BooksCDSearch";
    }
    [comp setQuery:@"operation" value:operation];

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

    if ([elem isEqualToString:@"jan"]) {
        item.idString = [NSString stringWithString:curString]; // とりあえず
    }
    else if ([elem isEqualToString:@"title"]) {
        item.name = [NSString stringWithString:curString];
    }
#if 0
    // old
    if ([elem isEqualToString:@"itemCode"]) {
        item.idString = [NSString stringWithString:curString]; // とりあえず
    } else if ([elem isEqualToString:@"itemName"]) {
        item.name = [NSString stringWithString:curString];
    }
#endif
    else if ([elem isEqualToString:@"itemUrl"]) {
        item.detailURL = [NSString stringWithString:curString];
    }
    else if ([elem isEqualToString:@"mediumImageUrl"]) {
        item.imageURL = [NSString stringWithString:curString];
    }
    else if ([elem isEqualToString:@"itemPrice"]) {
        double price = [[NSString stringWithString:curString] doubleValue];
        item.price = [Common currencyString:price withLocaleString:@"ja_JP"];
    }
    else if ([elem isEqualToString:@"author"]) {
        item.author = [NSString stringWithString:curString];
    }
    else if ([elem isEqualToString:@"publisherName"]) {
        item.manufacturer = [NSString stringWithString:curString];
    }

    // カテゴリはどうするか？
    // 一応、genreId はあるけど、Amazon とのマッピングは面倒

    [curString setString:@""];
}

//@}

@end
