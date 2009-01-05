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

// XML State

@implementation AmazonXmlState
@synthesize isLargeImage, isMediumImage, isOffers, isError;
@synthesize errorMessage, indexName; 

- (id)init
{
    self = [super init];
    if (self) {
        self.isLargeImage = NO;
        self.isMediumImage = NO;
        self.isOffers = NO;
        self.isError = NO;
        self.errorMessage = nil;
        self.indexName = nil;
    }
    return self;
}

- (void)dealloc
{
    [errorMessage release];
    [indexName release];
    [super dealloc];
}

@end
	
///////////////////////////////////////////////////////////////////////////////////////////////
// Amazon API
	
@implementation AmazonApi
@synthesize delegate, searchKeyword, searchIndex, searchTitle;

- (id)init
{
    self = [super init];
    if (self) {
        itemArray = [[NSMutableArray alloc] initWithCapacity:10];
        curString = [[NSMutableString alloc] initWithCapacity:20];
        responseData = [[NSMutableData alloc] initWithCapacity:256];
        baseURI = nil;

        NSString *country = [[DataModel sharedDataModel] country];
        [self setCountry:country];
    }
    return self;
}

/**
   Set country code
*/
- (void)setCountry:(NSString*)country
{
    [baseURI release];

    NSString *suffix;

    if ([country isEqualToString:@"JP"]) suffix = @"jp";
    else if ([country isEqualToString:@"DE"]) suffix = @"de";
    else if ([country isEqualToString:@"FR"]) suffix = @"fr";
    else if ([country isEqualToString:@"CA"]) suffix = @"ca";
    else if ([country isEqualToString:@"UK"]) suffix = @"co.uk";
    else suffix = @"com";

    baseURI = [[NSString alloc]
                  initWithFormat:@"http://itemshelf.com/cgi-bin/awsitemsearch.cgi?Country=%@",
                  suffix];
}

- (void)dealloc
{
    [responseData release];
    [itemArray release];

    [searchKeyword release];
    [searchTitle release];
    [searchIndex release];

    [baseURI release];
    [curString release];
    [xmlState release];

    [super dealloc];
}

/////////////////////////////////////////////////////////////////////////////////////
// URL 取得

/**
   Get detail URL of the Item (for PC browser)

   @param[in] item Item
   @return URL string
*/
+ (NSString *)normalUrl:(Item *)item
{
    URLComponent *comp = [[[URLComponent alloc]
                              initWithURLString:item.detailURL]
                             autorelease];

    // SubscriptionId と tag (associate id) を抜く
    [comp removeQuery:@"SubscriptionId"];
    [comp removeQuery:@"tag"];
	
    NSString *url = [NSString
                        stringWithFormat:@"http://itemshelf.com/cgi-bin/amazonredirect.cgi/%@", [comp absoluteString]];
    return url;
}
/**
   Get detail URL of the Item (for iPhone browser)

   @param[in] item Item
   @return URL string
*/
+ (NSString *)mobileUrl:(Item *)item
{
    URLComponent *comp = [[[URLComponent alloc] 
                              initWithURLString:item.detailURL] autorelease];

    NSString *url = [NSString
                        stringWithFormat:@"http://itemshelf.com/cgi-bin/amazonmobile.cgi?host=%@&asin=%@",
                        comp.host, item.asin];
    return url;
}

/////////////////////////////////////////////////////////////////////////////////////
// 検索処理

