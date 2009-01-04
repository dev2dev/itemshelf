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

@implementation Shelf (SmartShelf)

static NSMutableArray *titleFilterStrings = nil;
static NSMutableArray *authorFilterStrings = nil;
static NSMutableArray *manufacturerFilterStrings = nil;

// SmartShelf を update する
- (void)updateSmartShelf:(NSMutableArray *)shelves
{
    if (shelfType == ShelfTypeNormal) return;

    [array removeAllObjects];

    titleFilterStrings = [self makeFilterStrings:titleFilter];
    authorFilterStrings = [self makeFilterStrings:authorFilter];
    manufacturerFilterStrings = [self makeFilterStrings:manufacturerFilter];

    for (Shelf *shelf in shelves) {
        if (shelf.shelfType != ShelfTypeNormal) continue;

        for (Item *item in shelf.array) {
            if ([self isMatchSmartShelf:item]) {
                [array addObject:item];
            }
        }
    }

    [titleFilterStrings release];
    [authorFilterStrings release];
    [manufacturerFilterStrings release];
}

// ',' で分割した文字列配列を返す
- (NSMutableArray *)makeFilterStrings:(NSString *)filter
{
    NSMutableArray *ary = [[NSMutableArray alloc] initWithCapacity:3];

    NSString *token;
    while (filter != nil) {
        NSRange range = [filter rangeOfString:@","];
        if (range.location != NSNotFound) {
            token = [filter substringToIndex:range.location-1];
            if (range.location <= filter.length - 2) {
                filter = [filter substringFromIndex:range.location+1];
            } else {
                filter = nil;
            }
        } else {
            token = filter;
            filter = nil;
        }

        // trim space
        token = [token stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (token.length > 0) {
            [ary addObject:token];
        }
    }

    return ary;
}

- (BOOL)isMatchSmartShelf:(Item *)item
{
    if (shelfType == ShelfTypeNormal) {
        return NO;
    }

    BOOL result;
    result = [self matchSmartFilter:titleFilterStrings value:item.name];
    if (!result) return NO;

    result = [self matchSmartFilter:authorFilterStrings value:item.author];
    if (!result) return NO;

    result = [self matchSmartFilter:manufacturerFilterStrings value:item.manufacturer];
    if (!result) return NO;

    return YES;
}

- (BOOL)matchSmartFilter:(NSMutableArray *)filterStrings value:(NSString*)value
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
