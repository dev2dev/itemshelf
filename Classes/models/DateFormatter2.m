// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
/*
  CashFlow for iPhone/iPod touch

  Copyright (c) 2008, Takuya Murakami, All rights reserved.

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

#import "DateFormatter2.h"

@implementation DateFormatter2

- (id)init
{
    self = [super init];

    // JP locale では特に 12時間制のときの日付フォーマットがおかしいので、
    // US locale にする
    [self setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"US"] autorelease]];
    return self;
}

// 12時間制になってしまっているデータを強制的に変換する
- (NSString *)fixDateString:(NSString *)string
{
    int hoffset = 0;
    NSRange range;
    BOOL needFix = NO;

    // "午前"はそのまま削除
    range = [string rangeOfString:@"午前"];
    if (range.location != NSNotFound) {
        needFix = YES;
        hoffset = 0;
    } else {
        range = [string rangeOfString:@"午後"];
        if (range.location != NSNotFound) {
            needFix = YES;
            hoffset = 12;
        }
    }

    if (needFix) {
        // 時刻を取り出す
        NSRange hrange = range;
        hrange.location += range.length;
        hrange.length = 2;
        int hour = [[string substringWithRange] intValue];

        // 時刻を調整
        if (hour == 12) {
            // 午前12時 ⇒ 0時、午後12時 ⇒ 12時
            hour = 0;
        }
        hour += hoffset;
        NSString *hstr = [NSString stringWithFormat:@"%02d", hour];

        // 文字列を置換
        range.length += 2;
        string = [string stringByReplacingCharactersInRange:range withString:hstr];
    }

    return string;
}

- (NSDate *)dateFromString:(NSString *)string
{
    return [super dateFromString:[self fixDateString:string]];
}

@end
