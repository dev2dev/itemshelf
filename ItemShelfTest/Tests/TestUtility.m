// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-

#import "TestUtility.h"
#import "Database.h"
#import "Item.h"

@implementation TestUtility

+ (void)clearDatabase
{
    Database *db = [Database instance];
    // ここでデータベースが初期化されている(はず)

    [db exec:"DELETE FROM Item;"];
    [db exec:"DELETE FROM Shelf;"];
}

// テストデータを作成する
+ (void)initializeTestDatabase
{
    [TestUtility clearDatabase];

    Database *db = [Database instance];
    [db beginTransaction];

    int i;
    dbstmt *stmt;

    stmt = [db prepare:"INSERT INTO Shelf VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?);"];
    for (i = 1; i <= NUM_TEST_SHELF; i++) {
        Shelf *shelf = [TestUtility createTestShelf:i];

        [stmt bindInt:0 val:shelf.pkey];
        [stmt bindString:1 val:shelf.name];
        [stmt bindInt:2 val:shelf.sorder];
        [stmt bindInt:3 val:shelf.shelfType];
        [stmt bindString:4 val:shelf.titleFilter];
        [stmt bindString:5 val:shelf.authorFilter];
        [stmt bindString:6 val:shelf.manufacturerFilter];
        [stmt bindString:7 val:shelf.tagsFilter];
        [stmt bindInt:8 val:shelf.starFilter];
        [stmt step];
        [stmt reset];

        [shelf release];
    }

    stmt = [db prepare:"INSERT INTO Item VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"];
    for (i = 1; i <= NUM_TEST_ITEM; i++) {
        Item *item = [TestUtility createTestItem:i];

        [stmt bindInt:0 val:item.pkey];
        [stmt bindDate:1 val:item.date];
        [stmt bindInt:2 val:item.shelfId];
        [stmt bindInt:3 val:item.serviceId];
        [stmt bindString:4 val:item.idString];
        [stmt bindString:5 val:item.asin];
        [stmt bindString:6 val:item.name];
        [stmt bindString:7 val:item.author];
        [stmt bindString:8 val:item.manufacturer];
        [stmt bindString:9 val:item.category];
        [stmt bindString:10 val:item.detailURL];
        [stmt bindString:11 val:item.price];
        [stmt bindString:12 val:item.tags];
        [stmt bindString:13 val:item.memo];
        [stmt bindString:14 val:item.imageURL];
        [stmt bindInt:15 val:item.sorder];
        [stmt bindInt:16 val:item.star];
        [stmt step];
        [stmt reset];

        [item release];
    }
    [db commitTransaction];
}

// テストデータ生成 (Shelf)
+ (Shelf *)createTestShelf:(int)id
{
    Shelf *shelf = [[Shelf alloc] init];

    shelf.pkey = id;
    shelf.sorder = id;
    shelf.name = [NSString stringWithFormat:@"棚%d", id];
    switch ((id - 1) % 5) {
    case 0:
        shelf.shelfType = ShelfTypeNormal;
        break;
    case 1:
        shelf.shelfType = ShelfTypeSmart;
        break;
    case 2:
        shelf.shelfType = ShelfTypeSmart;
        shelf.titleFilter = @"アイテム";
        break;
    case 3:
        shelf.shelfType = ShelfTypeSmart;
        shelf.authorFilter = @"著者番号";
        break;
    case 4:
        shelf.shelfType = ShelfTypeSmart;
        shelf.manufacturerFilter = @"製造者";
        break;
    }
    return shelf;
}

// テストデータ生成 (Item)
+ (Item *)createTestItem:(int)id
{
    Item *item = [[Item alloc] init];

    item.pkey = id;
    item.date = [NSDate dateWithTimeIntervalSince1970:id*10000.0 * 60.0];
    item.shelfId = (id % NUM_TEST_SHELF) + 1;
    item.serviceId = -1;
    item.idString = [NSString stringWithFormat:@"12345%5d", id];
    item.asin = [NSString stringWithFormat:@"ASIN%04d", id];
    item.name = [NSString stringWithFormat:@"アイテムNo.%d", id];
    item.author = [NSString stringWithFormat:@"著者番号%d", id];
    item.manufacturer = [NSString stringWithFormat:@"製造者%d", id];
    switch (id % 4) {
    case 0:
        item.category = @"Books";
        break;
    case 1:
        item.category = @"Electronics";
        break;
    case 2:
        item.category = @"Music";
        break;
    case 3:
        item.category = @"VideoGames";
        break;
    }
    item.price = [NSString stringWithFormat:@"￥ %d", id*1000];
    item.detailURL = [NSString stringWithFormat:@"http://itemshelf.com/dummyDetail?id=%d", id];
    item.imageURL = [NSString stringWithFormat:@"http://itemshelf.com/dummyImage%d.jpg", id];
    item.sorder = id;
    item.star = 0;

    return item;
}

@end
