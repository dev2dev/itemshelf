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

#import "WebServer.h"
#import "Database.h"
#import "Item.h"

#define PORT_NUMBER		8888

@implementation WebServer

/**
   Start web server
*/
- (BOOL)startServer
{
    int on;
    struct sockaddr_in addr;

    listen_sock = socket(AF_INET, SOCK_STREAM, 0);
    if (listen_sock < 0) {
        return NO;
    }

    on = 1;
    setsockopt(listen_sock, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));

    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = htons(PORT_NUMBER);

    if (bind(listen_sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(listen_sock);
        return NO;
    }
	
    socklen_t len = sizeof(serv_addr);
    if (getsockname(listen_sock, (struct sockaddr *)&serv_addr, &len)  < 0) {
        close(listen_sock);
        return NO;
    }

    if (listen(listen_sock, 16) < 0) {
        close(listen_sock);
        return NO;
    }

    [self retain];
    thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMain:) object:nil];
    [thread start];
	
    return YES;
}

/**
   Stop web server
*/
- (void)stopServer
{
    if (listen_sock >= 0) {
        close(listen_sock);
    }
    listen_sock = -1;
}

/**
   Decide server URL
*/
- (NSString*)serverUrl
{
    // connect dummy UDP socket to get local IP address.
    int s = socket(AF_INET, SOCK_DGRAM, 0);
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(0x01010101); // dummy address
    addr.sin_port = htons(80);
	
    if (connect(s, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(s);
        return nil;
    }
	
    socklen_t len = sizeof(addr);
    getsockname(s, (struct sockaddr*)&addr, &len);
    close(s);

    char addrstr[64];
    inet_ntop(AF_INET, (void*)&addr.sin_addr.s_addr, addrstr, sizeof(addrstr));

    NSString *url;
    if (PORT_NUMBER == 80) {
        url = [NSString stringWithFormat:@"http://%s", addrstr];
    } else {
        url = [NSString stringWithFormat:@"http://%s:%d", addrstr, PORT_NUMBER];
    }
    return url;
}

/**
   Server thread
*/
- (void)threadMain:(id)dummy
{	
    NSAutoreleasePool *pool;
    pool = [[NSAutoreleasePool alloc] init];
	
    int s;
    socklen_t len;
    struct sockaddr_in caddr;
	
    for (;;) {
        len = sizeof(caddr);
        s = accept(listen_sock, (struct sockaddr *)&caddr, &len);
        if (s < 0) {
            break;
        }

        [self handleHttpRequest:s];

        close(s);
    }

    if (listen_sock >= 0) {
        close(listen_sock);
    }
    listen_sock = -1;
	
    [pool release];

    [self release];
    [NSThread exit];
}

/**
   Read http header line
*/
- (BOOL)readLine:(int)s line:(char *)line size:(int)size
{
    char *p = line;

    whiel (p < line + size) {
        int len = read(s, p, 1);
        if (len <= 0) {
            return NO;
        }
        if (p > line && *p == '\n' && *(p-1) == '\r') {
            *(p-1) = 0; // null terminate;
            return YES;
        }
        p++;
    }
    return NO; // not reach here...
}

/**
   Recv http body
*/
- (char *)readBody:(int)s contentLength:(int)contentLength
{
    char *buf, *p;
    int len, remain;

    if (contentLength < 0) {
        len = 1024*10; // ad hoc
    } else {
        len = contentLength;
    }
    
    buf = malloc(len + 1);
    p = buf;
    remain = len;

    while (remain > 0) {
        int rlen = read(s, p, remain);
        if (rlen < 0) {
            free(buf);
            return NULL;
        }
        if (contentLength < 0) break;

        p += rlen;
        remain -= rlen;
    }

    *p = 0; // null terminate;
    return buf;
}

/**
   Handle http request
*/
- (void)handleHttpRequest:(int)s
{
    char line[1024];
    int lineno = 0;
    NSString *filereq = @"/";
    int contentLength = -1;

    // read headers
    for (;;) {
        if (![self readLine:s line:line size:(sizeof)line]) {
            return; // error
        }
        NSLog(@"%s", line);
        
        if (strlen(line) == 0) {
            break; // end of header
        }

        if (lineno == 0) {
            // request line
            char *p, *p2;
            p = strtok(line, " ");
            if (p) p2 = strtok(NULL, " ");
            if (p2) filereq = [NSString stringWithCString:p2];
        }

        else if (strncasecmp(line, "Content-Length:", 15) == 0) {
            contentLength = atoi(line + 15);
        }

        lineno++;
    }

    // read body
    char *body = NULL;
    if (contentLength > 0) {
        body = [self readBody:s contentLength:contentLength];
    }

    // Request to '/' url.
    if ([filereq isEqualToString:@"/"])
    {
        [self sendIndexHtml:s];
    }

    // download
    else if ([filereq isEqualToString:@"/itemshelf.db"]) {
        [self sendBackup:s];
    }
            
    // upload
    else if ([filereq isEqualToString:@"/restore"]) {
        [self restore:s body:body bodylen:contentLength];
    }

    free(body);
    return;
}

/**
   Send reply in string
*/
- (void)send:(int)s string:(NSString *)string
{
    write(s, [string UTF8String], [string length]);
}

/**
   Send top page
*/
- (void)sendIndexHtml:(int)s
{
    [self send:s string:@"HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n"];

    [self send:s string:@"<html><body>"];
    [self send:s string:@"<h1>Backup</h1>"];
    [self send:s string:@"<form method=\"get\" action=\"/itemshelf.db\"><input type=submit value=\"Backup\"></form>"];

    [self send:s string:@"<h1>Restore</h1>"];
    [self send:s string:@"<form method=\"post\" enctype=\"multipart/form-data\"action=\"/restore\">"];
    [self send:s string:@"Select file to restore : <input type=file name=filename><br>"];
    [self send:s string:@"<input type=submit value=\"Restore\"></form>"];

    [self send:s string:@"</body></html>"];
}

/**
   Send backup file
*/
- (void)sendBackup:(int)s
{
    NSString *path = [[Database instance] dbPath];

    int f = open([path UTF8String], O_RDONLY);
    if (f < 0) {
        // file open error...
        // TBD
        return;
    }

    [self send:s string:@"HTTP/1.0 200 OK\r\nContent-Type:application/octet-stream\r\n\r\n"];

    char buf[1024];
    for (;;) {
        int len = read(f, buf, sizeof(buf));
        if (len == 0) break;

        write(s, buf, len);
    }
    close(f);
}

/**
   Restore from backup file
*/
- (void)restore:(int)s body:(char *)body bodylen:(int)bodylen
{
    NSLog(@"%s", body);
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

    // okay, save data between start and end.
    NSString *path = [[Database instance] dbPath];
    int f = open([path UTF8String], O_WRONLY);
    if (f < 0) {
        // TBD;
        return;
    }

    p = start;
    while (p < end) {
        int len = write(f, p, end - p);
        p += len;
    }
    close(f);

    // Clear all image data
    [Item deleteAllImageCache];
    
    // send reply
    [self send:s string:@"HTTP/1.0 200 OK\r\nContent-Type:text/html\r\n\r\n"];
    [self send:s string:@"Restore completed. Please restart the application."];

    // terminate application ...
    //[[UIApplication sharedApplication] terminate];
    exit(0);
}

@end
