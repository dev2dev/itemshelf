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

#import "ItemCell4.h"

@implementation ItemCell4

#define REUSE_CELL_ID @"ItemCell4Id"

+ (ItemCell4 *)getCell:(UITableView *)tableView
{
    ItemCell4 *cell = (ItemCell4*)[tableView dequeueReusableCellWithIdentifier:REUSE_CELL_ID];
    if (cell == nil) {
        cell = [[[ItemCell4 alloc] init] autorelease];
    }
    return cell;
}

- (id)init
{
    static UIImage *backgroundImage = nil;

    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSE_CELL_ID];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    if (backgroundImage == nil) {
        backgroundImage = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ItemCellBack" ofType:@"png"]] retain];
    }
	
    // 背景
    UIImageView *backImage = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, ITEM_CELL_HEIGHT)] autorelease];
    backImage.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    backImage.image = backgroundImage;
    [self.contentView addSubview:backImage];
	
    // 画像
    UIImageView *imgView;
    int n = [ItemCell4 numItemsPerCell];
    for (int i = 0; i < n; i++) {
        imgView = [[[UIImageView alloc]
                       initWithFrame:CGRectMake(ITEM_IMAGE_WIDTH * i,
                                                ITEM_CELL_HEIGHT - ITEM_IMAGE_HEIGHT - 8,
                                                ITEM_IMAGE_WIDTH, ITEM_IMAGE_HEIGHT)]
                      autorelease];
        imgView.tag = i + 1;
        imgView.autoresizingMask = 0;
        imgView.contentMode = UIViewContentModeScaleAspectFit; // 画像のアスペクト比を変えないようにする。
        //imgView.contentMode = UIViewContentModeBottom;
        imgView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:imgView];
    }

    return self;
}

- (void)setItem:(Item *)item atIndex:(int)index
{
    UIImageView *imgView = (UIImageView *)[self.contentView viewWithTag:index + 1];

    if (item != nil) {
        UIImage *image = [item getImage:nil];
        imgView.image = image;
#if 0
        imgView.image = [Common resizeImageWithin:image
                                width:ITEM_IMAGE_WIDTH - ITEM_IMAGE_WIDTH_PADDING
                                height:ITEM_IMAGE_HEIGHT];
#endif
    } else {
        imgView.image = nil;
    }
}

+ (int)numItemsPerCell
{
    if (IS_IPAD) {
        return 9;
    }
    return 4;
}

@end
