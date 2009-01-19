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

#import "EditShelfViewController.h"
#import "DataModel.h"

@implementation EditShelfViewController

@synthesize shelf, isNew;

// View Controller の生成
+ (EditShelfViewController *)editShelfViewController:(Shelf *)shelf isNew:(BOOL)isNew
{
    EditShelfViewController *vc =
        [[[EditShelfViewController alloc] initWithNibName:@"EditShelfView" bundle:nil] autorelease];
    vc.shelf = shelf;
    vc.isNew = isNew;

    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.rowHeight = 38; // ###
    
    self.navigationItem.title = NSLocalizedString(@"Edit shelf", @"");
    self.navigationItem.rightBarButtonItem =
        [[[UIBarButtonItem alloc]
             initWithBarButtonSystemItem:UIBarButtonSystemItemDone
             target:self
             action:@selector(doneAction:)] autorelease];

    self.navigationItem.leftBarButtonItem =
        [[[UIBarButtonItem alloc]
             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
             target:self
             action:@selector(closeAction:)] autorelease];

    shelfNameField    = [self textInputField:shelf.name placeholder:@"Name"];
    titleField        = [self textInputField:shelf.titleFilter placeholder:@"Title"];
    authorField       = [self textInputField:shelf.authorFilter placeholder:@"Author"];
    manufacturerField = [self textInputField:shelf.manufacturerFilter placeholder:@"Manufacturer"];
    tagsField         = [self textLabelField:shelf.tagsFilter];
}

- (void)dealloc {
    [shelf release];

    [shelfNameField release];
    [titleField release];
    [authorField release];
    [manufacturerField release];
    [tagsField release];

    [super dealloc];
}

- (void)doneAction:(id)sender
{
    shelf.name = shelfNameField.text;
    if (shelf.name == nil) {
        shelf.name = @"";
    }
    shelf.titleFilter = titleField.text;
    shelf.authorFilter = authorField.text;
    shelf.manufacturerFilter = manufacturerField.text;
    shelf.tagsFilter = tagsField.text;
    
    if (isNew) {
        // 新規追加
        [[DataModel sharedDataModel] addShelf:shelf];
    } else {
        // 変更
        [shelf updateName];
        if (shelf.shelfType == ShelfTypeSmart) {
            [shelf updateSmartFilters];
        }
    }

    // SmartShelf を更新する
    [shelf updateSmartShelf:[[DataModel sharedDataModel] shelves]];
    [self closeAction:sender];
}

- (void)closeAction:(id)sender
{
    [shelfNameField resignFirstResponder];
    [titleField resignFirstResponder];
    [authorField resignFirstResponder];
    [manufacturerField resignFirstResponder];
    //[tagsField resignFirstResponder];

    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UITextField*)textInputField:(NSString*)value placeholder:(NSString*)placeholder
{
    UITextField *t = [[UITextField alloc]
                         initWithFrame:CGRectMake(110, 10, 210, 32)];

    t.text = value;
    t.placeholder = NSLocalizedString(placeholder, @"");
    t.font = [UIFont systemFontOfSize:14];
    t.keyboardType = UIKeyboardTypeDefault;
    t.returnKeyType = UIReturnKeyDone;
    t.autocorrectionType = UITextAutocorrectionTypeNo;
    t.autocapitalizationType = UITextAutocapitalizationTypeNone;
	
    t.delegate = self;

    return t;
}

- (UILabel *)textLabelField:(NSString *)value
{
    UILabel *lb = [[UILabel alloc]
                      initWithFrame:CGRectMake(110, 2, 170, 32)];
    lb.text = value;
    lb.font = [UIFont systemFontOfSize:14];
    return lb;
}

- (BOOL)textFieldShouldReturn:(UITextField*)t
{
    [t resignFirstResponder];
    return YES;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (shelf.shelfType == ShelfTypeNormal) {
        return 1; // 棚の名前だけ
    }
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    switch (indexPath.row) {
    case 0:
        cell = [self textViewCell:@"Name" view:shelfNameField];
        break;
    case 1:
        cell = [self textViewCell:@"Title" view:titleField];
        break;
    case 2:
        cell = [self textViewCell:@"Author" view:authorField];
        break;
    case 3:
        cell = [self textViewCell:@"Manufacturer" view:manufacturerField];
        break;
    case 4:
        cell = [self textViewCell:@"Tags" view:tagsField];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        break;
    }
    return cell;
}

// View つきセルを作成
- (UITableViewCell *)textViewCell:(NSString *)title view:(UIView *)view
{
    NSString *CellIdentifier = @"textViewCell";

    UITableView *tv = (UITableView *)self.view;
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    } else {
        UIView *oldView = [cell.contentView viewWithTag:1];
        [oldView removeFromSuperview];
    }

    view.tag = 1;
    [cell.contentView addSubview:view];

    cell.text = NSLocalizedString(title, @"");
    cell.font = [UIFont boldSystemFontOfSize:14];

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row != 4) return; // tags

    EditTagsViewController *vc =
        [[EditTagsViewController alloc] initWithTags:tagsField.text delegate:self];
    vc.canAddTags = NO;
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

- (void)editTagsViewChanged:(EditTagsViewController *)vc
{
    tagsField.text = vc.tags;
    [self.tableView reloadData];
}

@end
