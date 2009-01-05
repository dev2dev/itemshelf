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

#import "ScanViewController.h"
#import "ItemViewController.h"
#import "BarcodeReader.h"
#import "NumPadViewController.h"
#import "DataModel.h"
#import "SearchController.h"

@implementation ScanViewController
@synthesize selectedShelf;

static UIImage *cameraIcon = nil, *libraryIcon = nil, *numpadIcon = nil, *keywordIcon = nil, *localeIcon = nil;

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.navigationItem.title = NSLocalizedString(@"Scan", @"");
	
    self.tableView.rowHeight = 70; // TBD

    activityIndicator = nil;

    if (cameraIcon == nil) {
        cameraIcon  = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ScanCamera" ofType:@"png"]] retain];
        libraryIcon = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PhotoLibrary" ofType:@"png"]] retain];
        numpadIcon  = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"NumPad" ofType:@"png"]] retain];
        keywordIcon = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"EnterCode" ofType:@"png"]] retain];
        localeIcon  = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Locale" ofType:@"png"]] retain];
    }
	
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(doneAction:)] autorelease];
}

- (void)doneAction:(id)sender
{
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [selectedShelf release];

    [super dealloc];
}


////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

// セルを返す
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
#define SCAN_CELL_ID @"ScanViewCellId"
#define TAG_IMAGE 1
#define TAG_NAME 2
#define TAG_DESC 3

    UIImageView *imgView;
    UILabel *nameLabel, *descLabel;
	
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:SCAN_CELL_ID];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:SCAN_CELL_ID] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone; // TBD
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        // アイコン
        imgView = [[[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 58, 58)] autorelease];
        imgView.tag = TAG_IMAGE;
        imgView.autoresizingMask = 0;
        imgView.contentMode = UIViewContentModeScaleAspectFit; // 画像のアスペクト比を変えないようにする。
        [cell.contentView addSubview:imgView];
		
        // 名称
        nameLabel = [[[UILabel alloc] initWithFrame:CGRectMake(70, 10, 240, 18)] autorelease];
        nameLabel.tag = TAG_NAME;
        nameLabel.font = [UIFont boldSystemFontOfSize:14.0];
        nameLabel.textColor = [UIColor blackColor];
        nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [cell.contentView addSubview:nameLabel];

        // 説明
        descLabel = [[[UILabel alloc] initWithFrame:CGRectMake(70, 30, 240, 30)] autorelease];
        descLabel.tag = TAG_DESC;
        descLabel.font = [UIFont systemFontOfSize:12.0];
        descLabel.textColor = [UIColor grayColor];
        descLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        descLabel.lineBreakMode = UILineBreakModeWordWrap;
        descLabel.numberOfLines = 0;
        descLabel.contentMode = UIViewContentModeTop;
        [cell.contentView addSubview:descLabel];
    } else {
        imgView = (UIImageView *)[cell.contentView viewWithTag:TAG_IMAGE];
        nameLabel = (UILabel *)[cell.contentView viewWithTag:TAG_NAME];
        descLabel = (UILabel *)[cell.contentView viewWithTag:TAG_DESC];
    }		

    switch (indexPath.row) {
    case 0:
        imgView.image = cameraIcon;
        nameLabel.text = NSLocalizedString(@"Camera scan", @"");
        descLabel.text = NSLocalizedString(@"Scan barcode with iPhone's camera", @"");
        break;
    case 1:
        imgView.image = libraryIcon;
        nameLabel.text = NSLocalizedString(@"Photo library scan", @"");
        descLabel.text = NSLocalizedString(@"Scan barcode image from photo library", @"");
        break;
    case 2:
        imgView.image = numpadIcon;
        nameLabel.text = NSLocalizedString(@"Enter item code", @"");
        descLabel.text = NSLocalizedString(@"EnterCodeDescription", @"");
        break;
    case 3:
        imgView.image = keywordIcon;
        nameLabel.text = NSLocalizedString(@"Enter title", @"");
        descLabel.text = NSLocalizedString(@"EnterTitleDescription", @"");
        break;
    case 4:
        imgView.image = localeIcon;
        nameLabel.text = NSLocalizedString(@"Select locale", @"");
        descLabel.text = NSLocalizedString(@"Select locale of Amazon", @"");
        break;
    }
	
    return cell;
}

// セルをクリックしたときの処理
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tv deselectRowAtIndexPath:indexPath animated:NO];
	
    switch (indexPath.row) {
    case 0:
        [self scanWithCamera:nil];
        break;
    case 1:
        [self scanFromLibrary:nil];
        break;
    case 2:
        [self enterIdentifier:nil];
        break;
    case 3:
        [self enterKeyword:nil];
        break;
    case 4:
        [self selectLocale];
        break;
    }
}

////////////////////////////////////////////////////////////////////////////////////////////
// 画像取り込み処理

- (IBAction)scanWithCamera:(id)sender
{
    [self execScan:UIImagePickerControllerSourceTypeCamera];
}

- (IBAction)scanFromLibrary:(id)sender
{
    [self execScan:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL)execScan:(UIImagePickerControllerSourceType)type
{
    if (![UIImagePickerController isSourceTypeAvailable:type]) {
        // abort
        // TBD
        return NO;
    }
	
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = type;
    picker.delegate = self;
    picker.allowsImageEditing = YES;
	
    [self presentModalViewController:picker animated:YES];
    [picker release];
    return YES;
}

// 画像取得完了
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [[picker parentViewController] dismissModalViewControllerAnimated:YES];

    // バーコード解析
    BarcodeReader *reader = [[[BarcodeReader alloc] init] autorelease];
    if (![reader recognize:image]) {
        [Common showAlertDialog:@"No symbol" message:@"Could not recognize barcode symbol"];
        return;
    }

    SearchController *sc = [SearchController createController];
    sc.delegate = self;
    sc.viewController = self;
    sc.selectedShelf = selectedShelf;
    [sc searchWithKeyword:reader.data];
}

- (void)searchControllerFinish:(SearchController*)controller result:(BOOL)result
{
    // TBD : 再度開始する？？？
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [[picker parentViewController] dismissModalViewControllerAnimated:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////
// マニュアル入力処理

// コード入力
- (void)enterIdentifier:(id)sender
{
    NumPadViewController *v = [NumPadViewController numPadViewController:NSLocalizedString(@"Code", @"")];
    v.selectedShelf = selectedShelf;

    [self.navigationController pushViewController:v animated:YES];
}

// タイトル入力
- (void)enterKeyword:(id)sender
{
    KeywordViewController *v = [KeywordViewController keywordViewController:NSLocalizedString(@"Title", @"")];
    v.selectedShelf = selectedShelf;

    [self.navigationController pushViewController:v animated:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////
// 地域選択

- (void)selectLocale
{
    NSArray *countries = [[DataModel sharedDataModel] countries];
    NSString *currentCountry = [[DataModel sharedDataModel] country];
	
    int idx = [countries findString:currentCountry];
    if (idx < 0) idx = 0;

    GenSelectListViewController *vc = [GenSelectListViewController
                                          genSelectListViewController:self
                                          array:countries
                                          title:NSLocalizedString(@"Select locale", @"")
                                          identifier:0];
    vc.selectedIndex = idx;
	
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)genSelectListViewChanged:(GenSelectListViewController*)vc identifier:(int)id
{
    NSString *country = [vc selectedString];
    [[DataModel sharedDataModel] setCountry:country];
}

@end