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

// データモデル

#import <UIKit/UIKit.h>
#import "Common.h"
#import "Item.h"
#import "Shelf.h"

/**
   Main data model of itemshelf, contains all shelves, items.
   
*/
@interface DataModel : NSObject
{
    NSMutableArray *shelves;	///< All shelves

//    NSString *currentCountry;	///< Current country setting
//    NSArray *countries;		///< Countries array
}

@property(nonatomic,retain) NSMutableArray *shelves;

+ (DataModel*)sharedDataModel;

- (void)loadDB;

- (Shelf *)shelf:(int)shelfId;
- (Shelf *)shelfAtIndex:(int)index;
- (int)shelvesCount;
- (void)addShelf:(Shelf *)shelf;
- (void)removeShelf:(Shelf *)shelf;
- (void)reorderShelf:(int)from to:(int)to;
- (NSMutableArray *)normalShelves;
- (void)updateSmartShelves;

- (void)addItem:(Item *)item;
- (void)removeItem:(Item *)item;
- (void)changeShelf:(Item *)item withShelf:(int)shelf;
- (Item *)findSameItem:(Item*)item;

- (NSMutableArray*)makeFilter:(Shelf *)shelf;

+ (NSMutableArray *)splitString:(NSString *)string;

//- (NSArray*)countries;
//- (NSString*)country;
//- (void)setCountry:(NSString*)country;

@end
