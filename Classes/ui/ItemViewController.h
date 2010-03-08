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

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "Common.h"
#import "Item.h"
#import "GenSelectListViewController.h"
#import "EditTagsViewController.h"
#import "EditMemoVC.h"
#import "EditStarViewController.h"

@interface ItemViewController : UIViewController
<UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, ItemDelegate, 
     EditTagsViewDelegate, EditMemoViewDelegate, EditStarViewDelegate,
     GenSelectListViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate,
     MFMailComposeViewControllerDelegate>
{
    IBOutlet UITableView *tableView;
    IBOutlet UIBarButtonItem *cameraButton;
	
    NSMutableArray *itemArray;
    NSString *urlString;

    UIActionSheet *openActionSheet;
    UIActionSheet *cameraActionSheet;

    Item *currentEditingItem;
}

@property(nonatomic,retain) NSMutableArray *itemArray;
@property(nonatomic,retain) NSString *urlString;


- (IBAction)cameraButtonTapped:(id)sender;
//- (IBAction)moveActionButtonTapped:(id)sender;
- (IBAction)openActionButtonTapped:(id)sender;
- (void)sendMail;
- (void)openSafari;

// private method
- (void)updateInfoStringsDict;
- (NSMutableArray *)infoStrings:(int)index;
- (int)_calcRowKind:(NSIndexPath *)indexPath item:(Item *)item;

- (void)checkAndAppendString:(NSMutableArray*)infoStrings value:(NSString *)value withName:(NSString *)name;
- (UITableViewCell *)getImageCell:(UITableView *)tv item:(Item*)item;

@end
