// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-

#import "GTMSenTestCase.h"
#import "Database.h"
#import "DataModel.h"
#import "Shelf.h"
#import "Item.h"

#define NUM_TEST_SHELF 10
#define NUM_TEST_ITEM	100

@interface TestUtility : NSObject {
}

+ (void)clearDatabase;
+ (void)initializeTestDatabase;
+ (Shelf *)createTestShelf:(int)id;
+ (Item *)createTestItem:(int)id;

@end
