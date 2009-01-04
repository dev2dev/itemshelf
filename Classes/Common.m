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

void AssertFailed(const char *filename, int line)
{
    NSLog(@"Assertion failed: %s line %d", filename, line);
    UIAlertView *v = [[UIAlertView alloc]
                         initWithTitle:@"Assertion Failed"
                         message:[NSString stringWithFormat:@"%s line %d", filename, line]
                         delegate:nil
                         cancelButtonTitle:@"Close"
                         otherButtonTitles:nil];
    [v show];
    [v release];
}

@implementation Common
/*
  - (id)init
  {
  self = [super init];
  return self;
  }
*/
+ (void)showAlertDialog:(NSString*)title message:(NSString*)message
{
    UIAlertView *av = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(title, @"")
                          message:NSLocalizedString(message, @"") 
                          delegate:nil 
                          cancelButtonTitle:NSLocalizedString(@"Close", @"") 
                          otherButtonTitles:nil];
    [av show];
    [av release];
}


+ (UIImage *)resizeImageWithin:(UIImage *)image width:(double)maxWidth height:(double)maxHeight
{
    double ratio = 1.0;
    double width = image.size.width;
    double height = image.size.height;
	
    if (height > maxHeight) {
        ratio = maxHeight / height;
    }
    if (width > maxWidth) {
        double r = maxWidth / width;
        if (r < ratio) {
            ratio = r;
        }
    }
	
    if (ratio == 1.0) {
        return image; // do nothing
    }
    width = (int)(width * ratio);
    height = (int)(height * ratio);
	
    return [Common resizeImage:image width:width height:height];
}

+ (UIImage *)resizeImage:(UIImage *)image width:(double)width height:(double)height
{
    //	return [image _imageScaledToSize:CGSizeMake(width, height) interpolationQuality:0];
	
    CGSize newSize = CGSizeMake(width, height);
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

@end

@implementation UIViewController (MyExt)

- (void)doModalWithNavigationController:(UIViewController *)vc
{
    UINavigationController *newnv = [[UINavigationController alloc]
                                        initWithRootViewController:vc];
    [self.navigationController presentModalViewController:newnv animated:YES];
    [newnv release];
}

@end
