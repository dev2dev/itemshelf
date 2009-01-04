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

/*
  Search Controller

  Web API を用いてアイテムの検索を実行し、ItemView を用いて検索結果を表示する。
  ActivityIndicator の表示など、UI に関する制御も一部行う。

  利用するときは、createController を使ってインスタンスを生成し、
  プロパティを設定、searchXXX を使って検索を実行する。設定するプロパティは以下の通り。

  delegate (option) : 検索完了時に呼び出す delegate を指定
  viewController (mandatory) : 現在表示中の　View Controller を指定
  selectedShelf (option) : 現在選択中の棚を指定
  country (option) : 検索を行う国コードを指定
*/

#import <UIKit/UIKit.h>
#import "AmazonApi.h"
#import "Shelf.h"

@class SearchController;

// 検索先の種別
typedef enum {
    SearchControllerTypeAmazon
} SearchControllerType;


@protocol SearchControllerDelegate
- (void)searchControllerFinish:(SearchController*)controller result:(BOOL)result;
@end

@interface SearchController : NSObject
{
    id<SearchControllerDelegate> delegate;
    UIViewController *viewController;

    Shelf *selectedShelf;
    NSString *country;

    UIActivityIndicatorView *activityIndicator;
    BOOL autoRegisterShelf;
}

@property(nonatomic,assign) id<SearchControllerDelegate> delegate;
@property(nonatomic,retain) UIViewController *viewController;
@property(nonatomic,retain) Shelf *selectedShelf;
@property(nonatomic,retain) NSString *country;

+ (SearchController *)createController;

- (void)searchWithKeyword:(NSString*)keyword;
- (void)searchWithTitle:(NSString *)title withIndex:(NSString*)searchIndex;

- (void)showActivityIndicator;
- (void)dismissActivityIndicator;
	
@end

@interface SearchControllerAmazon : SearchController <AmazonApiDelegate>
{
}
@end
