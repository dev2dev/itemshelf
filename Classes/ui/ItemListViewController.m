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

#import <QuartzCore/QuartzCore.h>
#import "ItemListViewController.h"
#import "ItemCell.h"
#import "ItemCell4.h"
#import "ItemViewController.h"
#import "ScanViewController.h"
#import "DataModel.h"

static int itemsPerLine = 1;

//////////////////////////////////////////////////////////////////////////////////////////
// UITableView with touch event handlers

@implementation UITableViewWithTouchEvent

CGPoint lastTouchLocation;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
}

/**
   Remember last touched location (coordinates)
*/
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch *touch = [touches anyObject];
    lastTouchLocation = [touch locationInView:self];
	
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    [super touchesCancelled:touches withEvent:event];
}
@end

//////////////////////////////////////////////////////////////////////////////////////////
// ItemListViewController implementation

@implementation ItemListViewController

- (void)setShelf:(Shelf *)shelf
{
    // Generate ItemListModel
    [model release];
    model = [[ItemListModel alloc] initWithShelf:shelf];
}

- (void)viewDidLoad
{
    ASSERT(model);
	
    [super viewDidLoad];
	
    NSString *title = model.shelf.name;
    self.navigationItem.title = title;

    // Disable scan button for smart shelf
    if (model.shelf.shelfType == ShelfTypeNormal) {
        scanButton.enabled = YES;
    } else {
        scanButton.enabled = NO;
    }

    // Add Edit button
    self.navigationItem.rightBarButtonItem = [self editButtonItem];
    if (itemsPerLine != 1) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
	
    // Generate table view with touch event handlers
    tableView = [[UITableViewWithTouchEvent alloc] initWithFrame:CGRectMake(0, 0, 320, 372)];
    tableView.rowHeight = ITEM_CELL_HEIGHT;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    [tableView release];
	
    // Create SearchBar
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    searchBar.hidden = YES;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.showsCancelButton = NO;
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    searchBar.delegate = self;

    // Initiate filter button title
    filterButton.title = NSLocalizedString(@"All", @"");
}

- (void)dealloc {
    [model release];
    [searchBar release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    ASSERT(model != nil);
    [model updateFilter];
    [self updateTitle];

    [tableView reloadData];
    [super viewWillAppear:animated];
}

/**
   Update title with shelf name and item count.
*/
- (void)updateTitle
{
    self.navigationItem.title = [NSString stringWithFormat:@"%@ (%d)", model.shelf.name, model.count];
}

/**
   Set filter string
*/
- (void)setFilter:(NSString *)f
{
    [model setFilter:f];
    [self updateTitle];

    if (f == nil) {
        filterButton.title = NSLocalizedString(@"All", @"");
    } else {
        filterButton.title = NSLocalizedString(f, @"");
    }

    [tableView reloadData];
}

/**
   Filter button tapped handler
*/
- (void)filterButtonTapped:(id)sender
{
    NSMutableArray *filters = [[DataModel sharedDataModel] filterArray:model.shelf];

    int filterIndex = [filters findString:model.filter];
    if (filterIndex < 0) {
        filterIndex = 0; // all (no filter)
    }
	
    GenSelectListViewController *vc = [GenSelectListViewController genSelectListViewController:self array:filters title:NSLocalizedString(@"Filter", @"")];
    vc.selectedIndex = filterIndex;
	
    [self doModalWithNavigationController:vc];
}

/**
   Called when filter is selected
*/
- (void)genSelectListViewChanged:(GenSelectListViewController*)vc
{
    if (vc.selectedIndex == 0) {
        // All (no filter)
        [self setFilter:nil];
    } else {
        [self setFilter:[vc selectedString]];
    }
}

/**
   Toggle cell view mode (1 - 4 cells per line)
*/
- (IBAction)toggleCellView:(id)sender
{
    NSArray *ary = [tableView indexPathsForVisibleRows];
    int centerRow = -1;
    if (ary.count > 0) {
        // 画面中央の行を計算
        centerRow = [[ary objectAtIndex:ary.count / 2] row];
    }

    if (itemsPerLine == 1) {
        itemsPerLine = 4;
        if (centerRow > 0) centerRow /= 4;
    } else {
        itemsPerLine = 1;
        if (centerRow > 0) centerRow *= 4;
    }

    if (self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem.enabled = 
            (itemsPerLine == 1) ? YES : NO;
    }

    [tableView reloadData];

    // 表示位置を調整する
    if (centerRow >= 0) {
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:centerRow inSection:0];
        [tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/**
   @name TableViewDataSource protocol
*/
//@{

#pragma mark TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (itemsPerLine == 1) {
        return [model count];
    }
    return ([model count] + itemsPerLine - 1) / itemsPerLine;
}

// セルを返す
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (itemsPerLine == 1) {
        Item *item = [model itemAtIndex:indexPath.row];
        ItemCell *cell = [ItemCell getCell:tv];

        // 画像をダウンロードしておく
        [item getImage:self];

        [cell setItem:item];
        return cell;
    } else {
        ItemCell4 *cell = [ItemCell4 getCell:tv];
        for (int i = 0;  i < 4; i++) {
            int idx = indexPath.row * 4 + i;

            Item *item;
            if (idx < model.count) {
                item = [model itemAtIndex:idx];
                [item getImage:self];
            } else {
                item = nil;
            }
            [cell setItem:item atIndex:i];
        }
        return cell;
    }
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

    ItemViewController *vc = [[[ItemViewController alloc]
                                  initWithNibName:@"ItemView"
                                  bundle:[NSBundle mainBundle]]
                                 autorelease];

    // クリックされたアイテムの index を計算
    int idx;
    if (itemsPerLine == 1) {
        idx = indexPath.row;
    } else {
        int x = lastTouchLocation.x * 4 / 320;
        idx = indexPath.row * 4 + x;
    }
    if (idx >= [model count]) {
        return;
    }

    Item *item = [model itemAtIndex:idx];
    ASSERT(item);

    [vc.itemArray addObject:item];
    [self.navigationController pushViewController:vc animated:YES];
}

