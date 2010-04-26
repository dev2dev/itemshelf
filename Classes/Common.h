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

// 共通

#ifdef DEBUG
#define LOG(...) NSLog(__VA_ARGS__)
#define ASSERT(x) if (!(x)) AssertFailed(__FILE__, __LINE__)
void AssertFailed(const char *filename, int line);

#else
#define	LOG(...)  /**/
#define ASSERT(x) /**/
#endif

#import "StringArray.h"

#ifndef UI_USER_INTERFACE_IDIOM
#define IS_IPAD   NO // TBD
#else
#define IS_IPAD   (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#endif

/**
   Common utility class
 */
@interface Common : NSObject {
}

+ (void)showAlertDialog:(NSString*)title message:(NSString*)message;
+ (UIImage *)resizeImageWithin:(UIImage *)image width:(double)maxWidth height:(double)maxHeight;
+ (UIImage *)resizeImage:(UIImage *)image width:(double)width height:(double)height;
+ (NSString *)currencyString:(double)value withLocaleString:(NSString *)locale;
@end

/**
   Extended UIViewController
*/
@interface UIViewController (MyExt)
- (void)doModalWithNavigationController:(UIViewController *)vc;
@end

/**
   Extended UIButton
*/
@interface UIButton (MyExt)
- (void)setTitleForAllState:(NSString*)title;
@end

/**
   Extended string
*/
@interface NSString (MyExt)
- (NSMutableArray *)splitWithDelimiter:(NSString*)delimiters;
@end
