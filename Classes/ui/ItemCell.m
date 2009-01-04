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

#import "ItemCell.h"

@implementation ItemCell

#define REUSE_CELL_ID @"ItemCellId"

+ (ItemCell *)getCell:(UITableView *)tableView
{
    ItemCell *cell = (ItemCell*)[tableView dequeueReusableCellWithIdentifier:REUSE_CELL_ID];
    if (cell == nil) {
        cell = [[[ItemCell alloc] init] autorelease];
    }
    return cell;
}


#define TAG_IMAGE   1
#define TAG_DESC    2
#define TAG_DATE    3

- (id)init
{
    static UIImage *backgroundImage = nil;

    self = [super initWithFrame:CGRectZero reuseIdentifier:REUSE_CELL_ID];
    self.selectionStyle = UITableViewCellSelectionStyleNone; // TBD
    //self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    CGRect b = self.bounds;
    b.size.height = ITEM_CELL_HEIGHT;
    self.bounds = b;
	
    if (backgroundImage == nil) {
        backgroundImage = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ItemCellBack" ofType:@"png"]] retain];
    }
	
    // 背景
    UIImageView *backImage = [[[UIImageView alloc] initWithFrame:self.bounds] autorelease];
    backImage.autoresizingMask = 0; /*UIViewAutoresizingFlexibleWidth;*/
    backImage.image = backgroundImage;
    //[self.contentView addSubview:backImage];
    self.backgroundView = backImage;
	
    // 画像
    UIImageView *imgView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, ITEM_CELL_HEIGHT - ITEM_IMAGE_HEIGHT - 8, ITEM_IMAGE_WIDTH, ITEM_IMAGE_HEIGHT)] autorelease];
    imgView.tag = TAG_IMAGE;
    imgView.autoresizingMask = 0;
    imgView.contentMode = UIViewContentModeScaleAspectFit; // 画像のアスペクト比を変えないようにする。
    //imgView.contentMode = UIViewContentModeBottom;
    imgView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:imgView];
    
    int label_x = ITEM_IMAGE_WIDTH + 5;
    int label_width = 320 - label_x - 10;

    // 名称
    UILabel *descLabel = [[[UILabel alloc] initWithFrame:CGRectMake(label_x, 10, label_width, 55)] autorelease];
    descLabel.tag = TAG_DESC;
    descLabel.font = [UIFont systemFontOfSize:15.0];
    descLabel.textColor = [UIColor blackColor];
    //descLabel.backgroundColor = [UIColor grayColor];
    descLabel.backgroundColor = [UIColor clearColor];
    descLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    descLabel.lineBreakMode = UILineBreakModeWordWrap;
    descLabel.numberOfLines = 0;
    [self.contentView addSubview:descLabel];
	
    // 日付
    UILabel *dateLabel = [[[UILabel alloc] initWithFrame:CGRectMake(label_x, 65, label_width, 18)] autorelease];
    dateLabel.tag = TAG_DATE;
    dateLabel.font = [UIFont systemFontOfSize:12.0];
    dateLabel.textColor = [UIColor darkGrayColor];
    //dateLabel.backgroundColor = [UIColor redColor];
    dateLabel.backgroundColor = [UIColor clearColor];
    dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:dateLabel];
	
    return self;
}

- (void)setItem:(Item *)item
{
    static NSDateFormatter *df = nil;

    if (df == nil) {
        df = [[NSDateFormatter alloc] init];
        [df setDateStyle:NSDateFormatterMediumStyle];
        [df setTimeStyle:NSDateFormatterShortStyle];
    }

    UILabel *descLabel = (UILabel *)[self.contentView viewWithTag:TAG_DESC];
    UILabel *dateLabel = (UILabel *)[self.contentView viewWithTag:TAG_DATE];
    UIImageView *imgView = (UIImageView *)[self.contentView viewWithTag:TAG_IMAGE];

    descLabel.text = item.name;
    dateLabel.text = [df stringFromDate:item.date];

    // resize image
    UIImage *image = [item getImage:nil];
    imgView.image = image;
#if 0
    imgView.image = [Common resizeImageWithin:image
                            width:ITEM_IMAGE_WIDTH - ITEM_IMAGE_WIDTH_PADDING
                            height:ITEM_IMAGE_HEIGHT];
#endif
}

@end
