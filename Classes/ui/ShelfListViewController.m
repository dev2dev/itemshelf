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

#import "ShelfListViewController.h"
#import "DataModel.h"
#import "ItemListViewController.h"
#import "ScanViewController.h"
#import "ConfigViewController.h"
#import "Edition.h"
#import "AdCell.h"

@implementation ShelfListViewController

@synthesize tableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // title 設定
    self.title = NSLocalizedString(@"Shelves", @"");
	
    // 棚追加ボタンを追加
#if 0
    UIBarButtonItem *plusButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                      target:self
                                      action:@selector(addShelf:)];
    self.navigationItem.leftBarButtonItem = plusButton;
    [plusButton release];
#endif

	
    // Edit ボタンを追加
    self.navigationItem.rightBarButtonItem = [self editButtonItem];
	
    // イメージロード
    if (normalShelfImage == nil) {
        normalShelfImage = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ShelfNormal" ofType:@"png"]] retain];
    }
    if (smartShelfImage == nil) {
        smartShelfImage = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ShelfSmart" ofType:@"png"]] retain];
    }
    
    needRefreshAd = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [normalShelfImage release];
    [smartShelfImage release];
    [tableView release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [tableView reloadData];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    needRefreshAd = YES;
}

#pragma mark TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    int count = [[DataModel sharedDataModel] shelvesCount];
    if (tv.editing) count++; // new cell
//    if ([Edition isLiteEdition]) count++; // ad
    return count;
}

- (int)getRow:(NSIndexPath *)indexPath
{
//    if ([Edition isLiteEdition]) {
//        return indexPath.row - 1; // ad
//    }
    return indexPath.row;
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = [self getRow:indexPath];
    if (row == -1) {
        return [AdCell adCellHeight];
    }
    return tv.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellid = @"ShelfCell";

    int row = [self getRow:indexPath];
    if (row == -1) {
        AdCell *ac = [AdCell adCell:tv parentViewController:self.navigationController]; // Ad
        return ac;
    }

    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellid];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid] autorelease];
    }

    DataModel *dm = [DataModel sharedDataModel];
    if (row >= [dm shelvesCount]) {
        // 新規追加セル
        cell.textLabel.text = NSLocalizedString(@"Add new shelf", @"");
        cell.imageView.image = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        Shelf *shelf = [dm shelfAtIndex:row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)", shelf.name, shelf.array.count];

        if (shelf.pkey == SHELF_ALL_PKEY) {
            // All 棚は名称変更しない
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }
	
        if (shelf.shelfType == ShelfTypeNormal) {
            cell.imageView.image = normalShelfImage;
        } else {
            cell.imageView.image = smartShelfImage;
        }
    }
	
    return cell;
}

// セルをクリックしたときの処理
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tv deselectRowAtIndexPath:indexPath animated:NO];

    int row = [self getRow:indexPath];
    if (row < 0) return;

    DataModel *dm = [DataModel sharedDataModel];
    if (row >= [dm shelvesCount]) {
        // 新規追加
        [self addShelf];
    } else {
        // 棚表示
        Shelf *shelf = [dm shelfAtIndex:row];

        if (IS_IPAD) {
            [splitItemListViewController setShelf:shelf];
            [splitItemListViewController viewWillAppear:NO];
        } else {
            // ItemListView を表示する
            ItemListViewController *vc = [[[ItemListViewController alloc]
                                              initWithNibName:@"ItemListView"
                                              bundle:nil] autorelease];
            [vc setShelf:shelf];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////
// 棚変更・追加処理

// 変更
- (void)tableView:(UITableView *)tv accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    int row = [self getRow:indexPath];
    if (row < 0) return;

    Shelf *shelf = [[DataModel sharedDataModel] shelfAtIndex:row];

    EditShelfViewController *vc = [EditShelfViewController
                                      editShelfViewController:shelf
                                      isNew:NO];
    [self doModalWithNavigationController:vc];
}

// 追加
- (void)addShelfButtonTapped:(id)sender
{
    [self addShelf];
}

- (void)addShelf
{
    NSString *title1 = NSLocalizedString(@"Add normal shelf", @"");
    NSString *title2 = NSLocalizedString(@"Add smart shelf", @"");

    UIActionSheet *as = [[UIActionSheet alloc]
                            initWithTitle:nil
                            delegate:self
                            cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                            destructiveButtonTitle:nil
                            otherButtonTitles:title1, title2, nil];
    as.actionSheetStyle = UIActionSheetStyleDefault;
    [as showInView:self.view];
    [as release];
}

// 追加 (種類選択)
- (void)actionSheet:(UIActionSheet*)as clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 2) return; // cancel

    Shelf *shelf = [[Shelf alloc] init];
    if (buttonIndex == 0) {
        shelf.shelfType = ShelfTypeNormal;
    } else {
        shelf.shelfType = ShelfTypeSmart;
    }

    EditShelfViewController *vc;
    vc = [EditShelfViewController editShelfViewController:shelf isNew:YES];
    [shelf release];

    [self doModalWithNavigationController:vc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Editボタン処理

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    // 編集モードの変更
    [tableView setEditing:editing animated:animated];
	
    // 「新規追加」行の追加／削除処理
    int newRow = [[DataModel sharedDataModel] shelvesCount];
    //if ([Edition isLiteEdition]) newRow++;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newRow inSection:0];
    if (editing) {
        // 行追加
        [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                   withRowAnimation:UITableViewRowAnimationTop];
    } else {
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                   withRowAnimation:UITableViewRowAnimationTop];
    }
    //[tableView reloadData];

