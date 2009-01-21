// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-

#import "TestUtility.h"

@interface ItemTest : SenTestCase {
    Database *db;
}

- (void)assertItemEquals:(Item *)i with:(Item *)j;

@end


@implementation ItemTest

- (void)setUp
{
    db = [Database instance];
}

- (void)tearDown
{
}

// テーブルがないときにテーブルが作成されること
- (void)testInitDb
{
    // テーブルを削除する
    [db exec:"DROP TABLE Item;"];
    [db release];

    // 再度オープンする (ここでテーブルができるはず）
    db = [Database instance];

    dbstmt *stmt = [db prepare:"SELECT sql FROM sqlite_master WHERE type='table' AND name='Item';"];
    STAssertEquals(SQLITE_ROW, [stmt step], @"No item table");
    NSString *sql = [stmt colString:0];

    // TBD: ここでテーブル定義をチェック

}

// テーブルのアップグレードテスト
// ver 1.0 からのアップグレードはまだないので、テスト不要

// Utility : Item の同一性確認
- (void)assertItemEquals:(Item *)i with:(Item *)j
{
    STAssertEquals(j.pkey, i.pkey, nil);
    STAssertEquals(j.shelfId, i.shelfId, nil);
    STAssertEquals(j.serviceId, i.serviceId, nil);
    STAssertEquals(j.sorder, i.sorder, nil);
    STAssertTrue([i.date isEqualToDate:j.date], @"%@ != %@", i.date, j.date);
    STAssertEqualStrings(j.idString, i.idString, nil);
    STAssertEqualStrings(j.asin, i.asin, nil);
    STAssertEqualStrings(j.name, i.name, nil);
    STAssertEqualStrings(j.author, i.author, nil);
    STAssertEqualStrings(j.manufacturer, i.manufacturer, nil);
    STAssertEqualStrings(j.category, i.category, nil);
    STAssertEqualStrings(j.detailURL, i.detailURL, nil);
    STAssertEqualStrings(j.price, i.price, nil);
    STAssertEqualStrings(j.tags, i.tags, nil);
    STAssertEqualStrings(j.memo, i.memo, nil);
    STAssertEqualStrings(j.imageURL, i.imageURL, nil);
}

// loadRow テスト
- (void)testLoadRow
{
    [TestUtility initializeTestDatabase];

    dbstmt *stmt = [db prepare:"SELECT * FROM Item WHERE pkey = ?;"];
    for (int i = 1; i <= NUM_TEST_ITEM; i++) {
        [stmt bindInt:0 val:i];
        STAssertTrue(SQLITE_ROW == [stmt step], nil);

        Item *item = [[Item alloc] init];
        STAssertTrue(!item.registeredWithShelf, nil);
        [item loadRow:stmt];

        // 比較対象データ
        Item *testItem = [TestUtility createTestItem:i];

        [self assertItemEquals:item with:testItem];

        STAssertEquals(YES, item.registeredWithShelf, nil);
        STAssertTrue(item.imageCache == nil, nil);

        [item release];
        [testItem release];

        [stmt reset];	
    }
}

// insert テスト
- (void)testInsert
{
    Item *item;

    [TestUtility clearDatabase];

    // 逆順で挿入
    for (int i = NUM_TEST_ITEM; i >= 1; i--) {
        item = [TestUtility createTestItem:i];

        // primary key と sorder をつぶしておく
        item.pkey = -1; 
        item.sorder = -1;

        [item insert];
        [item release];
    }

    // 読み込みテスト
    dbstmt *stmt = [db prepare:"SELECT * FROM Item WHERE pkey = ?;"];
    for (int i = 1; i <= NUM_TEST_ITEM; i++) {
        int pkey = NUM_TEST_ITEM - i + 1;
		
        [stmt bindInt:0 val:pkey];
        STAssertTrue(SQLITE_ROW == [stmt step], nil);

        Item* item = [[Item alloc] init];
        [item loadRow:stmt];

        // 比較対象データ
        Item *testItem = [TestUtility createTestItem:i];
        testItem.pkey = pkey;
        testItem.sorder = pkey;

        // チェック
        [self assertItemEquals:item with:testItem];

        [item release];
        [testItem release];

        [stmt reset];	
    }
}

// delete テスト
- (void)testDelete
{
    [TestUtility initializeTestDatabase];

    [db beginTransaction];
    dbstmt *stmt = [db prepare:"SELECT * FROM Item WHERE pkey = ?;"];
    for (int i = 1; i <= NUM_TEST_ITEM; i++) {
        [stmt bindInt:0 val:i];
        STAssertTrue(SQLITE_ROW == [stmt step], nil);

        Item *item = [[Item alloc] init];
        [item loadRow:stmt];

        // 削除する
        [item delete];
        [item release];
        [stmt reset];

        // データが消えていることを確認する。
        [stmt bindInt:0 val:i];
        STAssertTrue(SQLITE_DONE == [stmt step], nil);

        // イメージファイルも消去されていることを確認する
        // TBD

        [stmt reset];
    }
    [db commitTransaction];
}	

