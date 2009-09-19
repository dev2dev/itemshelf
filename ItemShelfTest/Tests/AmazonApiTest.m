// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-

#import "TestUtility.h"
#import "AmazonApi.h"

@interface AmazonApiTest : SenTestCase <AmazonApiDelegate> {
    AmazonApi *amazon;
    int testNumber;
}
@end


@implementation AmazonApiTest

- (void)setUp
{
    amazon = [[AmazonApi alloc] init];
    amazon.delegate = self;
}

- (void)testAlloc
{
    [amazon release];
}

- (void)amazonApiDidFinish:(AmazonApi *)amazon items:(NSMutableArray *)itemArray
{
    NSLog(@"AmazonApiDidFinish");
}

- (void)amazonApiDidFailed:(AmazonApi *)amazon reason:(int)reason message:(NSString *)message
{
    NSLog(@"AmazonApiDidFailed");
}


// TBD このテストプログラムではダメ。
//  Network からのダウンロードは、処理終了時に mainloop から　コールバックで返ってくるが、
// テスト項目はこの関数のコンテキストの中で完結していなければならないため。
- (void)testIsbnSearch
{
    testNumber = 1;

    amazon.searchKeyword = @"9784774135984";
    amazon.delegate = self;
    //[amazon setCountry:nil];
    [amazon itemSearch];
}

@end
