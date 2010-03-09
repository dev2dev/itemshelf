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

#import <arpa/inet.h>
#import <fcntl.h>

#import "TmiWebServer.h"
#import "BackupServer.h"
#import "Item.h"
#import "AppDelegate.h"
#import "ZipArchive.h"

@implementation BackupServer
@synthesize filePath, dataName;

- (id)init
{
    self = [super init];
    if (self) {
        filePath = nil;
        dataName = nil;
    }
    return self;
}

- (void)dealloc
{
    [dataName release];
    [filePath release];
    [super dealloc];
}

- (void)requestHandler:(NSString*)path body:(char *)body bodylen:(int)bodylen
{
    NSString *dataPath = [NSString stringWithFormat:@"/%@", dataName];

    // Request to '/' url.
    if ([path isEqualToString:@"/"])
    {
        [self sendIndexHtml];
    }

    // download
    else if ([path hasPrefix:dataPath]) {
        [self sendBackup];
    }
            
    // upload
    else if ([path isEqualToString:@"/restore"]) {
        [self parseBody:body bodylen:bodylen];
    }

    else {
        [super requestHandler:path body:body bodylen:bodylen];
    }
}

/**
   Send top page
*/
- (void)sendIndexHtml
{
    [self sendString:@"HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n"];

    [self sendString:@"<html><body>"];
    [self sendString:@"<h1>Backup</h1>"];

    NSString *formAction =
        [NSString stringWithFormat:@"<form method=\"get\" action=\"/%@\">", dataName];
    [self sendString:formAction];
    [self sendString:@"<input type=submit value=\"Backup\">"];
    [self sendString:@"</form>"];

    [self sendString:@"<h1>Restore</h1>"];
    [self sendString:@"<form method=\"post\" enctype=\"multipart/form-data\"action=\"/restore\">"];
    [self sendString:@"Select file to restore : <input type=file name=filename><br>"];
    [self sendString:@"<input type=submit value=\"Restore\"></form>"];

    [self sendString:@"</body></html>"];
}

/**
   Send backup file
*/
- (void)sendBackup
{
#if 0
    // DB only...
    int f = open([filePath UTF8String], O_RDONLY);
#else
    // ZIP
    if (![self _zipArchive]) {
        // TBD
        return;
    }
    int f = open([[self _zipFileName] UTF8String], O_RDONLY);
#endif

    if (f < 0) {
        // file open error...
        // TBD
        return;
    }

    [self sendString:@"HTTP/1.0 200 OK\r\nContent-Type:application/octet-stream\r\n\r\n"];

    char buf[1024];
    for (;;) {
        int len = read(f, buf, sizeof(buf));
        if (len == 0) break;

        write(serverSock, buf, len);
    }
    close(f);
}

/**
   Parse body (mime multipart)
*/
- (void)parseBody:(char *)body bodylen:(int)bodylen
{
    //NSLog(@"%s", body);

    // get mimepart delimiter
    char *p = strstr(body, "\r\n");
    if (!p) return;
    *p = 0;
    char *delimiter = body;

    // find data start pointer
    p = strstr(p + 2, "\r\n\r\n");
    if (!p) return;
    char *start = p + 4;

    // find data end pointer
    char *end = NULL;
    int delimlen = strlen(delimiter);
    for (p = start; p < body + bodylen; p++) {
        if (strncmp(p, delimiter, delimlen) == 0) {
            end = p - 2; // previous new line
            break;
        }
    }
    if (!end) return;

    [self restore:start datalen:end - start];
}

/**
   Restore from backup file
*/
- (void)restore:(char *)data datalen:(int)datalen
{
    const char zipheader[4] = {0x50, 0x4b, 0x03, 0x04};
    BOOL isZip = NO;

    // Check data format
    if (memcmp(data, zipheader, 4) == 0) {
        // okey its zip file
        isZip = YES;
    }
    else if (strncmp(data, "SQLite format 3", 15) != 0) {
        [self sendString:@"HTTP/1.0 200 OK\r\nContent-Type:text/html\r\n\r\n"];
        [self sendString:@"This is not itemshelf database file. Try again."];
        return;
    }

    // okay, save data between start and end.
    int f = -1;

    if (isZip) {
        // save to zip file
        f = open([[self _zipFileName] UTF8String], O_WRONLY);
    } else {
        // save to DB directly
        f = open([filePath UTF8String], O_WRONLY);
    }
    if (f < 0) {
        // TBD;
        return;
    }

    char *p = data;
    char *end = data + datalen;
    while (p < end) {
        int len = write(f, p, end - p);
        p += len;
    }
    close(f);

    // Clear all image data
    [Item deleteAllImageCache];
    
    if (isZip) {
        if (![self _unzipArchive]) {
            [self sendString:@"HTTP/1.0 200 OK\r\nContent-Type:text/html\r\n\r\n"];
            [self sendString:@"Restoration failed. Try again..."];
            return;
        }
    }

    // send reply
    [self sendString:@"HTTP/1.0 200 OK\r\nContent-Type:text/html\r\n\r\n"];
    [self sendString:@"Restore completed. Please restart the application."];

    // terminate application ...
    //[[UIApplication sharedApplication] terminate];
    exit(0);
}

- (NSString *)_zipFileName
{
    return [AppDelegate pathOfDataFile:@"Backup.zip"];
}

- (BOOL)_zipArchive
{
    NSString *dir = [AppDelegate pathOfDataFile:nil];

    // ファイル一覧取得
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager subpathsAtPath:dir];
    
    ZipArchive *zip = [[[ZipArchive alloc] init] autorelease];
    [zip CreateZipFile2:[self _zipFileName]];

    for (NSString *file in files) {
        if ([file hasSuffix:@"db"] || [file hasPrefix:@"img-"]) {
            NSString *fullpath = [dir stringByAppendingPathComponent:file];
            [zip addFileToZip:fullpath newname:file];
        }
    }

    BOOL result = [zip CloseZipFile2];
    return result;
}

- (BOOL)_unzipArchive
{
    NSString *dir = [AppDelegate pathOfDataFile:nil];

    ZipArchive *zip = [[[ZipArchive alloc] init] autorelease];
    if (![zip UnzipOpenFile:[self _zipFileName]]) {
        // no file
        return NO;
    }

    [zip UnzipFileTo:dir overWrite:YES];
    [zip UnzipCloseFile];
    
    return YES;
}

@end
