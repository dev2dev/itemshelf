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
#import "ConfigViewController.h"

#import "DataModel.h"
#import "Edition.h"
#import "AdCell.h"

static int itemsPerLine = 1;

//////////////////////////////////////////////////////////////////////////////////////////
// UITableView with touch event handlers

#pragma mark UITableViewWithTouchEvent

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

#pragma mark -
#pragma mark ItemListViewController

@implementation ItemListViewController

@synthesize popoverController;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle
{
    self = [super initWithNibName:nibName bundle:bundle];
    return self;
}

- (void)viewDidLoad
{
    ASSERT(model);
	
    [super viewDidLoad];

    // 検索バー作成
    if (!IS_IPAD) {
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    } else {
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 180, 44)];
    }
    searchBar.hidden = YES;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.showsCancelButton = NO;
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    searchBar.delegate = self;

    // Add buttons
    UIBarButtonItem *editb = [self editButtonItem];
    if (itemsPerLine != 1) {
        editb.enabled = NO;
    }

    if (!IS_IPAD) {
        // iPhone
        // 右側に編集ボタンを置く
        self.navigationItem.rightBarButtonItem = editb;
    } else {
        // iPad
        // 右側に検索バー、編集ボタンの２つを置く
        // (左側は縦置き時に棚一覧ボタンが出現するので使えない)
        searchBar.hidden = NO;
        int width = searchBar.frame.size.width + 70/*TBD*/;
        UIToolbar *tb = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, width, 44)] autorelease];
        
        UIBarButtonItem *sbb = [[[UIBarButtonItem alloc] initWithCustomView:searchBar] autorelease];
        tb.items = [NSArray arrayWithObjects:sbb, editb, nil];

        UIBarButtonItem *bb = [[[UIBarButtonItem alloc] initWithCustomView:tb] autorelease];
        self.navigationItem.rightBarButtonItem = bb;
    }
	
    // Generate table view with touch event handlers
    CGRect frame = self.view.frame;
    frame.origin.y = 0;
    frame.size.height = frame.size.height - toolbar.frame.size.height;
    tableView = [[UITableViewWithTouchEvent alloc] initWithFrame:frame];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    tableView.rowHeight = ITEM_CELL_HEIGHT;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.dataSource = self;
    tableView.delegate = self;
//    tableView.backgroundColor = 
//        [UIColor colorWithRed:235/255.0 green:205/255.0 blue:180/255.0 alpha:1.0];
    
    [self.view addSubview:tableView];
    [tableView release];
    
    // Initiate filter button title
    filterButton.title = @"All";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [Item clearAllImageCache];
}

- (void)dealloc {
    [model release];
    [searchBar release];
    [popoverController release];
    [super dealloc];
}

- (Shelf *)shelf
{
    if (model == nil) {
        return nil;
    }
    return model.shelf;
}

- (void)setShelf:(Shelf *)shelf
{
    // Generate ItemListModel
    [model release];
    if (shelf == nil) {
        model = nil;
    } else {
        model = [[ItemListModel alloc] initWithShelf:shelf];
    }
    [self reload];
}

- (void)reload
{
    if (model == nil) {
        self.navigationItem.title = @"";
        [tableView reloadData];
    } else {
        // set title
        NSString *title = model.shelf.name;
        self.navigationItem.title = title;

        // Disable scan button for smart shelf
        if (model.shelf.shelfType == ShelfTypeNormal) {
            scanButton.enabled = YES;
        } else {
            scanButton.enabled = NO;
        }

        [model updateFilter];
        [self updateTitle];

        [tableView reloadData];

        // ShelfListView 側の件数を更新する
        if (IS_IPAD) {
            [splitShelfListViewController reload];
        }
    }

    if (popoverController != nil) {
        [popoverController dismissPopoverAnimated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self reload];
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
        filterButton.title = @"All";
    } else {
        filterButton.title = f;
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
    vc.isLocalize = NO;

    if (!IS_IPAD) {
        [self doModalWithNavigationController:vc];
    } else {
        [self doModalWithPopoverController:vc fromBarButtonItem:filterButton];
    }
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

    if (IS_IPAD) {
        [self dismissModalPopover];
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

    int numMultiItemPerLine = [self _calcNumMultiItemsPerLine];
    
    if (itemsPerLine == 1) {
        itemsPerLine = numMultiItemPerLine;
        if (centerRow > 0) centerRow /= itemsPerLine;
    } else {
        if (centerRow > 0) centerRow *= itemsPerLine;
        itemsPerLine = 1;
    }

    UIBarButtonItem *editb = [self editButtonItem];
    editb.enabled = (itemsPerLine == 1) ? YES : NO;

    [tableView reloadData];

    // 表示位置を調整する
    if (centerRow >= 0 && [model count] > 0) {
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:centerRow inSection:1];
        [tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

// 一列に入る画像数を計算
- (int)_calcNumMultiItemsPerLine
{
    int width = self.view.frame.size.width;
    return width / ITEM_IMAGE_WIDTH;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/**
   @name TableViewDataSource protocol
*/
//@{

#pragma mark -
#pragma mark TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if ([Edition isLiteEdition]) return 1;
        return 0;
    }
    
    int n;
    if (itemsPerLine == 1) {
        n = [model count];
    } else {
        n = ([model count] + itemsPerLine - 1) / itemsPerLine; // multi items per line
    }

    return n;
}

- (int)getRow:(NSIndexPath *)indexPath
{
    return indexPath.row;
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return [AdCell adCellHeight];
    }
    return tv.rowHeight;
}

// セルを返す
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = [self getRow:indexPath];
    if (indexPath.section == 0) {
        // Ad
        AdCell *ac = [AdCell adCell:tv parentViewController:self.navigationController];
        return ac;
    }
    
    if (itemsPerLine == 1) {
        Item *item = [model itemAtIndex:row];
        ItemCell *cell = [ItemCell getCell:tv];

        // 画像をダウンロードしておく
        [item getImage:self];

        [cell setItem:item];
        return cell;
    } else {
        ItemCell4 *cell = [ItemCell4 getCell:tv numItemsPerCell:itemsPerLine];
        for (int i = 0;  i < itemsPerLine; i++) {
            int idx = row * itemsPerLine + i;

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
    if (indexPath.section == 0) return; // ad

    NSString *nib = (IS_IPAD) ? @"ItemView-ipad" : @"ItemView";
    ItemViewController *vc = [[[ItemViewController alloc]
                                  initWithNibName:nib
                                  bundle:[NSBundle mainBundle]]
                                 autorelease];

    // クリックされたアイテムの index を計算
    int idx = indexPath.row;
    if (itemsPerLine > 1) {
        int x = lastTouchLocation.x / ITEM_IMAGE_WIDTH;
        idx = idx * itemsPerLine + x;
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

#pragma mark -
#pragma mark Edit handling

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
    if (indexPath.section == 1 && itemsPerLine == 1) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

// delete row
- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)style
forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (style == UITableViewCellEditingStyleDelete) {
        int row = [self getRow:indexPath];
        Item *item = [model itemAtIndex:row];
        [model removeObject:item];

        [tv beginUpdates];
        [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tv endUpdates];
        [tableView reloadData];

        // ShelfListView 側の件数を更新する
        if (IS_IPAD) {
            [splitShelfListViewController reload];
        }
    }
}

// Reorder: can move?
- (BOOL)tableView:(UITableView *)tv canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 0) {
        return NO; // Ad
    }
    return YES; // 移動可能
}

- (NSIndexPath *)tableView:(UITableView *)tv
    targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)fromIndexPath 
    toProposedIndexPath:(NSIndexPath *)proposedIndexPath
{
    // 広告の場所(section:0)には移動させない
    NSIndexPath *idx = [NSIndexPath indexPathForRow:proposedIndexPath.row inSection:1];
    return idx;
}


