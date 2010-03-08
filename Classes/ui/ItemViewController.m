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
#import "KeywordViewController2.h"
#import "StarCell.h"

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

#if 0
    self.navigationItem.rightBarButtonItem = [self editButtonItem];
#endif
}

- (void)didReceiveMemoryWarning {
    [Item clearAllImageCache];
    [super didReceiveMemoryWarning];
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

    // keyword 検索の場合は、アイテム編集させない
    Item *item0 = [itemArray objectAtIndex:0];
    BOOL editable = false;
    if (itemArray.count == 1 && item0.registeredWithShelf) {
        editable = true;
    }
    cameraButton.enabled = editable;
    self.navigationItem.rightBarButtonItem.enabled = editable;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
    // イメージの全ロードを開始
    for (Item *item in itemArray) {
        [item getImage:self];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// InfoString 処理

#if 0
- (void)checkAndAppendString:(NSMutableArray*)infoStrings value:(NSString *)value withName:(NSString *)name
{
    if (value != nil && value.length > 0) {
        [infoStrings addObject:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(name, @""), value]];
    }
}

- (void)updateInfoStringsDict
{
    for (Item *item in itemArray) {
        item.infoStrings = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];

        [self checkAndAppendString:item.infoStrings value:item.author withName:@"Author"];
        [self checkAndAppendString:item.infoStrings value:item.manufacturer withName:@"Manufacturer"];
        [self checkAndAppendString:item.infoStrings value:item.price withName:@"Price"];
        [self checkAndAppendString:item.infoStrings value:NSLocalizedString(item.category, @"") withName:@"Category"];
        [self checkAndAppendString:item.infoStrings value:item.idString withName:@"Code"];
        [self checkAndAppendString:item.infoStrings value:item.asin withName:@"ASIN"];
		
        NSLog(@"DEBUG: Category = %@", item.category);
    }
}

- (NSMutableArray *)infoStrings:(int)index
{
    Item *item = [itemArray objectAtIndex:index];
    return item.infoStrings;
}
#endif

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
	
    // (画像 + 詳細を見る + 再検索) + 棚に追加 + (タグ + スター + メモ) + 情報数
    //    int n = 3 + (item.registeredWithShelf ? 0 : 1) + 3 + item.infoStrings.count;
    int n = 3 + (item.registeredWithShelf ? 0 : 1) + 3 + [item numberOfAdditionalInfo];

    if (tableView.editing) {
        n++; // タイトル編集行
    }

    return n;
}

// セルの高さを返す
- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Item *item = [itemArray objectAtIndex:indexPath.section];
	
    if ((!tableView.editing && indexPath.row == 0) ||
        (tableView.editing && indexPath.row == 1)) {
        // 画像セル
        UIImage *image = [item getImage:nil];
        if (image) {
            return image.size.height + 20;
        }
    }
    return tv.rowHeight; // default
}

// セルの種別を返す
#define ROW_TITLE -1
#define ROW_IMAGE -2
#define ROW_SHOW_DETAIL -3
#define ROW_SEARCH_AGAIN -4
#define ROW_ADD_TO_SHELF -5
#define ROW_TAGS -6
#define ROW_STAR -7
#define ROW_MEMO -8

- (int)_calcRowKind:(NSIndexPath *)indexPath item:(Item *)item
{
    int n;
    int row = indexPath.row;

    if (tableView.editing) {
        row--;  // タイトル編集行
    }

    switch (row) {
    case -1:
        return ROW_TITLE;
    case 0:
        return ROW_IMAGE;
    case 1:
        return ROW_SHOW_DETAIL;
    case 2:
        return ROW_SEARCH_AGAIN;
    }

    n = indexPath.row;
    if (!item.registeredWithShelf) {
        if (indexPath.row == 3) {
            return ROW_ADD_TO_SHELF;
        }
        n--;
    }

    switch (n) {
    case 3:
        return ROW_STAR;
    case 4:
        return ROW_TAGS;
    case 5:
        return ROW_MEMO;
    }
    return n - 6;
}

