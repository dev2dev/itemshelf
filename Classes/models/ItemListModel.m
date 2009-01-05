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

#import "ItemListModel.h"
#import "DataModel.h"

@implementation ItemListModel

@synthesize shelf;

/**
   Initialize the model with specified shelf

   @param[in] sh Shelf
   @return initialized instance
*/
- (id)initWithShelf:(Shelf *)sh
{
    self = [super init];

    shelf = [sh retain];
    searchText = nil;
    filter = nil;
    filteredList = [[NSMutableArray alloc] initWithCapacity:50];

    [self updateFilter];

    return self;
}

- (void)dealloc {
    [shelf release];
    [filteredList release];
    [filter release];
    [searchText release];
    [super dealloc];
}

/**
   Returns number of filtered items
*/
- (int)count
{
    return [filteredList count];
}

/**
   Get the item at index in filtered items.

   @param[in] index Index of the item.
   @note The index is reversed order.
*/
- (Item *)itemAtIndex:(int)index
{
    int n = [filteredList count] - 1 - index;
    if (n < 0) {
        ASSERT(NO);
        return nil;
    }
    Item *item = [filteredList objectAtIndex:n];
    return item;
}

/**
   Returns current filter string
*/
- (NSString*)filter
{
    return filter;
}

/**
   Set filter string.

   @param[in] f Filter string
*/
- (void)setFilter:(NSString *)f
{
    if (filter != f) {
        [filter release];
        filter = [f retain];
        [self updateFilter];
    }
}

/**
   Set search string.

   @param[in] t Search string
*/
- (void)setSearchText:(NSString *)t
{
    if (searchText != t) {
        [searchText release];
        searchText = [t retain];
        [self updateFilter];
    }
}

/**
   Update filtered items (private)
*/
- (void)updateFilter
{
    ASSERT(shelf);

    [filteredList removeAllObjects];
	
    Item *item;
    for (item in shelf) {
        // フィルタチェック
        if (filter != nil && ![item.productGroup isEqualToString:filter]) {
            continue;
        }
		
        // 検索テキストチェック
        if (searchText != nil && searchText.length > 0) {
            BOOL match = NO;
            NSRange range;
			
            range = [item.name rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound) match = YES;

            range = [item.author rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound) match = YES;
			
            range = [item.manufacturer rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound) match = YES;
			
            if (!match) continue;
        }

        [filteredList addObject:item];
    }
}

/**
   Remove item from the model
*/
- (void)removeObject:(Item *)item
{
    [filteredList removeObject:item];
    [[DataModel sharedDataModel] removeItem:item];
}

/**
   Move item order

   @param[in] fromIndex Index from which the item move.
   @param[in] toIndex Index to which the item move.

   @note Item data of original shelf will be sorted too.
*/
- (void)moveRowAtIndex:(int)fromIndex toIndex:(int)toIndex
{
    // filteredList の中のインデックスを計算
    int from = [filteredList count] - 1 - fromIndex;
    int to   = [filteredList count] - 1 - toIndex;

    if (from == to) {
        return;
    }
	
    // リスト内の入れ替えを実施
    Item *item = [[filteredList objectAtIndex:from] retain];
    [filteredList removeObjectAtIndex:from];
    [filteredList insertObject:item atIndex:to];
    [item release];
	
    // sorder を入れ替える
    [[Database instance] beginTransaction];
    if (to < from) {
        Item *a, *b = nil;
        for (int i = to; i < from; i++) {
            a = [filteredList objectAtIndex:i];
            b = [filteredList objectAtIndex:i+1];
            int tmp = a.sorder;
            a.sorder = b.sorder;
            b.sorder = tmp;
			
            [a updateSorder];
        }
        ASSERT(b);
        [b updateSorder];
    } else {
        Item *a, *b = nil;
        for (int i = to; i > from; i--) {
            a = [filteredList objectAtIndex:i];
            b = [filteredList objectAtIndex:i-1];
            int tmp = a.sorder;
            a.sorder = b.sorder;
            b.sorder = tmp;
			
            [a updateSorder];
        }
        ASSERT(b);
        [b updateSorder];
    }
    [[Database instance] commitTransaction];
	
    // Filter されたデータだけでなく、元データをソートしておく必要がある。
    // TBD : SmartShelf の場合、元データがどこにあるのかわからないので、
    // 全部の棚をソートしなければならない。
    for (Shelf *s in [[DataModel sharedDataModel] shelves]) {
        [s sortBySorder];
    }
}

@end
