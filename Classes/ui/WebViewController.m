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

#import "WebViewController.h"
#import "Item.h"

@implementation WebViewController
@synthesize webView, urlString;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle
{
    self = [super initWithNibName:nibName bundle:bundle];
    if (self) {
    }
    return self;
}


// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.title = NSLocalizedString(@"Browser", @"");

    barButtonBack.enabled = NO;
    barButtonForward.enabled = NO;
	
    // activity indicator を作る
    activityIndicator = [[UIActivityIndicatorView alloc]
                            initWithFrame:CGRectMake(0, 0, 32, 32)];
    activityIndicator.center = CGPointMake(160, 208);

    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    activityIndicator.autoresizingMask =
        UIViewAutoresizingFlexibleLeftMargin |
        UIViewAutoresizingFlexibleRightMargin | 
        UIViewAutoresizingFlexibleTopMargin | 
        UIViewAutoresizingFlexibleBottomMargin;
	
    [self.view addSubview:activityIndicator];
    [activityIndicator release];

    [activityIndicator startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didReceiveMemoryWarning {
    [Item clearAllImageCache];
    //[super didReceiveMemoryWarning];
}

- (void)dealloc {
    // webView の解放前に delegate をリセットしなければならない
    // (UIWebViewDelegate のリファレンス参照)
    webView.delegate = nil;
    [webView release];
    
    [urlString release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    // メモリを空けておく
    [Item clearAllImageCache];

    // ページロード処理
    //NSLog(@"Open URL: %@", urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *req = [[[NSURLRequest alloc] initWithURL:url] autorelease];
    [webView loadRequest:req];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [webView stopLoading];
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [Common isSupportedOrientation:interfaceOrientation];
}

- (IBAction)goForward:(id)sender
{
    [webView goForward];
}

- (IBAction)goBackward:(id)sender
{
    [webView goBack];
}

- (IBAction)reloadPage:(id)sender
{
    [webView reload];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orient duration:(NSTimeInterval)duration
{
#if 0
    if (orient != UIInterfaceOrientationPortrait) {
        self.navigationController.navigationBarHidden = YES;
    }
#endif
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orient
{
    if (self.interfaceOrientation == UIInterfaceOrientationPortrait) {
        self.navigationController.navigationBarHidden = NO;
    } else {
        self.navigationController.navigationBarHidden = YES;
    }
}

////////////////////////////////////////////////////////////////////////////////////////////
// UIWebViewDelegate

- (BOOL)webView:(UIWebView *)v shouldStartLoadWithReq:(NSURLRequest *)req
{
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [activityIndicator startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)v
{
    [activityIndicator stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
    barButtonBack.enabled = [v canGoBack];
    barButtonForward.enabled = [v canGoForward];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError*)err
{
    [activityIndicator stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    [Common showAlertDialog:@"Error" message:NSLocalizedString(@"Cannot connect with service", @"")];
}

////////////////////////////////////////////////////////////////////////////////////////////

@end
