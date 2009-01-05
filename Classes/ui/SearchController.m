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

#import "SearchController.h"
#import "ItemViewController.h"
#import "AmazonApi.h"
#import "DataModel.h"

@implementation SearchController

@synthesize delegate, viewController, selectedShelf, country;

static SearchControllerType currentSearchControllerType = SearchControllerTypeAmazon;

/**
   Create SearchController instance (factory method)

   @note At this moment, this supports only Amazon.
*/
+ (SearchController *)createController
{
    SearchController *c = nil;

    switch (currentSearchControllerType) {
    case SearchControllerTypeAmazon:
        c = [[SearchControllerAmazon alloc] init];
        break;

    default:
        ASSERT(0);
        break;
    }

    return c;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.delegate = nil;
        self.viewController = nil;
        self.selectedShelf = nil;
        self.country = nil;
        activityIndicator = nil;
    }
    return self;
}

- (void)dealloc
{
    [viewController release];
    [selectedShelf release];
    [country release];

    if (activityIndicator) {
        [activityIndicator removeFromSuperview];
        [activityIndicator release];
    }
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////
// Search functions

/**
   Search item with keyword

   @param[in] keyword Search keyword
*/
- (void)searchWithKeyword:(NSString*)keyword
{
    // must be override
    ASSERT(NO);
}

/**
   Search item with title

   @param[in] title Title to search
   @param[in] searchIndex Search index (category)
*/
- (void)searchWithTitle:(NSString *)title withIndex:(NSString*)searchIndex
{
    // must be override
    ASSERT(NO);
}

////////////////////////////////////////////////////////////////////////////////////////////
// ActivityIndicator

- (void)_showActivityIndicator
{
    ASSERT(viewController != nil);
    ASSERT(activityIndicator == nil);


    activityIndicator = [[UIActivityIndicatorView alloc]
                            initWithFrame:CGRectMake(0, 0, viewController.view.bounds.size.width, viewController.view.bounds.size.height)];
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    activityIndicator.backgroundColor = [UIColor grayColor];
    activityIndicator.contentMode = UIViewContentModeCenter;
    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
        UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [viewController.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
}

- (void)_dismissActivityIndicator
{
    ASSERT(viewController != nil);
    ASSERT(activityIndicator);

    [activityIndicator stopAnimating];
    [activityIndicator removeFromSuperview];
    [activityIndicator release];
    activityIndicator = nil;
}

@end

///////////////////////////////////////////////////////////////////////////
// SearchController for Amazon

@implementation SearchControllerAmazon

- (void)searchWithKeyword:(NSString*)keyword
{
    ASSERT(viewController != nil);
    [self _showActivityIndicator];

    autoRegisterShelf = YES;

    AmazonApi *amazon = [[AmazonApi alloc] init];
    amazon.delegate = self;
    if (country != nil) {
        [amazon setCountry:country];
    }

    amazon.searchKeyword = keyword;
    [amazon itemSearch];
}

- (void)searchWithTitle:(NSString *)title withIndex:(NSString*)searchIndex
{
    ASSERT(viewController != nil);
    [self _showActivityIndicator];

    autoRegisterShelf = NO;

    AmazonApi *amazon = [[AmazonApi alloc] init];
    amazon.delegate = self;
    amazon.searchTitle = title;
    amazon.searchIndex = searchIndex;
    if (country != nil) {
        [amazon setCountry:country];
    }

    [amazon itemSearch];
}

/**
   @name AmazonApiDelegate
*/
//@{

// 検索成功時の処理
- (void)amazonApiDidFinish:(AmazonApi *)amazon items:(NSMutableArray *)itemArray
{
    [self _dismissActivityIndicator];

    // add history
    DataModel *dm = [DataModel sharedDataModel];
    int count = [itemArray count];

    for (int i = 0; i < count; i++) {
        Item *item = [itemArray objectAtIndex:i];

        // 棚にひも付けをする (登録はまだ)
        if (selectedShelf == nil) {
            item.shelfId = 0; // 未分類
        } else {
            item.shelfId = selectedShelf.pkey;
        }
		
        // 重複チェック
        Item *x = [dm findSameItem:item];
        if (x == nil) {
            // 棚に登録
            if (autoRegisterShelf) {
                [dm addItem:item];
            }
        } else {
            // データ重複 : 置換する
            [itemArray replaceObjectAtIndex:i withObject:x];
        }
    }
	
    // show item view
    ItemViewController *vc = [[[ItemViewController alloc] initWithNibName:@"ItemView" bundle:nil] autorelease];
    vc.itemArray = itemArray;

    [amazon release];

    [viewController.navigationController pushViewController:vc animated:YES];

    if (delegate) {
        [delegate searchControllerFinish:self result:YES];
    }
    [self release];
}

// 検索失敗
- (void)amazonApiDidFailed:(AmazonApi *)amazon reason:(int)reason message:(NSString *)message
{
    [self _dismissActivityIndicator];
	
    NSString *reasonString = @"Unknown error";
    switch (reason) {
    case AMAZON_ERROR_NETWORK:
        reasonString = NSLocalizedString(@"Cannot connect Amazon service", @"");
        break;

    case AMAZON_ERROR_BADREPLY:
        reasonString = NSLocalizedString(@"Illegal message was received", @"");
        break;

    case AMAZON_ERROR_NOTFOUND:
        reasonString = NSLocalizedString(@"Cannot find item information", @"");
        break;
    }

    if (message) {
        reasonString = [NSString stringWithFormat:@"%@\n(%@)", reasonString, message];
    }

    [Common showAlertDialog:@"Error" message:reasonString];

    [amazon release];

    if (delegate) {
        [delegate searchControllerFinish:self result:NO];
    }
    [self release];
}

//@}

@end
