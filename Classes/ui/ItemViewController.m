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

#import "ItemViewController.h"
#import "DataModel.h"
#import "WebViewController.h"
#import "WebApi.h"
#import "KeywordViewController.h"

@implementation ItemViewController

@synthesize itemArray, urlString;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.itemArray = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    NSString *title = NSLocalizedString(@"Item", @"");
    self.navigationItem.title = title;

    // アイテム移動用ボタン
    self.navigationItem.rightBarButtonItem =
	[[[UIBarButtonItem alloc]
             initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
             target:self
             action:@selector(moveActionButtonTapped:)]
            autorelease];
}

- (void)dealloc {
    for (Item *item in itemArray) {
        [item cancelDownload];
    }
    [itemArray release];
    [urlString release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateInfoStringsDict];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
    // イメージの全ロードを開始
    for (Item *item in itemArray) {
        [item getImage:self];
    }
}

- (void)checkAndAppendString:(NSMutableArray*)infoStrings value:(NSString *)value withName:(NSString *)name
{
    if (value != nil && value.length > 0) {
        [infoStrings addObject:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(name, @""), value]];
    }
}

- (void)didReceiveMemoryWarning {
    [Item clearAllImageCache];
    [super didReceiveMemoryWarning];
}

///////////////////////////////////////////////////////////////////////////////////////////////////// InfoString 処理

- (void)updateInfoStringsDict
{
    for (Item *item in itemArray) {
        item.infoStrings = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];

        [self checkAndAppendString:item.infoStrings value:item.author withName:@"Author"];
        [self checkAndAppendString:item.infoStrings value:item.manufacturer withName:@"Manufacturer"];
        [self checkAndAppendString:item.infoStrings value:item.price withName:@"Price"];
        [self checkAndAppendString:item.infoStrings value:NSLocalizedString(item.productGroup, @"") withName:@"Category"];
        [self checkAndAppendString:item.infoStrings value:item.idString withName:@"Code"];
        [self checkAndAppendString:item.infoStrings value:item.asin withName:@"ASIN"];
		
        NSLog(@"DEBUG: ProductGroup = %@", item.productGroup);
    }
}

- (NSMutableArray *)infoStrings:(int)index
{
    Item *item = [itemArray objectAtIndex:index];
    return item.infoStrings;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return itemArray.count;
}

// セクションタイトル : アイテム名
- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    Item *item = [itemArray objectAtIndex:section];
    return item.name;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    Item *item = [itemArray objectAtIndex:section];
	
    // 画像 + 詳細表示セル + 再検索 + 情報数
    return 3 + (item.registeredWithShelf ? 0 : 1) + item.infoStrings.count;
}

// セルの高さを返す
- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Item *item = [itemArray objectAtIndex:indexPath.section];
	
    if (indexPath.row == 0) {
        // 画像セル
        UIImage *image = [item getImage:nil];
        if (image) {
            return image.size.height + 20;
        }
    }
    return tv.rowHeight; // default
}

// セルを返す
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Item *item = [itemArray objectAtIndex:indexPath.section];
    NSMutableArray *infoStrings = [self infoStrings:indexPath.section];

    // 画像セル
    if (indexPath.row == 0) {
        return [self getImageCell:tv item:item];
    }

    // テキストセル
    UITableViewCell *cell;
    NSString *cellid = @"ItemViewTextCell";

    cell = [tv dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellid] autorelease];
    }
	
    if (indexPath.row == 1) {
        cell.text = NSLocalizedString(@"Show detail", @"");
        cell.font = [UIFont boldSystemFontOfSize:16.0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.row == 2) {
        cell.text = NSLocalizedString(@"Search again with title", @"");
        cell.font = [UIFont boldSystemFontOfSize:16.0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;        
    }
    else {
        int idx = indexPath.row - 3;
		
        if (!item.registeredWithShelf) {
            idx--;
        }
		
        if (idx == -1) {
            cell.text = NSLocalizedString(@"Add to shelf", @"");
            cell.font = [UIFont boldSystemFontOfSize:16.0];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.text = [infoStrings objectAtIndex:idx];
            cell.font = [UIFont boldSystemFontOfSize:14.0];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }

    return cell;
}

// 画像セルを返す
- (UITableViewCell *)getImageCell:(UITableView *)tv item:(Item *)item
{
    NSString *cellid = @"ItemViewImageCell";

    // 画像をロードする
    UIImage *image = [item getImage:self];
	
    // セルを生成する
    UITableViewCell *cell;
    UIImageView *imgView = nil;

    cell = [tv dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero
                                         reuseIdentifier:cellid] autorelease];
    } else {
        // 古い image view があれば捨てる
        imgView = (UIImageView *)[cell.contentView viewWithTag:1];
        if (imgView) {
            [imgView removeFromSuperview];
        }
    }

    // imgView を作る
    if (image) {
        int width = image.size.width;
        int height = image.size.height;
        imgView = [[[UIImageView alloc] initWithFrame:CGRectMake((320 - width) / 2, 10, width, height)] autorelease];
        imgView.image = image;

        imgView.tag = 1;
        imgView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin  | UIViewAutoresizingFlexibleRightMargin; // center
        imgView.contentMode = UIViewContentModeScaleAspectFit;
        imgView.backgroundColor = [UIColor clearColor];

        [cell.contentView addSubview:imgView];
        cell.contentView.contentMode = UIViewContentModeCenter;

    }

    return cell;
}

