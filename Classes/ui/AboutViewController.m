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

#import "AboutViewController.h"
#import "Edition.h"

#define COPYRIGHT @"Copyright © 2008-2009, ItemShelf development team. All rights reserved."
#define COPYRIGHT_ZEBRA @"Zebra barcode library, Copyright 2007-2008 (c) Jeff Brown <spadix@users.sourceforge.net>"

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"About", @"");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *ret = nil;
    switch (section) {
    case 0:
        ret = @"About";
        break;
    case 1:
        ret = @"Credits";
        break;
    }
    return ret;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int ret = 0;
    switch (section) {
    case 0:
        ret = 3;
        break;
    case 1:
        ret = 2;
        break;
    }
    return ret;
}

// Customize cell heights
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int height = tableView.rowHeight;	

    switch (indexPath.section) {
    case 0:
        switch (indexPath.row) {
        case 0: // icon
            height = 80;
            break;
        }
        break;
			
    case 1:
        switch (indexPath.row) {
        case 0:
            height = 60;
            break;
        case 1:
            height = 50;
            break;
        }
        break;
    }
    return height;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"AboutCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
    NSString *version;
    NSString *aptitle;
    UILabel *clabel;
    UIImage *iconImage;
	
    cell.selectionStyle = UITableViewCellSelectionStyleNone;	
	
    switch (indexPath.section) {
    case 0:
        switch (indexPath.row) {
        case 0:
            if ([Edition isLiteEdition]) {
                iconImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Icon-lite" ofType:@"png"]];
            } else {
                iconImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Icon" ofType:@"png"]];
            }
            cell.imageView.image = iconImage;
            if ([Edition isLiteEdition]) {
                aptitle = @"ItemShelf Lite";
            } else {
                aptitle = NSLocalizedString(@"AppName", @"");
            }
            cell.textLabel.text = aptitle;
            break;

        case 1:
            version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
            cell.textLabel.text = [NSString stringWithFormat:@"Version %@", version];
            break;
					
        case 2:
            cell.textLabel.text = NSLocalizedString(@"Support site", @"");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        break;
			
    case 1:
        switch (indexPath.row) {
        case 0:
            clabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 5, 270, 50)] autorelease];
            clabel.lineBreakMode = UILineBreakModeWordWrap;
            clabel.numberOfLines = 0;
            clabel.font = [UIFont boldSystemFontOfSize:14.0];
            clabel.text = COPYRIGHT;
            [cell addSubview:clabel];
            break;
					
        case 1:
            clabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 5, 270, 40)] autorelease];
            clabel.lineBreakMode = UILineBreakModeWordWrap;
            clabel.numberOfLines = 0;
            clabel.font = [UIFont boldSystemFontOfSize:11.0];
            clabel.text = COPYRIGHT_ZEBRA;
            [cell addSubview:clabel];
            break;
        }
        break;
    }

    return cell;
}

// セルタップ時の処理					
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 2) {
        // URL タップ
        NSURL *url = [NSURL URLWithString:NSLocalizedString(@"SupportURL", @"")];
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
