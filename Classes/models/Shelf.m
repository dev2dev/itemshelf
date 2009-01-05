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

// 棚クラス

#import "Item.h"
#import "Shelf.h"


@implementation Shelf
@synthesize array, pkey, name, sorder, shelfType, titleFilter, authorFilter, manufacturerFilter;

- (id)init
{
    self = [super init];
    if (self) {
        self.name = nil;
        self.array = [[NSMutableArray alloc] initWithCapacity:30];
        self.shelfType = ShelfTypeNormal;
        self.titleFilter = @"";
        self.authorFilter = @"";
        self.manufacturerFilter = @"";
    }
    return self;
}

- (void)dealloc
{
    [array release];
    [name release];
    [titleFilter release];
    [authorFilter release];
    [manufacturerFilter release];

    [super dealloc];
}

/**
   Add item to shelf
*/
- (void)addItem:(Item*)item
{
    [array addObject:item];
}

/**
   Remove item from shelf
*/
- (void)removeItem:(Item*)item
{
    [array removeObject:item];
}

/**
   Check if the item is contained in this shelf.

   @return Returns YES if the item is contained.
*/
- (BOOL)containsItem:(Item*)item
{
    return [array containsObject:item];
}

/**
   NSFastEnumeration protocol
*/
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
    return [array countByEnumeratingWithState:state objects:stackbuf count:len];
}
 
/**
   Used from sortBySorder (private)
*/
static int compareBySorder(Item *t1, Item *t2, void *context)
{
    if (t1.sorder == t2.sorder) {
        return [t1.date compare:t2.date];
    }
    if (t1.sorder < t2.sorder) {
        return NSOrderedAscending;
    }
    return NSOrderedDescending;
}

/**
   Sort items which sorder
*/
- (void)sortBySorder
{
    [array sortUsingFunction:compareBySorder context:NULL];
}

///////////////////////////////////////////////////////////////
// データベース処理

/**
   Create/upgrade Shelf table in the database.

   If no table exist, create now.
   If the table is old format, upgrade it.
*/
+ (void)checkTable
{
    Database *db = [Database instance];
    dbstmt *stmt;

    // テーブルの scheme をチェック
    // sqlite_master テーブルから table 一覧と schema をチェックする
    BOOL isNew = NO;
    stmt = [db prepare:"SELECT sql FROM sqlite_master WHERE type='table' AND name='Shelf';"];
    if ([stmt step] != SQLITE_ROW) {
        isNew = YES;
    } else {
        /* upgrade check */
        NSString *tablesql = [stmt colString:0];

        // Ver 1.1 からの upgrade
        NSRange range = [tablesql rangeOfString:@"titleFilter"];
        if (range.location == NSNotFound) {
            [db exec:"ALTER TABLE Shelf ADD COLUMN type INTEGER;"];
            [db exec:"ALTER TABLE Shelf ADD COLUMN titleFilter TEXT;"];
            [db exec:"ALTER TABLE Shelf ADD COLUMN authorFilter TEXT;"];
            [db exec:"ALTER TABLE Shelf ADD COLUMN manufacturerFilter TEXT;"];

            [db exec:"UPDATE Shelf SET type = 0;"];
        }
    }
    [stmt release];

    if (!isNew) return;

    // テーブル新規作成
    [db exec:"CREATE TABLE Shelf ("
        "pkey INTEGER PRIMARY KEY,"
        "name TEXT,"
        "sorder INTEGER,"
        "type INTEGER,"
        "titleFilter TEXT,"
        "authorFilter TEXT,"
        "manufacturerFilter TEXT"
        ");"
     ];

    // 初期データを入れる
    for (int i = 0; i < 3; i++) {
        NSString *name;
        switch (i) {
        case 0:
            name = @"Unclassified";
            break;
        case 1:
            name = @"Wishlist";
            break;
        case 2:
            name = @"ItemShelf";
            break;
        }

        stmt = [db prepare:"INSERT INTO Shelf VALUES(?, ?, ?, 0, NULL, NULL, NULL);"];
        [stmt bindInt:0 val:i];
        [stmt bindString:1 val:NSLocalizedString(name, @"")];
        [stmt bindInt:2 val:i];
        [stmt step];
        [stmt release];
    }
}

/**
   Load row of shelf table of the database.
*/
- (void)loadRow:(dbstmt *)stmt
{
    self.pkey   = [stmt colInt:0];
    self.name   = [stmt colString:1];
    self.sorder = [stmt colInt:2];
    self.shelfType   = [stmt colInt:3];
    self.titleFilter        = [stmt colString:4];
    self.authorFilter       = [stmt colString:5];
    self.manufacturerFilter = [stmt colString:6];

    NSLog(@"%d %@ %d %d %@ %@ %@", self.pkey, self.name, self.sorder,
          self.shelfType, self.titleFilter, self.authorFilter, self.manufacturerFilter);
}

/**
   Insert row to shelf table of the database.
*/
- (void)insert
{
    Database *db = [Database instance];
	
    [db beginTransaction];
	
    dbstmt *stmt = [db prepare:"INSERT INTO Shelf VALUES(NULL, ?, -1, ?, ?, ?, ?);"];
    [stmt bindString:0 val:name];
    [stmt bindInt:1    val:shelfType];
    [stmt bindString:2 val:titleFilter];
    [stmt bindString:3 val:authorFilter];
    [stmt bindString:4 val:manufacturerFilter];

    [stmt step];
    [stmt release];

    self.pkey = [db	lastInsertRowId];
    self.sorder = pkey;  // 初期並び順は Primary Key と同じにしておく(最大値)
    [self updateSorder];
	
    [db commitTransaction];
}

/**
   Delete row from shelf table of the database.
*/
- (void)delete
{
    Database *db = [Database instance];

    [db beginTransaction];

    const char *sql = "DELETE FROM Shelf WHERE pkey = ?;";
    dbstmt *stmt = [db prepare:sql];

    [stmt bindInt:0 val:pkey];
    [stmt step];
    [stmt release];
	
    // この棚にあるアイテムも全部消す
    if (shelfType == ShelfTypeNormal) {
        for (Item *item in array) {
            [item delete];
        }
    }

    [db commitTransaction];
}

/**
   Update shelf name of the database.
*/
- (void)updateName
{
    const char *sql = "UPDATE Shelf SET name = ? WHERE pkey = ?;";
    dbstmt *stmt = [[Database instance] prepare:sql];
	
    [stmt bindString:0 val:name];
    [stmt bindInt:1 val:pkey];
    [stmt step];
    [stmt release];
}

/**
   Update sorder name of the database.
*/
- (void)updateSorder
{
    const char *sql = "UPDATE Shelf SET sorder = ? WHERE pkey = ?;";
    dbstmt *stmt = [[Database instance] prepare:sql];
	
    [stmt bindInt:0 val:sorder];
    [stmt bindInt:1 val:pkey];
    [stmt step];
    [stmt release];
}

/**
   Update smart filters of the database.
*/
- (void)updateSmartFilters
{
    const char *sql = "UPDATE Shelf SET titleFilter = ?, authorFilter = ?, manufacturerFilter = ? WHERE pkey = ?;";
    dbstmt *stmt = [[Database instance] prepare:sql];
	
    [stmt bindString:0 val:titleFilter];
    [stmt bindString:1 val:authorFilter];
    [stmt bindString:2 val:manufacturerFilter];
    [stmt bindInt:3 val:pkey];
    [stmt step];
    [stmt release];
}

@end