// イメージロード完了時の delegate
- (void)itemDidFinishDownloadImage:(Item*)item
{
    [tableView reloadData];
}

//
// セルをクリックしたときの処理
//
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tv deselectRowAtIndexPath:indexPath animated:NO];
	
    Item *item = [itemArray objectAtIndex:indexPath.section];

    if (indexPath.row == 1) {
        // 詳細を表示
        NSString *detailURL = [WebApiFactory detailUrl:item isMobile:YES];
        WebViewController *vc = [[[WebViewController alloc] initWithNibName:@"WebView" bundle:nil] autorelease];
        vc.urlString = detailURL;

        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (indexPath.row == 2) {
        // 再検索
        KeywordViewController *v = [KeywordViewController keywordViewController:NSLocalizedString(@"Title", @"")];
        v.selectedShelf = [[DataModel sharedDataModel] shelf:item.shelfId];
        v.initialText = item.name;

        //[self.navigationController popViewControllerAnimated:NO];
        [self.navigationController pushViewController:v animated:YES];
    }
    else if (indexPath.row == 3 && !item.registeredWithShelf) {
        // 棚に登録
        [[DataModel sharedDataModel] addItem:item];
        [tv reloadData];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////
// Shelf 変更処理

- (IBAction)moveActionButtonTapped:(id)sender
{
    NSMutableArray *shelves = [[DataModel sharedDataModel] normalShelves];
    NSMutableArray *shelfNames = [[NSMutableArray alloc] initWithCapacity:shelves.count];

    // 先頭のアイテム
    Item *item = [itemArray objectAtIndex:0];

    int i = 0, selectedIndex = 0;
    for (Shelf *shelf in shelves) {
        [shelfNames addObject:shelf.name];
        NSLog(@"%@", shelf.name);
        if (item.shelfId == shelf.pkey) {
            selectedIndex = i;
        }
        i++;
    }

    GenSelectListViewController *vc =
        [GenSelectListViewController
            genSelectListViewController:self
            array:shelfNames
            title:NSLocalizedString(@"Select shelf", @"")
            identifier:0
         ];
    vc.selectedIndex = selectedIndex;
    [shelfNames release];
	
    [self doModalWithNavigationController:vc];
}

- (void)genSelectListViewChanged:(GenSelectListViewController*)vc identifier:(int)id
{
    int selectedIndex = [vc selectedIndex];

    DataModel *dm = [DataModel sharedDataModel];
    Shelf *shelf = [[dm normalShelves] objectAtIndex:selectedIndex];
    for (Item *item in itemArray) {
        [dm changeShelf:item withShelf:shelf.pkey];	
    }
}

////////////////////////////////////////////////////////////////////////////////////////////
// Action Sheet 処理

- (IBAction)openActionButtonTapped:(id)sender
{
    NSString *label1 = NSLocalizedString(@"Send detail with e-mail", @"");
    NSString *label2 = NSLocalizedString(@"Open with Safari", @"");
	
    openActionSheet = [[UIActionSheet alloc]
                          initWithTitle:nil delegate:self
                          cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                          destructiveButtonTitle:nil
                          otherButtonTitles:label1, label2, nil];
    openActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [openActionSheet showInView:self.view];
    [openActionSheet release];
}

- (void)actionSheet:(UIActionSheet*)as clickedButtonAtIndex:(NSInteger)buttonIndex
{

    if (as == openActionSheet) {
        openActionSheet = nil;

        switch (buttonIndex) {
        case 0:
            // send e-mail
            [self sendMail];
            break;
        case 1:
            // open with safari
            [self openSafari];
            break;
        }
    }
}

#define REPLACE(str, x, y) [str replaceOccurrencesOfString:x withString:y options:NSLiteralSearch range:NSMakeRange(0, [str length])]

- (void)sendMail
{
    NSMutableString *body = [[[NSMutableString alloc] initWithCapacity:256] autorelease];

    // メールで送れるのは先頭の1個だけにしておく
    Item *item = [itemArray objectAtIndex:0];

    // タイトル
    [body appendString:item.name];
    [body appendString:@"\n\n"];
	
    // itemshelf リンク
    [body appendFormat:@"<a href='itemshelf://%@'>ItemShelf Link</a>", item.asin];
    [body appendString:@"\n\n"];
	
    // 詳細 URL
    NSString *detailURL = [WebApiFactory detailUrl:item isMobile:NO];
    [body appendFormat:@"<a href='%@'>Detail link of the item</a>", detailURL];
	
    // ここでいったん body を完全に　URL encode する
    NSString *tmp = [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [body setString:tmp];
	
    // mail body に　encode するため、& を置換する (stringByAdding... はこれはやってくれない)
    REPLACE(body, @"&", @"%26");

    LOG(@"BODY = %@", body);

    // 同様にして、Subject を作る
    NSMutableString *subject = [[[NSMutableString alloc] initWithCapacity:64] autorelease];
    [subject appendFormat:@"[ItemShelf] %@", item.name];
    tmp = [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [subject setString:tmp];
    REPLACE(subject, @"&", @"%26");

    // mailto URL を作る
    NSString *mailStr = [NSString stringWithFormat:@"mailto:?subject=%@&body=%@", subject, body];

    // メーラをキックする
    NSURL *url = [NSURL URLWithString:mailStr];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)openSafari
{
    Item *item = [itemArray objectAtIndex:0];
    NSString *detailURL = [WebApiFactory detailUrl:item isMobile:YES];
    NSURL *url = [NSURL URLWithString:[detailURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:url];
}


@end
