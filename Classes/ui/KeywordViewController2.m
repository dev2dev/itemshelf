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

#import "KeywordViewController.h"
#import "AppDelegate.h"
#import "SearchController.h"

@implementation KeywordViewController

@synthesize selectedShelf, initialText;

+ (KeywordViewController *)keywordViewController:(NSString*)title
{
    KeywordViewController *vc = [[[KeywordViewController alloc]
                                     initWithNibName:@"KeywordView"
                                     bundle:nil] autorelease];
    vc.title = title;

    return vc;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    webApiFactory = [[WebApiFactory alloc] init];

    textField.placeholder = self.title;
    textField.clearButtonMode = UITextFieldViewModeAlways;

    if (initialText != nil) {
        textField.text = initialText;
    }
	
    [self _setupCategories];
    
    // key type
    keyType = 0;
    keyTypes = [[NSArray alloc] initWithObjects:@"Title", @"Keyword", nil];
    [keyTypeButton setTitleForAllState:NSLocalizedString(@"Title", @"")];
 
    // set service string
    [serviceIdButton setTitleForAllState:[webApiFactory serviceIdString]];

    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
                                                  initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                  target:self
                                                  action:@selector(doneAction:)] autorelease];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(cancelAction:)] autorelease];
}

- (void)_setupCategories
{
    [searchIndices release];
    WebApi *api = [webApiFactory createWebApi];

    searchIndices = [api categoryStrings];
    [searchIndices retain];

    searchSelectedIndex = [api defaultCategoryIndex];

    NSString *text = [searchIndices objectAtIndex:searchSelectedIndex];
    [indexButton setTitleForAllState:NSLocalizedString(text, @"")];

    [api release];
}

- (void)dealloc {
    [searchIndices release];
    [keyTypes release];
    [initialText release];
    [webApiFactory release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [textField becomeFirstResponder];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (IBAction)doneAction:(id)sender
{
    // 検索
    if (textField.text.length < 3) {
        [Common showAlertDialog:@"Error" message:@"Title is too short"];
        return;
    }

    [textField resignFirstResponder];
	
    SearchController *sc = [SearchController newController];
    sc.delegate = self;
    sc.viewController = self;
    sc.selectedShelf = selectedShelf;

    WebApi *api = [webApiFactory createWebApi];
    NSString *searchIndex = [searchIndices objectAtIndex:searchSelectedIndex];
    switch (keyType) {
        case 0:
            // Title search
            [sc search:api withTitle:textField.text withIndex:searchIndex];
            break;
        case 1:
            // Keyword search
            [sc search:api key:textField.text keyType:SEARCH_KEY_KEYWORD index:searchIndex];
            break;
    }
        
    [api release];
}

- (void)searchControllerFinish:(SearchController*)controller result:(BOOL)result
{
    if (result) {
        //textField.text = nil;
    }
}

- (IBAction)cancelAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)indexButtonTapped:(id)sender
{
    GenSelectListViewController *vc =
        [GenSelectListViewController
            genSelectListViewController:self
            array:searchIndices
            title:NSLocalizedString(@"Category", @"")];
    vc.selectedIndex = searchSelectedIndex;
    vc.identifier = 0;

    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)keyTypeButtonTapped:(id)sender
{
    GenSelectListViewController *vc =
    [GenSelectListViewController
     genSelectListViewController:self
     array:keyTypes
     title:NSLocalizedString(@"Search type", @"")];
    vc.selectedIndex = keyType;
    vc.identifier = 1;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)serviceIdButtonTapped:(id)sender
{
    GenSelectListViewController *vc =
        [GenSelectListViewController
            genSelectListViewController:self
            array:[webApiFactory serviceIdStrings]
            title:NSLocalizedString(@"Select locale", @"")];
    vc.selectedIndex = webApiFactory.serviceId;
    vc.identifier = 2;

    [self.navigationController pushViewController:vc animated:YES];
}

- (void)genSelectListViewChanged:(GenSelectListViewController*)vc
{
    NSString *text;
    
    switch (vc.identifier) {
    case 0: // serchIndex
        searchSelectedIndex = vc.selectedIndex;
        text = [searchIndices objectAtIndex:searchSelectedIndex];
        [indexButton setTitleForAllState:NSLocalizedString(text, @"")];
        break;

        case 1: // key type
            keyType = vc.selectedIndex;
            text = [keyTypes objectAtIndex:keyType];
            [keyTypeButton setTitleForAllState:NSLocalizedString(text, @"")];
            break;
            
    case 2: // serviceId
        webApiFactory.serviceId = vc.selectedIndex;
        [webApiFactory saveDefaults];
        [serviceIdButton setTitleForAllState:[webApiFactory serviceIdString]];

        [self _setupCategories];
        break;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (UITableViewCell *)containerCellWithTitle:(NSString*)title view:(UIView *)view
{
    KeywordViewCell *cell = [KeywordViewCell allocCell:title tableView:self.tableView identifier:title];
    [cell attachContainer:view];
    return cell;
}

- (UITableViewCell *)containerCellWithTitle:(NSString*)title text:(NSString *)text
{
    KeywordViewCell *cell = [KeywordViewCell allocCell:title tableView:self.tableView identifier:title];

    UILabel *value;
    value = [[[UILabel alloc] initWithFrame:CGRectMake(90, 6, 210, 32)] autorelease];
    value.text = text;
    value.font = [UIFont systemFontOfSize: 16.0];
    value.textColor = [UIColor blackColor];
    value.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [cell attachContainer:view];    
    return cell;
}


@end

////
// KeywordViewCell

@implementation KeywordViewCell

+ (KeywordViewCell *)allocCell:(NSString *)title tableView:(UITableView*)tableView identifier:(NSString *)identifier
{
    KeywordViewCell *cell = (KeywordViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[[KeywordViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identifier] autorelease];
    }
    
    UILabel *tlabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 6, 110, 32)] autorelease];
    tlabel.text = NSLocalizedString(title, @"");
    tlabel.font = [UIFont systemFontOfSize: 14.0];
    tlabel.textColor = [UIColor blueColor];
    tlabel.textAlignment = UITextAlignmentRight;
    tlabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [cell.contentView addSubview:tlabel];

    return cell;
}

- (void)attachView:(UIView *)view
{
    [attachedView removeFromSuperview];
    [attachedView release];

    attachedView = [view retain];
    [self addSubview:view];
}

- (void)dealloc
{
    [attachedView release];
    [super release];
}

@end
