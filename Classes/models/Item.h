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

// アイテム情報を格納するクラス

#import <UIKit/UIKit.h>
#import "Common.h"
#import "Database.h"

// 画像をメモリにキャッシュしておく個数
#define MAX_IMAGE_CACHE_AGE		70

@class Item;

@protocol ItemDelegate
- (void)itemDidFinishDownloadImage:(Item*)item;
@end


// Item 情報 : とりあえず仮で
@interface Item : NSObject 
{
    int pkey;		///< Primary key (for database)
    NSDate *date;	///< Registered date
    int shelfId;	///< Shelf ID (SHELF_*)

    int idType;		///< ID type (same as zebra_symbol_idtype_t)
    NSString *idString;	///< ID string (JAN/EAN/UPC etc.)
    NSString *asin;	///< ASIN: Amazon Standard Identification Number

    NSString *name;	///< Item name
    NSString *author;	///< Author
    NSString *manufacturer;	///< Manufacturer name
    NSString *productGroup;	///< Product Group (Category)
    NSString *detailURL;	///< URL of detail page of the item
    NSString *price;	///< Price info
    NSString *tags;	///< Tag info (reserved)

    NSString *memo;	///< User defined memo (reserved)
    NSString *imageURL;	///< URL of image
	
    UIImage *imageCache; ///< Image cache
	
    int sorder;		///< Sort order
	
    // image download 用
    NSMutableData *buffer;  ///< Temporary buffer to download image
    id<ItemDelegate> itemDelegate; ///< Delegate of ItemDelegate protocol

    // ItemView 用
    NSMutableArray *infoStrings; ///< Information strings, used with ItemView
    BOOL registeredWithShelf;  ///< Is registered in shelf?
}

@property(nonatomic,assign) int pkey;
@property(nonatomic,retain) NSDate *date;
@property(nonatomic,assign) int shelfId;
@property(nonatomic,assign) int idType;
@property(nonatomic,retain) NSString *idString;
@property(nonatomic,retain) NSString *asin;
@property(nonatomic,retain) NSString *name;
@property(nonatomic,retain) NSString *author;
@property(nonatomic,retain) NSString *manufacturer;
@property(nonatomic,retain) NSString *productGroup;
@property(nonatomic,retain) NSString *detailURL;
@property(nonatomic,retain) NSString *price;
@property(nonatomic,retain) NSString *tags;
@property(nonatomic,retain) NSString *memo;
@property(nonatomic,retain) NSString *imageURL;
@property(nonatomic,retain) UIImage *imageCache;
@property(nonatomic,assign) int sorder;
@property(nonatomic,retain) NSMutableArray *infoStrings;
@property(nonatomic,assign) BOOL registeredWithShelf;

- (BOOL)isEqualToItem:(Item*)item;
+ (void)checkTable;
- (void)loadRow:(dbstmt *)stmt;
- (void)insert;
- (void)delete;
- (void)changeShelf:(int)shelf;
- (void)updateSorder;

+ (void)clearAllImageCache;
- (UIImage *)getImage:(id<ItemDelegate>)delegate;
- (void)cancelDownload;
- (void)_refreshImageCache;
- (void)_putImageCache;
- (NSString*)_imageFileName;
- (NSString *)_imagePath; // private
- (void)_deleteImageFile;

@end
