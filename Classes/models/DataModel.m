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
#import "DataModel.h"
#import "StringArray.h"

@implementation DataModel

@synthesize shelves;

static DataModel *theDataModel = nil; // singleton

+ (DataModel*)sharedDataModel
{
    if (theDataModel == nil) {
        theDataModel = [[DataModel alloc] init];
    }
    return theDataModel;
}

- (id)init
{
    self = [super init];
    if (self) {
        shelves = [[NSMutableArray alloc] initWithCapacity:10];
    }
	
    countries = [[NSArray arrayWithObjects:@"US", @"UK", @"CA", @"FR", @"DE", @"JP", nil] retain];

    // load setting
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    currentCountry = [defaults stringForKey:@"Country"];
    if (currentCountry == nil) {
        currentCountry = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    }
    [currentCountry retain];
    return self;
}

- (void)dealloc
{
    [shelves release];
    [currentCountry release];
    [countries release];

    [super dealloc];
}

///////////////////////////////////////////////////////////////////
// Shelf 操作

- (Shelf *)shelf:(int)shelfId
{
    for (Shelf *shelf in shelves) {
        if (shelf.pkey == shelfId) {
            return shelf;
        }
    }
    return nil;
}

- (Shelf *)shelfAtIndex:(int)index
{
    ASSERT(index < shelves.count);
    return [shelves objectAtIndex:index];
}

- (int)shelvesCount
{
    return [shelves count];
}

- (void)addShelf:(Shelf *)shelf
{
    [shelves addObject:shelf];
    [shelf insert];
}

- (void)removeShelf:(Shelf *)shelf
{
    [shelf delete];
    [shelves removeObject:shelf];

    [self updateSmartShelves];
}

- (void)reorderShelf:(int)from to:(int)to
{
    Shelf *shelf = [[shelves objectAtIndex:from] retain];
    [shelves removeObjectAtIndex:from];
    [shelves insertObject:shelf atIndex:to];
    [shelf release];
	
    // renumber sorder
    Database *db = [Database instance];
    [db beginTransaction];

    int n = 0;
    for (int i = 0; i < shelves.count; i++) {
        shelf = [shelves objectAtIndex:i];
        if (shelf.pkey != SHELF_ALL_PKEY) {
            if (shelf.sorder != n) {
                shelf.sorder = n;
                [shelf updateSorder];
            }
            n++;
        }
    }
    [db commitTransaction];
}

- (NSMutableArray *)normalShelves
{
    NSMutableArray *ary = [[[NSMutableArray alloc] initWithCapacity:10] autorelease];
    for (Shelf *shelf in shelves) {
        if (shelf.shelfType == ShelfTypeNormal) {
            [ary addObject:shelf];
        }
    }
    return ary;
}

- (void)updateSmartShelves
{
    for (Shelf *shelf in shelves) {
        if (shelf.shelfType != ShelfTypeNormal) {
            [shelf updateSmartShelf:shelves];
        }
    }
}

///////////////////////////////////////////////////////////////////
// Item 操作

- (void)addItem:(Item *)item
{
    Shelf *shelf = [self shelf:item.shelfId];
    ASSERT(shelf.shelfType == ShelfTypeNormal);
	
    [shelf addItem:item];
    [item insert]; // add database
	
    item.registeredWithShelf = YES;

    [self updateSmartShelves];
}

- (void)removeItem:(Item *)item
{
    [item delete];

    for (int i = 0; i < shelves.count; i++) {
        Shelf *shelf = [shelves objectAtIndex:i];
        if ([shelf containsItem:item]) {
            [shelf removeItem:item];
        }
    }

    [self updateSmartShelves];
}

- (void)changeShelf:(Item *)item withShelf:(int)shelf
{
    if (item.shelfId == shelf) {
        return; // do nothing
    }

    Shelf *oldShelf = [self shelf:item.shelfId];
    Shelf *newShelf = [self shelf:shelf];

    ASSERT(oldShelf.shelfType == ShelfTypeNormal);
    ASSERT(newShelf.shelfType == ShelfTypeNormal);

    [oldShelf removeItem:item];
    [newShelf addItem:item];
    [newShelf sortBySorder];

    [item changeShelf:shelf];

    [self updateSmartShelves];
}

// make filter
- (NSMutableArray *)makeFilter:(Shelf *)shelf
{
    NSMutableArray *filters = [[NSMutableArray alloc] initWithCapacity:10];
	
    Item *item;
    for (item in shelf) {
        if ([filters findString:item.productGroup] < 0) {
            [filters addObject:item.productGroup];
        }
    }

    // sort filter
    [filters sortByString];

    // 先頭に追加
    [filters insertObject:@"All" atIndex:0];
	
    return filters;
}

// 同一アイテムを全棚から検索
- (Item *)findSameItem:(Item*)item
{
    for (int i = 0; i < shelves.count; i++) {
        Shelf *shelf = [shelves objectAtIndex:i];
        if (shelf.shelfType != ShelfTypeNormal) continue;

        for (Item *x in shelf) {
            if ([item isEqualToItem:x]) {
                return x;
            }
        }
    }
    return nil;
}

////////////////////////////////////////////////////////////////
// Database operation

- (void)loadDB
{
    Database *db = [Database instance];

    dbstmt *stmt;

    // All Shelf を追加しておく
    Shelf *shelf;
    shelf = [[Shelf alloc] init];
    shelf.pkey = SHELF_ALL_PKEY;
    shelf.name = NSLocalizedString(@"All", @"");
    shelf.shelfType = ShelfTypeSmart;
    shelf.sorder = -1;
    [shelves addObject:shelf];
    [shelf release];

    // load shelves
    stmt = [db prepare:"SELECT * FROM Shelf ORDER BY sorder;"];
    while ([stmt step] == SQLITE_ROW) {
        shelf = [[Shelf alloc] init];
        [shelf loadRow:stmt];
        [shelves addObject:shelf];
        [shelf release];
    }
    [stmt release];

    // load items
    stmt = [db prepare:"SELECT * FROM Item ORDER BY sorder,date;"];
    while ([stmt step] == SQLITE_ROW) {
        Item *item = [[Item alloc] init];
        [item loadRow:stmt];

        Shelf *shelf = [self shelf:item.shelfId];
        [shelf addItem:item];
        [item release];
    }
    [stmt release];

    [self updateSmartShelves];
}


////////////////////////////////////////////////////////////////
// Configuration

- (NSArray*)countries
{
    return countries;
}

// 国コードを返す
- (NSString *)country
{
    return currentCountry;
}

// 国コードをセットする
- (void)setCountry:(NSString *)country
{
    if (currentCountry == country) {
        return;
    }
    [currentCountry release];
    currentCountry = [country retain];
	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:currentCountry forKey:@"Country"];
}

@end