// changeShelf テスト
- (void)testChangeShelf
{
    [TestUtility initializeTestDatabase];

    [db beginTransaction];
    dbstmt *stmt = [db prepare:"SELECT * FROM Item WHERE pkey = ?;"];
    for (int i = 1; i <= NUM_TEST_ITEM; i++) {
        // item 読み込み
        [stmt bindInt:0 val:i];
        STAssertTrue(SQLITE_ROW == [stmt step], nil);
        Item *item = [[Item alloc] init];
        [item loadRow:stmt];

        // shelf 変更しない場合でも大丈夫なことを確認する
        int origShelfId = item.shelfId;
        [item changeShelf:origShelfId];
        STAssertEquals(origShelfId, item.shelfId, nil);

        // shelf 変更
        int newShelfId = (origShelfId + 1) % 3;
        [item changeShelf:newShelfId];
        STAssertEquals(newShelfId, item.shelfId, nil);
		
        // データベースが書き変わっていることを確認する
        [item release];
        [stmt reset];
        [stmt bindInt:0 val:i];
        STAssertTrue(SQLITE_ROW == [stmt step], nil);
        item = [[Item alloc] init];
        [item loadRow:stmt];

        STAssertTrue(newShelfId == item.shelfId, nil);
        [item release];
        [stmt reset];
    }
}

// updateSorder のテスト
- (void)testUpdateSorder
{
    [TestUtility initializeTestDatabase];

    [db beginTransaction];
    dbstmt *stmt = [db prepare:"SELECT * FROM Item WHERE pkey = ?;"];
    for (int i = 1; i <= NUM_TEST_ITEM; i++) {
        // item 読み込み
        [stmt bindInt:0 val:i];
        STAssertTrue(SQLITE_ROW == [stmt step], nil);
        Item *item = [[Item alloc] init];
        [item loadRow:stmt];

        // 逆順に並び替える
        int newSorder = NUM_TEST_ITEM - i + 1;
        item.sorder = newSorder;
        [item updateSorder];
		
        // データベースが書き変わっていることを確認する
        [item release];
        [stmt reset];
        [stmt bindInt:0 val:i];
        STAssertTrue(SQLITE_ROW == [stmt step], nil);
        item = [[Item alloc] init];
        [item loadRow:stmt];

        STAssertTrue(newSorder == item.sorder, nil);
        [item release];
        [stmt reset];
    }
}

//////////////////////////////////////////////////////////////////
// イメージ取得テスト

// getImage : imageURL が空のときに NoImage が返ること
- (void)testGetImageNoImage
{
    Item *item = [TestUtility createTestItem:1];

    // nil でテスト
    item.imageURL = nil;
    UIImage *noImage = [item getImage:nil]; // 本当にこれが noImage かどうかわからんけど
    STAssertNotNil(noImage, nil);
    STAssertNil(item.imageCache, nil); // キャッシュされていないことを確認

    // 再び nil でテスト
    STAssertTrue(noImage == [item getImage:nil], nil);
    STAssertNil(item.imageCache, nil);
	
    // 空文字列でテスト
    item.imageURL = @"";
    STAssertEquals(noImage, [item getImage:nil], nil);
    STAssertNil(item.imageCache, nil);

    [item release];
}

// getImage : メモリ上にキャッシュされている場合はこれを返すこと
// また、イメージキャッシュをクリアすると消えること
- (void)testGetImageOnCache
{
    Item *item = [TestUtility createTestItem:1];
	
    item.imageURL = @"DUMMY";
    UIImage *cached = [[UIImage alloc] init];
    item.imageCache = cached;

    // テスト
    //   image cache の refresh の確認をこめて回数回す
    for (int i = 0; i < 100; i++) {
        STAssertEquals(cached, [item getImage:nil], nil);
    }

    [Item clearAllImageCache];
    STAssertNil([item getImage:nil], nil);

    [cached release];
    [item release];
}

// イメージキャッシュテスト
- (void)testImageCache
{
    int i;
    NSMutableArray *items = [[NSMutableArray alloc] init];
    UIImage *testImage = [[UIImage alloc] init];

    [Item clearAllImageCache];

    for (i = 1; i <= MAX_IMAGE_CACHE_AGE * 2; i++) {
        // item 生成
        Item *item = [TestUtility createTestItem:i];
        [items addObject:item];

        // キャッシュに入れる
        item.imageURL = @"DUMMY";
        item.imageCache = testImage;
        [item _putImageCache];

        [item release];
    }

    // testImage のリファレンスカウンタ確認
    int r = [testImage retainCount];
    STAssertEquals(MAX_IMAGE_CACHE_AGE + 1, r, nil);

    // キャッシュ状況を確認
    for (i = 1; i <= MAX_IMAGE_CACHE_AGE; i++) {
        Item *item = [items objectAtIndex:i-1];
        STAssertNil(item.imageCache, nil);
    }
    for (i = MAX_IMAGE_CACHE_AGE + 1; i <= MAX_IMAGE_CACHE_AGE * 2; i++) {
        Item *item = [items objectAtIndex:i-1];
        STAssertEquals(testImage, item.imageCache, nil);
    }

    // キャッシュ全クリア
    [Item clearAllImageCache];

    // testImage のリファレンスカウンタが 1 に戻っていることを確認
    r = [testImage retainCount];
    STAssertEquals(1, r, nil);

    [items release];
    [testImage release];
}

// getImage: ファイルキャッシュからイメージがロードされることを確認する
//  このさい、キャッシュに登録されることも確認する
- (void)testGetImageFromFileCache
{
    // TBD
}

// fetchImage : imageCache が有る場合は YES が返ること

// fetchImage : imageURL が空のときは YES が返ること

// fetchImage : ダウンロード中の場合は NO が返ること　（テスト不能？？？）

// fetchImage : キャッシュファイルがある場合は YES が返ること

// fetchImage : キャッシュがない場合は、ネットワークからダウンロードすること (テスト不能？）

// cancelDownload

@end
