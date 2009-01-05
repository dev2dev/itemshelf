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

// 棚クラス

#import <UIKit/UIKit.h>
#import "Common.h"
#import "Database.h"

/**
   Shelf type
*/
typedef enum 
{
    ShelfTypeNormal,  ///< Normal shelf
    ShelfTypeSmart    ///< Smart shelf
} ShelfType;

#define SHELF_ALL_PKEY	-99999	///< Special primary key for "All shelf".

@class Item;

/**
   Shelf class
*/
@interface Shelf : NSObject <NSFastEnumeration>
{
    NSMutableArray *array;	///< Array of items.
	
    int pkey;			///< Primary key of this shelf.
    NSString *name;		///< Name of this shelf.
    int sorder;			///< Sort order

    ShelfType shelfType;	///< Shelf type

    // smart shelf filter
    NSString *titleFilter;	///< Title filter of smart shelf
    NSString *authorFilter;	///< Author filter of smart shelf
    NSString *manufacturerFilter; ///< Manufacturer filter of smart shelf
}

@property(nonatomic,retain) NSMutableArray *array;
@property(nonatomic,assign) int pkey;
@property(nonatomic,retain) NSString *name;
@property(nonatomic,assign) int sorder;
@property(nonatomic,assign) ShelfType shelfType;
@property(nonatomic,retain) NSString *titleFilter;
@property(nonatomic,retain) NSString *authorFilter;
@property(nonatomic,retain) NSString *manufacturerFilter;

- (void)addItem:(Item*)item;
- (void)removeItem:(Item*)item;
- (BOOL)containsItem:(Item*)item;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len;

- (void)sortBySorder;

+ (void)checkTable;
- (void)loadRow:(dbstmt *)stmt;
- (void)insert;
- (void)delete;
- (void)updateName;
- (void)updateSorder;
- (void)updateSmartFilters;
@end

/**
   Smart shelf
*/
@interface Shelf(SmartShelf)
- (void)updateSmartShelf:(NSMutableArray *)shelves;

// private
- (NSMutableArray *)makeFilterStrings:(NSString *)filter;
- (BOOL)isMatchSmartShelf:(Item *)item;
- (BOOL)matchSmartFilter:(NSMutableArray *)filterStrings value:(NSString*)value;
@end
