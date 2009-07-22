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

// アイテム一覧モデル
//   ItemListViewController で使用

#import <UIKit/UIKit.h>
#import "Common.h"
#import "Shelf.h"
#import "Item.h"
#import "StringArray.h"

/**
   Item list model, used from ItemListViewController

   This model contains array of items, "filtered" with
   search string and category.
*/
@interface ItemListModel : NSObject
{
    Shelf *shelf;		///< Shelf
	
    NSString *filter;		///< Filter string (if nil, no filter)
    NSString *searchText;	///< Search string

    NSMutableArray *filteredList; ///< Filtered array of items.
}

@property(nonatomic,readonly) Shelf *shelf;
@property(nonatomic,retain) NSString *filter;

- (id)initWithShelf:(Shelf *)shelf;
- (int)count;
- (Item *)itemAtIndex:(int)index;
- (void)setSearchText:(NSString *)t;
- (void)setFilter:(NSString *)f;
- (void)updateFilter;
- (void)removeObject:(Item *)item;
- (void)moveRowAtIndex:(int)fromIndex toIndex:(int)toIndex;
- (void)sort:(int)kind;

@end
