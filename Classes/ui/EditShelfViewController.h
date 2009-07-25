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
#import "Common.h"
#import "Shelf.h"
#import "EditTagsViewController.h"
#import "EditStarViewController.h"

@interface EditShelfViewController : UITableViewController
<UITextFieldDelegate, EditTagsViewDelegate, EditStarViewDelegate>
{
    Shelf *shelf;
    BOOL isNew;

    UITextField *shelfNameField;
    UITextField *titleField;
    UITextField *authorField;
    UITextField *manufacturerField;
    UILabel *tagsField;
    UILabel *starField;
    int starFilter;
}

@property(nonatomic,retain) Shelf *shelf;
@property(nonatomic,assign) BOOL isNew;

+ (EditShelfViewController *)editShelfViewController:(Shelf *)shelf isNew:(BOOL)isNew;

// private
- (void)doneAction:(id)sender;
- (void)closeAction:(id)sender;
- (UITextField*)allocTextInputField:(NSString*)value placeholder:(NSString*)placeholder;
- (UILabel*)allocTextLabelField:(NSString*)value;
- (UITableViewCell *)textViewCell:(NSString *)title view:(UIView *)view;
- (NSString *)_starFilterString:(int)starFilter;

@end
