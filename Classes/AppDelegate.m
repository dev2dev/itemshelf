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
#import "Edition.h"

@implementation AppDelegate

@synthesize window;
@synthesize navigationController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    srand(time(nil));
	
    // データをロードする
    DataModel *dm = [DataModel sharedDataModel];
    [dm loadDB];
	
    if (IS_IPAD) {
        [window addSubview:splitViewController.view];
    } else {
        [window addSubview:navigationController.view];
    }
    [window makeKeyAndVisible];

    // AdMob
    [self performSelectorInBackground:@selector(reportAppOpenToAdMob) withObject:nil];
}

- (void)dealloc {
    [[DataModel sharedDataModel] release];
    [Database shutdown];

    if (IS_IPAD) {
        [splitViewController release];
    } else {
        [navigationController release];
    }

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
    [wf setCodeSearch];

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

    // Show ScanView and start search.
    ScanViewController *vc = [[ScanViewController alloc] initWithNibName:@"ScanView" bundle:nil];
    UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:vc];
    [navigationController presentModalViewController:nv animated:NO];
	
    SearchController *sc = [SearchController newController];
    sc.delegate = self;
    sc.viewController = vc;
    sc.selectedShelf = nil;

    WebApi *api = [wf allocWebApi];
    [sc search:api withCode:code];
    [api release];

    [vc release];
    [nv release];
	
    return YES;
}

- (void)searchControllerFinish:(SearchController*)controller result:(BOOL)result
{
    // TBD エラーチェック
}

// AdMob
- (void)reportAppOpenToAdMob {
    NSString *appId;
    if ([Edition isLiteEdition]) {
        appId = @"306480147";
    } else {
        appId = @"298454705";
    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // we're in a new thread here, so we need our own autorelease pool
    // Have we already reported an app open?
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                        NSUserDomainMask, YES) objectAtIndex:0];
    NSString *appOpenPath = [documentsDirectory stringByAppendingPathComponent:@"admob_app_open"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:appOpenPath]) {
        // Not yet reported -- report now
        NSString *appOpenEndpoint = [NSString stringWithFormat:@"http://a.admob.com/f0?isu=%@&app_id=%@",
                                              [[UIDevice currentDevice] uniqueIdentifier], appId];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:appOpenEndpoint]];
        NSURLResponse *response;
        NSError *error;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if((!error) && ([(NSHTTPURLResponse *)response statusCode] == 200) && ([responseData length] > 0)) {
            [fileManager createFileAtPath:appOpenPath contents:nil attributes:nil]; // successful report, mark it as such
        }
    }
    [pool release];
}

@end
