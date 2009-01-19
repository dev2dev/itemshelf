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

#import "GenSelectListViewController.h"

@implementation GenSelectListViewController

@synthesize delegate, list, identifier, selectedIndex;

/**
   Generate GenSelectListViewController

   @param[in] delegate Delegate
   @param[in] ary Array of option strings
   @param[in] title Title of this view
   @param[in] id User defined identifier
   @return Instance of GenSelectListViewController
*/
+ (GenSelectListViewController *)genSelectListViewController:(id<GenSelectListViewDelegate>)a_delegate array:(NSArray*)ary title:(NSString*)title
{
    GenSelectListViewController *vc =
        [[[GenSelectListViewController alloc]
             init:a_delegate array:ary title:title] autorelease];

    return vc;
}

- (id)init:(id<GenSelectListViewDelegate>)a_delegate array:(NSArray*)ary title:(NSString*)a_title
{
    self = [super initWithNibName:@"GenSelectListView" bundle:nil];
    if (self) {
        self.delegate = a_delegate;
        self.list = ary;
        self.title = a_title;
        self.identifier = -1;
    }
    return self;
}    

- (void)dealloc
{
    [list release];
    [super dealloc];
}

- (void)viewDidLoad
{
    self.navigationItem.leftBarButtonItem =
        [[[UIBarButtonItem alloc]
             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
             target:self
             action:@selector(_cancelAction:)] autorelease];
}

/**
   Returns selected string
*/
- (NSString *)selectedString
{
    return [list objectAtIndex:selectedIndex];
}

- (void)_closeView
{
    if (self.navigationController.viewControllers.count == 1) {
        [self.navigationController dismissModalViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)_cancelAction:(id)sender
{
    [self _closeView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self tableView] reloadData];
}

/**
   @name Table view delegate / data source
*/
//@{
- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [list count];
}

// 行の内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *MyIdentifier = @"genSelectListViewCells";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
    }
    if (indexPath.row == self.selectedIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    NSString *text = [list objectAtIndex:indexPath.row];
    cell.text = NSLocalizedString(text, @"");

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndex = indexPath.row;
    [delegate genSelectListViewChanged:self];

    [self _closeView];
}

//@}

@end