/**
   Execute item search

   @note you must set searchTitle or searchKeyword property before call this.
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
    if (searchTitle) {
        [comp setQuery:@"Title" value:searchTitle];
    } else {
        [comp setQuery:@"Keywords" value:searchKeyword];
    }
    //[comp setQuery:@"Debug" value:@"1"];
    [comp log];

    HttpClient *httpClient = [[HttpClient alloc] init:self];
	
    NSURL *uri = [comp url];
    [httpClient requestGet:uri];
    [httpClient release];
}

/////////////////////////////////////////////////////////////////////////////////////
// HttpClientDelegate

- (void)httpClientDidFailed:(HttpClient*)client error:(NSError*)err
{
    // show error : TBD
    if (delegate) {
        [delegate amazonApiDidFailed:self reason:AMAZON_ERROR_NETWORK message:nil];
    }
}

// 読み込み完了時の処理
- (void)httpClientDidFinish:(HttpClient*)client
{
#if 0
    NSString *response = [[[NSString alloc] initWithData:client.receivedData encoding:NSUTF8StringEncoding] autorelease];
    LOG(@"response = %@", response);
    //const char *utf8 = [response UTF8String];
#endif
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:client.receivedData];
	
    itemCounter = -1;
	
    if (xmlState) {
        [xmlState release];
    }
    xmlState = [[AmazonXmlState alloc] init];
	
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:YES];
    BOOL result = [parser parse];
    [parser release];
	
    if (delegate) {
        if (!result) {
            // XML error
            [delegate amazonApiDidFailed:self reason:AMAZON_ERROR_BADREPLY message:nil];
        } else if (itemArray.count > 0) {
            // success
            [delegate amazonApiDidFinish:self items:itemArray];
        } else {
            // no data
            [delegate amazonApiDidFailed:self reason:AMAZON_ERROR_NOTFOUND message:xmlState.errorMessage];
        }
    }
}

/////////////////////////////////////////////////////////////////////////////////////
// パーサ delegate

// 開始タグの処理
- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elem namespaceURI:(NSString *)nspace qualifiedName:(NSString *)qname attributes:(NSDictionary *)attributes
{
    [curString setString:@""];
	
    if ([elem isEqualToString:@"Item"]) {
        itemCounter++;

        if (itemCounter < AMAZON_MAX_SEARCH_ITEMS) {
            Item *item = [[Item alloc] init];

            item.idString = searchKeyword;
            item.productGroup = xmlState.indexName;

            [itemArray addObject:item];
            [item release];
        }
    }
    if (itemCounter >= AMAZON_MAX_SEARCH_ITEMS) {
        return;
    }

    if ([elem isEqualToString:@"MediumImage"]) {
        xmlState.isMediumImage = YES;
    }
    else if ([elem isEqualToString:@"LargeImage"]) {
        xmlState.isLargeImage = YES;
    }
    else if ([elem isEqualToString:@"Offers"]) {
        xmlState.isOffers = YES;
    }
    else if ([elem isEqualToString:@"Error"]) {
        xmlState.isError = YES;
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

    if (itemCounter >= AMAZON_MAX_SEARCH_ITEMS) {
        [curString setString:@""];
        return;
    }

    if ([elem isEqualToString:@"LargeImage"]) {
        xmlState.isLargeImage = NO;
    }
    else if ([elem isEqualToString:@"MediumImage"]) {
        xmlState.isMediumImage = NO;
    }
    else if ([elem isEqualToString:@"Offers"]) {
        xmlState.isOffers = NO;
    }
    else if ([elem isEqualToString:@"Error"]) {
        xmlState.isError = NO;
    }
    else if ([elem isEqualToString:@"Message"]) {
        if (xmlState.isError) {
            xmlState.errorMessage = [NSString stringWithString:curString];
        }
    }
    else if ([elem isEqualToString:@"SearchIndex"] || [elem isEqualToString:@"IndexName"]) {
        if (curString.length > 0) {
            xmlState.indexName = [NSString stringWithString:curString];
        }
    }

    if (itemCounter < 0) {
        [curString setString:@""];
        return;
    }
    Item *item = [itemArray objectAtIndex:itemCounter];
	
    if ([elem isEqualToString:@"ASIN"]) {
        item.asin = [NSString stringWithString:curString];
    } else if ([elem isEqualToString:@"Title"]) {
        item.name = [NSString stringWithString:curString];
    } else if ([elem isEqualToString:@"Author"]) {
        item.author = [NSString stringWithString:curString];
    } else if ([elem isEqualToString:@"Manufacturer"]) {
        item.manufacturer = [NSString stringWithString:curString];
        //	} else if ([elem isEqualToString:@"ProductGroup"]) {
        //		item.productGroup = [NSString stringWithString:curString];
        //	} else if ([elem isEqualToString:@"IndexName"]) {
        //		item.productGroup = [NSString stringWithString:curString];
    } else if ([elem isEqualToString:@"DetailPageURL"]) {
        item.detailURL = [NSString stringWithString:curString];
    } else if ([elem isEqualToString:@"FormattedPrice"]) {
        // 金額は、Offers の中のものだけを見る。
        // (OfferSummary の中にも FormattedPrice があるので)
        if (xmlState.isOffers) {
            item.price = [NSString stringWithString:curString];
        }
    } else if ([elem isEqualToString:@"URL"]) {
        // MediumImage の URL だけを見る
        // かつ、最初の1個目だけ見る
        if (xmlState.isMediumImage && [item.imageURL isEqualToString:@""]) {
            item.imageURL = [NSString stringWithString:curString];
        }
    }
    [curString setString:@""];
}

@end
