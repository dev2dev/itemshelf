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

// Virtual Shelf

#import "Item.h"
#import "Shelf.h"
#import "DataModel.h"

@implementation Shelf(SmartShelf)

static NSMutableArray *titleFilterStrings = nil;
static NSMutableArray *authorFilterStrings = nil;
static NSMutableArray *manufacturerFilterStrings = nil;
static NSMutableArray *tagsFilterStrings = nil;

/**
   Update all items in smart shelves.
*/
- (void)updateSmartShelf:(NSMutableArray *)shelves
{
    if (shelfType == ShelfTypeNormal) return;

    [array removeAllObjects];

    titleFilterStrings = [self _makeFilterStrings:titleFilter];
    authorFilterStrings = [self _makeFilterStrings:authorFilter];
    manufacturerFilterStrings = [self _makeFilterStrings:manufacturerFilter];
    tagsFilterStrings = [self _makeFilterStrings:tagsFilter];

    for (Shelf *shelf in shelves) {
        if (shelf.shelfType != ShelfTypeNormal) continue;

        for (Item *item in shelf.array) {
            if ([self _isMatchSmartShelf:item]) {
                [array addObject:item];
            }
        }
    }

    [titleFilterStrings release];
    [authorFilterStrings release];
    [manufacturerFilterStrings release];
    [tagsFilterStrings release];
}

/**
   Returns array of filter tokens, which is separated with comma delimiter. (private)
*/ 
- (NSMutableArray *)_makeFilterStrings:(NSString *)filter
{
    return [filter splitWithDelimiter:@" ,"];
}

/**
   Check if the item is match to the smart shelf (private)
*/
- (BOOL)_isMatchSmartShelf:(Item *)item
{
    if (shelfType == ShelfTypeNormal) {
        return NO;
    }

    BOOL result;
    result = [self _isMatchSmartFilter:titleFilterStrings value:item.name];
    if (!result) return NO;

    result = [self _isMatchSmartFilter:authorFilterStrings value:item.author];
    if (!result) return NO;

    result = [self _isMatchSmartFilter:manufacturerFilterStrings value:item.manufacturer];
    if (!result) return NO;

    result = [self _isMatchSmartFilter:tagsFilterStrings value:item.tags];
    if (!result) return NO;

    return YES;
}

/**
   Check if the item is match to the filter tokens (private)
*/
- (BOOL)_isMatchSmartFilter:(NSMutableArray *)filterStrings value:(NSString*)value
{
    if (filterStrings.count == 0) return YES;
	
    for (NSString *filter in filterStrings) {
        NSRange range = [value rangeOfString:filter options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

@end
