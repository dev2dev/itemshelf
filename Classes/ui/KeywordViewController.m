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

@synthesize selectedShelf;

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
    textField.placeholder = self.title;
    textField.clearButtonMode = UITextFieldViewModeAlways;
	
    searchIndices =
        [[NSArray alloc]
            initWithObjects:@"Apparel", @"Baby", @"Beauty", @"Books",
            @"Classical", @"DVD", @"Electronics", @"ForeignBooks", @"Grocery",
            @"HealthPersonalCare", @"Hobbies", @"Kitchen", @"Music",
            @"MusicTracks", @"Software", @"SportingGoods", @"Toys", @"VHS", @"Video",
            @"VideoGames", @"Watches", nil];

    searchSelectedIndex = 3;  // books
    searchIndex = [searchIndices objectAtIndex:searchSelectedIndex];
	
    [indexButton setTitle:NSLocalizedString(searchIndex, @"") forState:UIControlStateNormal];

    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
                                                  initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                  target:self
                                                  action:@selector(doneAction:)] autorelease];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(cancelAction:)] autorelease];
}

- (void)dealloc {
    [searchIndex release];
    [searchIndices release];
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
	
    SearchController *sc = [SearchController createController];
    sc.delegate = self;
    sc.viewController = self;
    sc.selectedShelf = selectedShelf;

    [sc searchWithTitle:textField.text withIndex:searchIndex];
}

- (void)searchControllerFinish:(SearchController*)controller result:(BOOL)result
{
    if (result) {
        textField.text = nil;
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
            title:NSLocalizedString(@"Category", @"")
            identifier:0];

    vc.list = searchIndices;
    vc.selectedIndex = searchSelectedIndex;
	
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)genSelectListViewChanged:(GenSelectListViewController*)vc identifier:(int)id
{
    searchSelectedIndex = vc.selectedIndex;
    [searchIndex release];
    searchIndex = [[searchIndices objectAtIndex:searchSelectedIndex] retain];
    [indexButton setTitle:NSLocalizedString(searchIndex, @"") forState:UIControlStateNormal];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

@end