#if 0
    if (editing) {
        self.navigationItem.leftBarButtonItem.enabled = NO;
    } else {
        self.navigationItem.leftBarButtonItem.enabled = YES;
    }
#endif
}

// 編集スタイルを返す
- (UITableViewCellEditingStyle)tableView:(UITableView*)tv editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{       
    int row = [self getRow:indexPath];
    if (row < 0) {
        return UITableViewCellEditingStyleNone;
    }

    DataModel *dm = [DataModel sharedDataModel];
    if (row >= [dm shelvesCount]) {
        return UITableViewCellEditingStyleInsert;
    }
    Shelf *shelf = [dm shelfAtIndex:row];
    if (shelf.pkey == SHELF_ALL_PKEY || shelf.pkey == 0) {
        // All棚と未分類棚(pkey==0)は消さない
        return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleDelete;
}

// 削除処理/追加処理など
- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath*)indexPath
{
    int row = [self getRow:indexPath];
    if (row < 0) return;

    DataModel *dm = [DataModel sharedDataModel];
    if (row >= [dm shelvesCount]) {
        // 追加
        [self addShelf];
    }
    else if (style == UITableViewCellEditingStyleDelete) {
        // 削除
        Shelf *shelf = [[DataModel sharedDataModel] shelfAtIndex:row];
        [[DataModel sharedDataModel] removeShelf:shelf];
	
        [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadData];
    }
}

// 並べ替え処理
- (BOOL)tableView:(UITableView *)tv canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = [self getRow:indexPath];
    if (row < 0) return NO;

    DataModel *dm = [DataModel sharedDataModel];
    if (row >= [dm shelvesCount]) {
        return NO; // 新規追加行
    }
    Shelf *shelf = [dm shelfAtIndex:row];
    if (shelf.pkey == SHELF_ALL_PKEY) {
        return NO;	// All 棚は移動させない
    }
    return YES;
}

- (NSIndexPath *)tableView:(UITableView *)tv targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)fromIndexPath 
       toProposedIndexPath:(NSIndexPath *)proposedIndexPath
{
    int addNewShelfRow = [[DataModel sharedDataModel] shelvesCount];
    
    // All 列と、Add new shelf... の列には移動を禁止する
    if (proposedIndexPath.row == 0 || proposedIndexPath.row == addNewShelfRow) {
        return fromIndexPath;
    }
    return proposedIndexPath;
}

- (void)tableView:(UITableView *)tv moveRowAtIndexPath:(NSIndexPath*)from toIndexPath:(NSIndexPath*)to
{
    int shelvesCount = [[DataModel sharedDataModel] shelvesCount];
    int fromRow = [self getRow:from];
    int toRow = [self getRow:to];

    if (fromRow < 0 || toRow < 0 ||
        fromRow >= shelvesCount || toRow >= shelvesCount) return;

    [[DataModel sharedDataModel] reorderShelf:fromRow to:toRow];
}

////////////////////////////////////////////////////////////////////////////////////////////
// Scan 処理

- (IBAction)scanButtonTapped:(id)sender
{
    ScanViewController *vc = [[ScanViewController alloc] initWithNibName:@"ScanView" bundle:nil];
    [self doModalWithNavigationController:vc];
    [vc release];
}

////////////////////////////////////////////////////////////////////////////////////////////
// Config 処理

- (IBAction)actionButtonTapped:(id)sender
{
    ConfigViewController *vc = [[ConfigViewController alloc] initWithNibName:@"ConfigView" bundle:nil];
#if 1
    [self doModalWithNavigationController:vc];
    [vc release];
#else
    UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:vc];
    [vc release];
	
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
	
    UIView *superView = self.view;
    [superView addSubview:vc.view];
    [superView addSubview:nv.view];
	
    [UIView commitAnimations];
#endif
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

@end
