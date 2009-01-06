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

#import <UIKit/UIKit.h>
#import "WebApi.h"
#import "Shelf.h"

@class SearchController;

@protocol SearchControllerDelegate
- (void)searchControllerFinish:(SearchController*)controller result:(BOOL)result;
@end

/**
  Search Controller

  This class execute item search with web API, and show result with ItemView.
  Also execute some UI control (activity indicator etc.)

  To use this, create instance with createController method, set up
  properties, then call searchXXX method. 
  Following properties should be set.

  - delegate (option) : Delegate to callback when search finished.
  - viewController (mandatory) : Current view controller.
  - selectedShelf (option) : Current selected shelf.
  - country (option) : Country code to search.

  This is abstract class. You must inherit this class and override
  searchWithKeyword: and searchWithTitle:withIndex: method.
*/
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

- (void)_showActivityIndicator;
- (void)_dismissActivityIndicator;
	
@end
