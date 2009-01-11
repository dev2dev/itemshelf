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

#import "WebServer.h"
#import <arpa/inet.h>

#define PORT_NUMBER		8888

@implementation WebServer

@synthesize contentBody, contentType, filename;

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
	
    thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMain:) object:nil];
    [thread start];
	
    return YES;
}

- (void)stopServer
{
    if (listen_sock >= 0) {
        close(listen_sock);
    }
    listen_sock = -1;
}

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
    [NSThread exit];
}

#define BUFSZ   1024*4

- (char *)recvData:(int)s
{
    char *buf = malloc(BUFSZ);
    int buflen = BUFSZ;
    int totallen = 0;
    char *p = buf;
    for (;;) {
        int len = read(s, p, buflen - totallen);
        if (len < 0) {
            free(buf);
            return NULL; // error
        }
        if (len == 0) {
            *p = 0; // EOF
            break;
        }
        p += len;
        totallen += len;

        if (buflen == totallen) {
            buflen += BUFSZ;
            buf = realloc(buf, buflen); // ###
            p = buf + totallen;
        }
    }

    return buf;
}

- (void)handleHttpRequest:(int)s
{
    char *buf = [self recvData:s];
    if (buf == NULL) return; // error

    NSArray *reqs = [[NSString stringWithCString:buf] componentsSeparatedByString:@"\r\n"];
    free(buf);

    // get request line
    NSString *reqline = [reqs objectAtIndex:0];
    NSRange range = [raqline rangeOfString:@" "];
    if (range.location == NSNotFound) return ; // error
    
    NSString *req = [reqline substringToIndex:range.location];
    reqline = [reqline substringFromIndex:range.location+1];

    range = [reqline rangeOfString:@"HTTP/"];
    if (range.location == NSNotFound) return ; // error

    NSString *filereq = [[getreq substringToIndex:range.location]
                            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

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
        [self restore:reqs];
    }
}

- (void)send:(int)s string:(NSString *)string
{
    write(s, [string UTF8String], [string length]);
}

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

- (void)sendBackup:(int)s
{
    [self send:s string:@"HTTP/1.0 200 OK\r\nContent-Type:application/octet-stream\r\n\r\n"];

    //write(s, hoge, len);
}
	
- (void)restore:(NSArray*)reqs
{
}

@end