//@}

//////////////////////////////////////////////////////////////////////////////////////////
// Edit handling

/**
   @name Edit handling
*/
//@{

// Edit button process
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    // tableView に通知
    [tableView setEditing:editing animated:animated];
}

// Return editing style
- (UITableViewCellEditingStyle)tableView:(UITableView*)tv
           editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
    // 削除可能
    if (itemsPerLine == 1) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

// delete row
- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)style
forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (style == UITableViewCellEditingStyleDelete) {
        Item *item = [model itemAtIndex:indexPath.row];
        [model removeObject:item];

        [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadData];
    }
}

// Reorder: can move?
- (BOOL)tableView:(UITableView *)tv canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    return YES; // 全セル移動可能
}

// Reorder cell
- (void)tableView:(UITableView *)tv moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath
{
    [model moveRowAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
}

//@}

//////////////////////////////////////////////////////////////////////////////////////////
// SearchBar processing

/**
   @name SearchBar processing
*/
//@{

/**
   Toggel search bar
*/
- (IBAction)toggleSearchBar:(id)sender
{
    searchBar.hidden = !searchBar.hidden;
	
    if (!searchBar.hidden) {
        [self showSearchBar];
    } else {
        [self hideSearchBar];
    }
	
    [tableView reloadData];
}

/**
   Show search bar with animation
*/
- (void)showSearchBar
{
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.titleView = searchBar;
    self.navigationItem.hidesBackButton = YES;
    searchBar.hidden = NO;

    CATransition *anim = [CATransition animation];
    [anim setType:kCATransitionMoveIn];
    [anim setSubtype:kCATransitionFromBottom];
    [anim setDuration:0.2];
    [self.navigationController.navigationBar.layer addAnimation:anim forKey:@"searchBarAnimation"];
	
    [searchBar becomeFirstResponder];
}

/**
   Hide search bar with animation
*/
- (void)hideSearchBar
{
    self.navigationItem.rightBarButtonItem = [self editButtonItem];
    self.navigationItem.titleView = nil;
    self.navigationItem.hidesBackButton = NO;
    searchBar.hidden = YES;
	
    CATransition *anim = [CATransition animation];
    [anim setType:kCATransitionReveal];
    [anim setSubtype:kCATransitionFromTop];
    [anim setDuration:0.2];
    [self.navigationController.navigationBar.layer addAnimation:anim forKey:@"searchBarAnimation"];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)sb
{
    // Enable cancel button when editing text
    sb.showsCancelButton = YES; 
	
    // Disable Edit, Filter buttons.
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)sb
{
    sb.showsCancelButton = NO;
	
    // Back to enabeld for Edit, Filter buttons.
    self.navigationItem.leftBarButtonItem.enabled = YES;
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)searchBar:(UISearchBar *)sb textDidChange:(NSString *)text
{
    [model setSearchText:text];
    // No need to updateTitle here (title is hidden by search bar)

    [tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)sb
{
    sb.text = @"";
    [sb resignFirstResponder];
    [self hideSearchBar];

    [model setSearchText:nil];
    [tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)sb
{
    [sb resignFirstResponder];
}

//@}

//////////////////////////////////////////////////////////////////////////////////////////
// Scan processing

/**
   @name Scan button processing
*/

//@{
- (void)scanButtonTapped:(id)sender
{
    ScanViewController *vc = [[ScanViewController alloc] initWithNibName:@"ScanView" bundle:nil];
    vc.selectedShelf = model.shelf;
	
    [self doModalWithNavigationController:vc];
    [vc release];
}
//@}

- (void)didReceiveMemoryWarning {
    [Item clearAllImageCache];

    // do not release view
}

@end
