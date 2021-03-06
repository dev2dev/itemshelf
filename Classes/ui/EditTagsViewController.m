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

#import "EditTagsViewController.h"
#import "DataModel.h"

@implementation EditTagsViewController

@synthesize delegate, tableView, canAddTags;

- (id)initWithTags:(NSString *)a_tags delegate:(id<EditTagsViewDelegate>)a_delegate;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        delegate = a_delegate;
        canAddTags = YES;

        if (a_tags == nil) {
            tags = [[NSMutableArray alloc] init];
        } else {
            tags = [[a_tags splitWithDelimiter:@","] retain];
        }
        allTags = [[[DataModel sharedDataModel] allTags] retain];
        
        for (NSString *tag in tags) {
            if ([allTags findString:tag] < 0) {
                [allTags addObject:tag];
            }
        }
        [allTags sortByString];
    }
    return self;
}

- (void)dealloc
{
    self.tableView = nil;
    self.view = nil;
    [tags release];
    [allTags release];
    [super dealloc];
}

- (void)loadView
{
    self.tableView = [[[UITableView alloc]
                          initWithFrame:[[UIScreen mainScreen] applicationFrame]
                          style:UITableViewStyleGrouped] autorelease];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    tableView.autoresizesSubviews = YES;

    self.view = tableView;

    self.title = NSLocalizedString(@"Tags", @"");

    self.navigationItem.rightBarButtonItem = 
        [[[UIBarButtonItem alloc]
             initWithBarButtonSystemItem:UIBarButtonSystemItemDone
             target:self
             action:@selector(_doneAction:)] autorelease];

    [tableView reloadData];
}

- (NSString *)tags
{
    NSMutableString *a_tags = nil;

    for (NSString *tag in tags) {
        if (a_tags == nil) {
            a_tags = [[[NSMutableString alloc] init] autorelease];
            [a_tags setString:tag];
        }
        else {
            [a_tags appendString:@","];
            [a_tags appendString:tag];
        }
    }
    
    if (a_tags == nil) {
        [a_tags setString:@""];
    }
    return a_tags;
}

- (void)_doneAction:(id)sender
{
    [delegate editTagsViewChanged:self];
    [self.navigationController popViewControllerAnimated:YES];
}

/**
   @name Table view delegate / data source
*/
//@{
- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    if (canAddTags) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (canAddTags && section == 0) {
        return 1;
    } else {
        return allTags.count;
    }
}

// 行の内容
- (UITableViewCell *)tableView:(UITableView *)a_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *MyIdentifier = @"editTagsViewCells";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (canAddTags && indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"New tag", @"");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else {
        cell.textLabel.text = [allTags objectAtIndex:indexPath.row];
        if ([tags findString:cell.textLabel.text] >= 0) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)a_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (canAddTags && indexPath.section == 0) {
        // add new tag
        GenEditTextViewController *vc =
            [GenEditTextViewController genEditTextViewController:self
                                       title:NSLocalizedString(@"Tags", @"")];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else {
        NSString *tag = [allTags objectAtIndex:indexPath.row];
        int n = [tags findString:tag];
        if (n < 0) {
            // add tag
            [tags addObject:tag];
            [tags sortByString];
        } else {
            // delete tag
            [tags removeObjectAtIndex:n];
        }
        [a_tableView reloadData];
    }
}

- (void)genEditTextViewChanged:(GenEditTextViewController *)vc
{
    if (vc.text.length > 0 && [allTags findString:vc.text] < 0) {
        [allTags addObject:vc.text];
        [allTags sortByString];

        [tags addObject:vc.text];
        [tags sortByString];
    }
    [[self tableView] reloadData];
}

//@}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [Common isSupportedOrientation:interfaceOrientation];
}

@end
