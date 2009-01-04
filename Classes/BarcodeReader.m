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

#import "BarcodeReader.h"
#import "zebra.h"

static void data_handler(zebra_image_t *zimage, const void *userdata);

@implementation BarcodeReader

@synthesize type, data;

- (id)init
{
    self = [super init];
    if (self) {
        scanner = zebra_image_scanner_create();
        zebra_image_scanner_set_data_handler(scanner, data_handler, self);
        type = -1;
        data = nil;
    }
    return self;
}

- (void)dealloc
{
    zebra_image_scanner_destroy(scanner);
    [super dealloc];
}

- (BOOL)recognize:(UIImage *)uimage
{
    self.data = nil;
	
    zebra_image_t *zimage = [self UIImageToZImage:uimage];
    zebra_scan_image(scanner, zimage);
    zebra_image_destroy(zimage);

    if (self.data == nil) {
        return NO;
    }
    return YES;
}

// スキャン完了すると呼ばれる
static void data_handler(zebra_image_t *zimage, const void *userdata)
{
    const zebra_symbol_t *symbol = zebra_image_first_symbol(zimage);
    zebra_symbol_type_t type = zebra_symbol_get_type(symbol);
    const char *data = zebra_symbol_get_data(symbol);
    LOG(@"Symbol: %d %s", type, data);
	
    BarcodeReader *reader = (BarcodeReader *)userdata;
	
    // 最初に見つかったほうのバーコードを使う
    if (reader.type < 0) {
        reader.type = type;
        reader.data = [NSString stringWithCString:data];
    }
}



#define fourcc(a, b, c, d)                              \
    ((uint32_t)(a) | ((uint32_t)(b) << 8) |             \
     ((uint32_t)(c) << 16) | ((uint32_t)(d) << 24))

- (zebra_image_t *)UIImageToZImage:(UIImage*)uimage
{
    // Step 1 : UIImage から gray scale の生データを取り出す
    CGImageRef image = uimage.CGImage;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    int width = CGImageGetWidth(image);
    int height = CGImageGetHeight(image);
    CGRect imageRect = CGRectMake(0, 0, width, height);
	
    int bitsPerComponent = 8;
    int bytesPerRow = 1 * width;
    int bitmapByteCount = bytesPerRow * height;
	
    void *bitmap = malloc(bitmapByteCount);
	
    CGContextRef context = CGBitmapContextCreate(bitmap, width, height, 
                                                 bitsPerComponent, bytesPerRow, 
                                                 colorSpace, 0);
    CGContextDrawImage(context, imageRect, image);

    // Step 2: zebra image に設定
    zebra_image_t *zimage = zebra_image_create();
    zebra_image_set_format(zimage, fourcc('Y', '8', 0, 0)); // gray scale
    zebra_image_set_size(zimage, width, height);
    zebra_image_set_data(zimage, bitmap, bitmapByteCount, NULL);
	
    CGContextRelease(context);
    // bitmap は zimage の解放時に解放される。

    return zimage;
}

@end
