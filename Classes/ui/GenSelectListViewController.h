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
#import <Foundation/Foundation.h>
#import "Common.h"

@class GenSelectListViewController;

/**
   GenSelectListView delegate protocol
*/
@protocol GenSelectListViewDelegate
/**
   Called when list item is selected.
*/
- (void)genSelectListViewChanged:(GenSelectListViewController*)vc identifier:(int)id;
@end

/**
   Generic list selection view controller
*/
@interface GenSelectListViewController : UITableViewController
{
    id<GenSelectListViewDelegate> delegate;     ///< delegate
    int identifier;     ///< identifier of this controller (use can use this to identify)
	
    NSArray *list;      ///< list of options
    int selectedIndex;  ///< selected index of options list
}

@property(nonatomic,assign) id<GenSelectListViewDelegate> delegate;
@property(nonatomic,assign) int identifier;
@property(nonatomic,retain) NSArray *list;
@property(nonatomic,assign) int selectedIndex;

+ (GenSelectListViewController *)genSelectListViewController:(id<GenSelectListViewDelegate>)delegate array:(NSArray*)ary title:(NSString*)title identifier:(int)id;
- (id)init:(id<GenSelectListViewDelegate>)delegate array:(NSArray*)ary title:(NSString*)title identifier:(int)id;
- (void)_cancelAction:(id)sender;
- (NSString *)selectedString;

@end
