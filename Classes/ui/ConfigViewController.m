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

#import "ConfigViewController.h"
#import "DataModel.h"
#import "AboutViewController.h"
#import "WebViewController.h"

@implementation ConfigViewController

/*
  - (id)initWithStyle:(UITableViewStyle)style {
  // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
  if (self = [super initWithStyle:style]) {
  }
  return self;
  }
*/

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"About", @"");

    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
                                                  initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                  target:self
                                                  action:@selector(doneAction:)] autorelease];
}

- (void)dealloc {
    [super dealloc];
}

- (void)doneAction:(id)sender
{
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return NSLocalizedString(@"Backup", @"");
        case 1:
            return NSLocalizedString(@"About", @"");
    }
    return nil;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: // backup
            return 1;
        case 1: // about
            return 2;
    }
    return 0;
}

// Customize cell heights
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.rowHeight; // default
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"ConfigCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;	
	
    switch (indexPath.section) {
        case 0: // backup
            cell.text = NSLocalizedString(@"Backup and restore", @"");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case 1: // about
            switch (indexPath.row) {
                case 0:
                    cell.text = NSLocalizedString(@"Help", @"");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case 1:
                    cell.text = NSLocalizedString(@"About this software", @"");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
            }
            break;
    }

    return cell;
}

// セルタップ時の処理					
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        // backup
        [self _doBackup];
    }
    else if (indexPath.section == 1 && indexPath.row == 0) {
        // show help
        //NSURL *url = [NSURL URLWithString:NSLocalizedString(@"HelpURL", @"")];
        //[[UIApplication sharedApplication] openURL:url];

        WebViewController *wv = [[[WebViewController alloc] initWithNibName:@"WebView" bundle:nil] autorelease];
        wv.urlString = NSLocalizedString(@"HelpURL", @"");
        [self.navigationController pushViewController:wv animated:YES];
    }
    else if (indexPath.section == 1 && indexPath.row == 1) {
        AboutViewController *aout = [[[AboutViewController alloc]
                                         initWithNibName:@"AboutView"
                                         bundle:nil] autorelease];
        [self.navigationController pushViewController:aout animated:YES];
    }
}

- (void)_doBackup
{
    BOOL result = NO;
    
    backupServer = [[BackupServer alloc] init];
    backupServer.filePath = [[Database instance] dbPath];
    backupServer.dataName = @"itemshelf.db";

    NSString *url = [backupServer serverUrl];
    if (url != nil) {
        result = [backupServer startServer];
    }
    
    UIAlertView *v;
    if (!result) {
        [backupServer release];
        v = [[UIAlertView alloc]
             initWithTitle:@"Error"
             message:NSLocalizedString(@"Cannot start web server.", @"")
             delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"")
             otherButtonTitles:nil];
    } else {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"WebServerNotation", @""), url];
        
        v = [[UIAlertView alloc]
             initWithTitle:NSLocalizedString(@"Backup and restore", @"")
             message:message
             delegate:self cancelButtonTitle:NSLocalizedString(@"Close", @"")
             otherButtonTitles:nil];
    }
    [v show];
    [v release];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [backupServer stopServer];
    [backupServer release];
    backupServer = nil;
}

@end
