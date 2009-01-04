// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-

#import "TestUtility.h"
#import "DataModel.h"

@interface DataModelTest : SenTestCase {
    Database *db;
    DataModel *dm;
}
@end

@implementation DataModelTest

- (void)setUp
{
    db = [Database instance];
    //	[TestUtility initializeTestDatabase];
    dm = [DataModel sharedDataModel];
}

- (void)tearDown
{
    //	[dm release];
}

- (void)testLoadDB
{
#if 0
    [dm loadDB];

    // 先頭に All Shelf があることを確認する
    STAssertTrue([dm shelvesCount] >= 1, nil); // TBD
    Shelf *shelf = [dm shelfAtIndex:0];
    STAssertNotNil(shelf, nil);
#endif
}

@end