// Reorder cell
- (void)tableView:(UITableView *)tv moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath
{
    if (fromIndexPath.section == 0 || toIndexPath.section == 0) {
        // can't move!
        return;
    } else {
        [model moveRowAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
    }
}

//@}

//////////////////////////////////////////////////////////////////////////////////////////
// Sort

#pragma mark -
#pragma mark Sorting

/**
 @name Sort
 */
//@{

/**
 Sort
 */
- (IBAction)sortButtonTapped:(id)sender
{
	NSString *label1 = NSLocalizedString(@"Title", @"");
	NSString *label2 = NSLocalizedString(@"Author", @"");
	NSString *label3 = NSLocalizedString(@"Manufacturer", @"");
	NSString *label4 = NSLocalizedString(@"Star", @"");
	NSString *label5 = NSLocalizedString(@"Date", @"");
	
	UIActionSheet *as = [[UIActionSheet alloc]
						 initWithTitle:NSLocalizedString(@"Sort", @"")
						 delegate:self 
						 cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
						 destructiveButtonTitle:nil
                                otherButtonTitles:label1, label2, label3, label4, label5, nil];
	as.actionSheetStyle = UIActionSheetStyleDefault;
	[as showInView:self.view];
	[as release];
}

- (void)actionSheet:(UIActionSheet *)as clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[model sort:buttonIndex];
	[tableView reloadData];
}

//@}

//////////////////////////////////////////////////////////////////////////////////////////
// SearchBar processing

#pragma mark -
#pragma mark Search bar processing

/**
   @name SearchBar processing
*/
//@{

/**
   Toggel search bar
*/
- (IBAction)toggleSearchBar:(id)sender
{
    if (IS_IPAD) return;

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
    if (IS_IPAD) return;

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
    if (IS_IPAD) return;

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
    if (!IS_IPAD) {
        // Enable cancel button when editing text
        sb.showsCancelButton = YES; 
	
        // Disable Edit, Filter buttons.
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)sb
{
    if (!IS_IPAD) {
        sb.showsCancelButton = NO;

        // Back to enabeld for Edit, Filter buttons.
        self.navigationItem.leftBarButtonItem.enabled = YES;
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
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

#pragma mark -
#pragma mark Scan handling

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

- (IBAction)configButtonTapped:(id)sender
{
    ConfigViewController *vc = [[ConfigViewController alloc] initWithNibName:@"ConfigView" bundle:nil];
    [self doModalWithNavigationController:vc];
    [vc release];
}

#pragma mark -
#pragma mark Split View Delegate

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
    barButtonItem.title = NSLocalizedString(@"Shelves", @"");
    self.navigationItem.leftBarButtonItem = barButtonItem;
    self.popoverController = pc;
}

- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.navigationItem.leftBarButtonItem = nil;
    self.popoverController = nil;
}

#pragma mark -
#pragma mark Rotation support

// 画面回転
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [Common isSupportedOrientation:interfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (itemsPerLine > 1) {
        itemsPerLine = [self _calcNumMultiItemsPerLine];
        [tableView reloadData];
    }
}

@end
