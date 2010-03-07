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

#import <AudioToolbox/AudioToolbox.h>

#import "NumPadViewController.h"
#import "AppDelegate.h"
#import "SearchController.h"

@implementation NumPadViewController

@synthesize selectedShelf;

+ (NumPadViewController *)numPadViewController:(NSString*)title
{
    NumPadViewController *vc = [[[NumPadViewController alloc]
                                    initWithNibName:@"NumPadView"
                                    bundle:nil] autorelease];
    vc.title = title;
    return vc;
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle
{
    self = [super initWithNibName:nibName bundle:bundle];
    if (self) {
        webApiFactory = [[WebApiFactory alloc] init];
        [webApiFactory setCodeSearch];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    textField.placeholder = self.title;
    textField.clearButtonMode = UITextFieldViewModeAlways;
	
    noteLabel.text = NSLocalizedString(@"NumPadNoteText", @"");
	
    // set service string
    [serviceIdButton setTitleForAllState:[webApiFactory serviceIdString]];

    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
												 initWithTitle:@"Search" style:UIBarButtonItemStyleDone
											     target:self action:@selector(doneAction:)] autorelease];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(cancelAction:)] autorelease];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [webApiFactory release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [textField resignFirstResponder];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (IBAction)padTapped:(id)sender
{
    // ボタンクリック音を鳴らす
    AudioServicesPlaySystemSound(1105);
	
    UIButton *button = sender;
    NSString *s = button.currentTitle;
    LOG(@"%@", s);
	
    NSString *t = textField.text;
    NSString *newtext = nil;
	
    if ([s isEqualToString:@"⌫"]) {
        if (t != nil && t.length > 0) {
            newtext = [t substringToIndex:t.length - 1];			
        }
    } else {
        if (t == nil) {
            newtext = s;
        } else {
            newtext = [t stringByAppendingString:s];
        }
    }
    textField.text = newtext;
}

// return キーを押したときにキーボードを消すための処理
- (BOOL)textFieldShouldReturn:(UITextField*)t
{
    [t resignFirstResponder];
    return YES;
}

- (IBAction)doneAction:(id)sender
{
    if (textField.text.length < 8) {
        [Common showAlertDialog:@"Error" message:@"Code is too short"];
        return;
    }
	
    [textField resignFirstResponder];


    SearchController *sc = [SearchController newController];
    sc.delegate = self;
    sc.viewController = self;
    sc.selectedShelf = selectedShelf;

    WebApi *api = [webApiFactory allocWebApi];
    [sc search:api withCode:textField.text];
    [api release];
}

- (void)searchControllerFinish:(SearchController*)sc result:(BOOL)result
{
    if (result) {
        textField.text = nil;
    }
}

- (IBAction)cancelAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)serviceIdButtonTapped:(id)sender
{
    GenSelectListViewController *vc =
        [GenSelectListViewController
            genSelectListViewController:self
            array:[webApiFactory serviceIdStrings]
            title:NSLocalizedString(@"Select locale", @"")];
    vc.selectedIndex = webApiFactory.serviceId;
	
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)genSelectListViewChanged:(GenSelectListViewController*)vc
{
    webApiFactory.serviceId = vc.selectedIndex;
    [webApiFactory saveDefaults];
    [serviceIdButton setTitleForAllState:[webApiFactory serviceIdString]];
}



@end
