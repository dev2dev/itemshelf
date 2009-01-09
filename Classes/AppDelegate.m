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

#import "AppDelegate.h"
#import "DataModel.h"
#import "ScanViewController.h"
#import "SearchController.h"

@implementation AppDelegate

@synthesize window;
@synthesize navigationController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    srand(time(nil));
	
    // データをロードする
    DataModel *dm = [DataModel sharedDataModel];
    [dm loadDB];
	
    [window addSubview:navigationController.view];
    [window makeKeyAndVisible];
}

- (void)dealloc {
    [[DataModel sharedDataModel] release];
    [navigationController release];
    [window release];
    [super dealloc];
}

/**
   Get path of data file.

   @param[in] filename Name of the data file.
   @return Full path of the data file.
 */
+ (NSString*)pathOfDataFile:(NSString*)filename
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    NSString *dataDir = [paths objectAtIndex:0];
    if (filename == nil) {
        return dataDir;
    }
    NSString *path = [dataDir stringByAppendingPathComponent:filename];
    return path;
}

/**
   Handle custom URL

   This application accept "itemshelf://" URL scheme.
*/
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if (![url.scheme isEqualToString:@"itemshelf"]) {
        return NO;
    }

    LOG(@"host = %@, path = %@", url.host, url.path);
	
    WebApiFactory *wf = [WebApiFactory webApiFactory];

    // Get keyword (ASIN/ISBN/JAN etc.) from host part.
    NSString *code = url.host;

    // Get country code from path part.
    NSString *country = [url.path lastPathComponent];
    if (country.length != 2) {
        country = nil;
    }
    if (country != nil) {
        wf.serviceId = [wf serviceIdFromCountryCode:country];
    }
    WebApi *api = [[wf createWebApiForCodeSearch] autorelease];

    // Show ScanView and start search.
    ScanViewController *vc = [[ScanViewController alloc] initWithNibName:@"ScanView" bundle:nil];
    UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:vc];
    [navigationController presentModalViewController:nv animated:NO];
	
    SearchController *sc = [SearchController createController];
    sc.delegate = self;
    sc.viewController = vc;
    sc.selectedShelf = nil;
    [sc search:api withCode:code];

    [vc release];
    [nv release];
	
    return YES;
}

- (void)searchControllerFinish:(SearchController*)controller result:(BOOL)result
{
    // TBD エラーチェック
}

@end
