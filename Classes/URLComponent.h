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

#import "Common.h"

@interface URLQuery : NSObject
{
    NSString *name;
    NSString *value;
}

@property(nonatomic,retain) NSString *name;
@property(nonatomic,retain) NSString *value;

@end

@interface URLComponent : NSObject
{
    NSString *scheme, *host, *path, *params, *query, *fragment;

    NSMutableArray *queries;
}

@property(nonatomic,retain) NSString *scheme;
@property(nonatomic,retain) NSString *host;
@property(nonatomic,retain) NSString *path;
@property(nonatomic,retain) NSString *params;
@property(nonatomic,retain) NSString *query;
@property(nonatomic,retain) NSString *fragment;
@property(nonatomic,retain) NSMutableArray *queries;

- (id)initWithURL:(NSURL *)url;
- (id)initWithURLString:(NSString *)urlString;
- (void)setURL:(NSURL *)url;
- (void)setURLString:(NSString*)urlString;
- (NSString*)absoluteString;
- (NSURL*)url;

- (void)parseQuery;
- (void)composeQuery;

- (URLQuery*)URLQuery:(NSString*)name; // private
- (NSString*)query:(NSString*)name;
- (void)setQuery:(NSString*)name value:(NSString*)value;
- (void)removeQuery:(NSString*)name;

- (void)log;

@end
