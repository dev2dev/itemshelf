// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-

#import "TestUtility.h"

@interface ShelfTest : SenTestCase {
    Database *db;
}
@end

@implementation ShelfTest

- (void)setUp
{
    db = [Database instance];
}

- (void)testAlloc
{
}

// テーブルがないときにテーブルが作成されること
- (void)testInitDb
{
    // テーブルを削除する
    [db exec:"DROP TABLE Shelf;"];
    [db release];

    // 再度オープンする (ここでテーブルができるはず）
    db = [Database instance];
	
    // テーブル定義確認
    dbstmt *stmt = [db prepare:"SELECT sql FROM sqlite_master WHERE type='table' AND name='Shelf';"];
    int result = [stmt step];
    STAssertEquals(SQLITE_ROW, result, @"No shelf table");
    NSString *sql = [stmt colString:0];

    // TBD: ここでテーブル定義をチェック
    NSLog(@"%@", sql);
    [stmt release];
}

// テーブルのアップグレードテスト
- (void)testUpgradeDbFrom1_0
{
    // ver 1.0 テーブルを作成
    [db exec:"DROP TABLE Shelf;"];
    [db exec:"CREATE TABLE Shelf (pkey INTEGER PRIMARY KEY, name TEXT, sorder INTEGER);"];
    [db release];

    // 再ロード
    db = [Database instance];

    // テーブル定義確認
    dbstmt *stmt = [db prepare:"SELECT sql FROM sqlite_master WHERE type='table' AND name='Shelf';"];
    STAssertEquals(SQLITE_ROW, [stmt step], @"No shelf table");
    NSString *sql = [stmt colString:0];

    // ここでテーブル定義をチェック
    NSLog(@"%@", sql);
    NSRange range = [sql rangeOfString:@"manufacturerFilter"];
    STAssertTrue(range.location != NSNotFound, @"Bad shelf table");

    [stmt release];
}	

- (void)assertShelfEquals:(Shelf*)i with:(Shelf*)j
{
    STAssertEquals(j.pkey, i.pkey, nil);
    STAssertEquals(j.shelfType, i.shelfType, nil);
    STAssertEquals(j.sorder, i.sorder, nil);
    STAssertEqualStrings(j.name, i.name, nil);
    STAssertEqualStrings(j.titleFilter, i.titleFilter, nil);
    STAssertEqualStrings(j.authorFilter, i.authorFilter, nil);
    STAssertEqualStrings(j.manufacturerFilter, i.manufacturerFilter, nil);
}

// loadRow テスト
- (void)testLoadRow
{
    [TestUtility initializeTestDatabase];

    dbstmt *stmt = [db prepare:"SELECT * FROM Shelf WHERE pkey = ?;"];
    for (int i = 1; i <= NUM_TEST_SHELF; i++) {
        [stmt bindInt:0 val:i];
        STAssertTrue(SQLITE_ROW == [stmt step], nil);

        Shelf *shelf = [[Shelf alloc] init];
        [shelf loadRow:stmt];

        // 比較対象データ
        Shelf *testShelf = [TestUtility createTestShelf:i];

        [self assertShelfEquals:shelf with:testShelf];

        [shelf release];
        [testShelf release];

        [stmt reset];	
    }
    [stmt release];
}

// insert テスト
// delete テスト
// updateName テスト
// updateSorder テスト
// updateSmartFilters テスト

// addItem
// removeItem
// containsItem
// enumeration テスト
// sortBySorder テスト
	
@end
