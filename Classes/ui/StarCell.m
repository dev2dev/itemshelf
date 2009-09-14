// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
/*
  ItemShelf for iPhone/iPod touch

  Copyright (c) 2008-2009, ItemShelf Development Team. All rights reserved.

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

#import "StarCell.h"

@implementation StarCell

#define REUSE_CELL_ID @"StarCellId"

#define CELL_HEIGHT 42
#define CELL_WIDTH 280
#define STAR_IMAGE_WIDTH 120
#define STAR_IMAGE_HEIGHT 22

+ (StarCell *)getCell:(UITableView *)tableView star:(int)star
{
    StarCell *cell = (StarCell*)[tableView dequeueReusableCellWithIdentifier:REUSE_CELL_ID];
    if (cell == nil) {
        cell = [[[StarCell alloc] init] autorelease];
    }
    [cell setStar:star];
    return cell;
}

- (id)init
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSE_CELL_ID];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    // スター画像領域
    imageView =
        [[[UIImageView alloc]
          initWithFrame:CGRectMake((CELL_WIDTH - STAR_IMAGE_WIDTH) / 2, (CELL_HEIGHT - STAR_IMAGE_HEIGHT) / 2,
                                   STAR_IMAGE_WIDTH, STAR_IMAGE_HEIGHT)] autorelease];
    imageView.tag = 0;
    imageView.autoresizingMask = 0;
    imageView.contentMode = UIViewContentModeScaleAspectFit; // 画像のアスペクト比を変えないようにする。
    imageView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:imageView];

    return self;
}

- (void)setStar:(int)star
{
    static UIImage *starImages[6];
    if (starImages[0] == nil) {
        // initial
        int i;
        for (i = 0; i <= 5; i++) {
            NSString *name = [NSString stringWithFormat:@"Star%d", i];
            starImages[i] = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"png"]] retain];
        }
    }

    ASSERT(0 <= star && star <= 5);
    ASSERT(starImages[star] != nil);
    if (star < 0 || star > 5) star = 0; // safety

    UIImage *img = starImages[star];
    imageView.image = img;
}

@end