// セルを返す
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Item *item = [itemArray objectAtIndex:indexPath.section];

    int rowKind = [self _calcRowKind:indexPath item:item];

    // 画像セル
    if (rowKind == ROW_IMAGE) {
        return [self getImageCell:tv item:item];
    }


    // スターセル
    if (rowKind == ROW_STAR) {
        StarCell *cell = [StarCell getCell:tv star:item.star];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }

    // テキストセル
    UITableViewCell *cell;
    NSString *cellid = @"ItemViewTextCell";

    cell = [tv dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid] autorelease];
    }
	
    cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
    cell.accessoryType = UITableViewCellAccessoryNone;

    switch (rowKind) {
    case ROW_TITLE:
        cell.textLabel.text = item.title;
        cell.accessoryType = UITableViewCellAccessoryDiscloseIndicator;
        break;

    case ROW_SHOW_DETAIL:
        cell.textLabel.text = NSLocalizedString(@"Show detail", @"");
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        break;

    case ROW_SEARCH_AGAIN:
        cell.textLabel.text = NSLocalizedString(@"Search again with title", @"");
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;        
        break;

    case ROW_ADD_TO_SHELF:
        cell.textLabel.text = NSLocalizedString(@"Add to shelf", @"");
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        break;

    case ROW_TAGS:
        cell.textLabel.text = [NSString stringWithFormat:@"%@: %@",
                              NSLocalizedString(@"Tags", @""),
                              item.tags];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        break;

    case ROW_MEMO:
        cell.textLabel.text = [NSString stringWithFormat:@"%@: %@",
                              NSLocalizedString(@"Memo", @""),
                              item.memo];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        break;
				
    default:
        cell.textLabel.text = [NSString stringWithFormat:@"%@: %@",
                                        [item additionalInfoKeyAtIndex:rowKind],
                                        [item additionalInfoValueAtIndex:rowKind]];
        if (tableView.editing && [item isAdditionalInfoEditableAtIndex:rowKind]) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        break;
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
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
    int rowKind = [self _calcRowKind:indexPath item:item];

    if (rowKind == ROW_IMAGE) {
        [self cameraButtonTapped:nil];
    }
    else if (rowKind == ROW_SHOW_DETAIL) {
        // 詳細を表示
        NSString *detailURL = [WebApiFactory detailUrl:item isMobile:YES];
        WebViewController *vc = [[[WebViewController alloc] initWithNibName:@"WebView" bundle:nil] autorelease];
        vc.urlString = detailURL;

        [self.navigationController pushViewController:vc animated:YES];

    }
    else if (rowKind == ROW_SEARCH_AGAIN) {
        // 再検索
        KeywordViewController2 *v = [KeywordViewController2 keywordViewController:NSLocalizedString(@"Keyword", @"")];
        v.selectedShelf = [[DataModel sharedDataModel] shelf:item.shelfId];
		v.initialText = item.name;

        //[self.navigationController popViewControllerAnimated:NO];
        [self.navigationController pushViewController:v animated:YES];
    }
    else if (rowKind == ROW_ADD_TO_SHELF) {
        // 棚に登録
        if (![[DataModel sharedDataModel] addItem:item]) {
            [[DataModel sharedDataModel] alertItemCountOver];
        }
        [tv reloadData];
    }
    else if (rowKind == ROW_STAR) {
        // スター編集
        currentEditingItem = item;
        EditStarViewController *vc =
            [[EditStarViewController alloc] initWithStar:item.star delegate:self];
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    }
    else if (rowKind == ROW_TAGS) {
        // タグ編集
        currentEditingItem = item;
        EditTagsViewController *vc =
            [[EditTagsViewController alloc] initWithTags:item.tags delegate:self];
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    }
    else if (rowKind == ROW_MEMO) {
        currentEditingItem = item;
        EditMemoViewController *vc = 
            [EditMemoViewController editMemoViewController:self
                                    title:NSLocalizedString(@"Memo", @"")
                                    identifier:0];
        vc.text = item.memo;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (rowKind == ROW_TITLE) {
        // タイトル編集
        currentEditingItem = item;
        currentEditingRow = rowKind;
        GenEditTextViewController *vc =
            [GenEditTextViewController genEditTextViewController:self
                                       title:NSLocalizedString(@"Title", @"")];
        vc.value = item.title;

        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (rowKind >= 0 && [item isAdditionalInfoEditableAtIndex:rowKind]) {
        // その他編集
        currentEditingItem = item;
        currentEditingRow = rowKind;

        NSString *key, *value;
        key = [item additionalInfoKeyAtIndex:rowKind];
        value = [item additionalInfoValueAtIndex:rowKind];

        GenEditTextViewController *vc =
            [GenEditTextViewController genEditTextViewController:self
                                       title:NSLocalizedString(key, @"")];
        vc.value = value;

        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)editStarViewChanged:(EditStarViewController *)vc
{
    currentEditingItem.star = [vc star];
    [currentEditingItem updateStar];
    [tableView reloadData];
}

- (void)editTagsViewChanged:(EditTagsViewController *)vc
{
    currentEditingItem.tags = [vc tags];
    [currentEditingItem updateTags];
    [tableView reloadData];
}

- (void)editMemoViewChanged:(EditMemoViewController *)vc identifier:(int)id
{
    currentEditingItem.memo = vc.text;
    [currentEditingItem updateMemo];
    [tableView reloadData];
}

// タイトルその他編集
- (void)genEditTextViewChanged:(GenEditTextViewController *)vc
{
    if (currentEditingRowKind == ROW_TITLE) {
        currentEditingItem.title = vc.text;
    } else {
        [currentEditingItem setAdditionalInfoValueAtIndex:currentEditingRow withValue:vc.text];
    }
    // TBD: DB update
    [tableView reloadData];
}


//////////////////////////////////////////////////////////////////////////////////////////
// Edit handling

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
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tv canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////
// 写真撮影/選択処理

- (void)cameraButtonTapped:(id)sender
{
	Item *item = [itemArray objectAtIndex:0];
	if (!item.registeredWithShelf) return; // do nothing
	
	currentEditingItem = item;
	
    cameraActionSheet = [[UIActionSheet alloc]
                            initWithTitle:NSLocalizedString(@"Set image for this item.", @"")
                            delegate:self
                            cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                            destructiveButtonTitle:nil
                            otherButtonTitles:NSLocalizedString(@"Camera", @""),
                              NSLocalizedString(@"Photo library", @""), nil];
    cameraActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [cameraActionSheet showInView:self.view];
    [cameraActionSheet release];
}

- (void)execImagePicker:(UIImagePickerControllerSourceType)sourceType
{
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = sourceType;
        picker.delegate = self;
        picker.allowsEditing = YES;
        [self presentModalViewController:picker animated:YES];
        [picker release];
    }
}

// 写真撮影完了
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
	[currentEditingItem saveImageCache:image data:nil];
	[tableView reloadData];
}

#if 0
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
	[currentEditingItem saveImageCache:image data:nil];
	[tableView reloadData];
}
#endif

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
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
         ];
    vc.selectedIndex = selectedIndex;
    [shelfNames release];
	
    [self doModalWithNavigationController:vc];
}

- (void)genSelectListViewChanged:(GenSelectListViewController*)vc
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
    else if (as == cameraActionSheet) {
        cameraActionSheet = nil;
        switch (buttonIndex) {
        case 0:
            [self execImagePicker:UIImagePickerControllerSourceTypeCamera];
            break;
        case 1:
            [self execImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
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
	
#if 0
    // old version...

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
#else
    // MFMailComposeViewController を使う
    MFMailComposeViewController *vc = [[MFMailComposeViewController alloc] init];
    vc.mailComposeDelegate = self;

    [vc setSubject:[NSString stringWithFormat:@"[ItemShelf] %@", item.name]];
    [vc setMessageBody:body isHTML:YES];
    [self.navigationController presentModalViewController:vc animated:YES];
    [vc release];
#endif
}

// MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [controller dismissModalViewControllerAnimated:YES];
}

- (void)openSafari
{
    Item *item = [itemArray objectAtIndex:0];
    NSString *detailURL = [WebApiFactory detailUrl:item isMobile:YES];
    NSURL *url = [NSURL URLWithString:[detailURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:url];
}


@end
