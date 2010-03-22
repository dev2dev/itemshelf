// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
/*
  ItemShelf for iPhone/iPod touch

  Copyright (c) 2008-2009, ItemShelf Development Team. All rights reserved.

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

#import "BarcodeScannerController.h"
#import "BarcodeReader.h"

@implementation BarcodeScannerController

- (id)init
{
    self = [super init];
    reader = [[BarcodeReader alloc] init];
    return self;
}

- (void)dealloc
{
    [self _stopTimer];
    [reader release];

    [super dealloc];
}

- (void)setDelegate:(id<BarcodeScannerControllerDelegate>)delegate
{
    [super setDelegate:delegate];
}

- (id<BarcodeScannerControllerDelegate>)delegate
{
    return (id<BarcodeScannerControllerDelegate>)[super delegate];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"BarcodeScannerController: viewDidAppear");
    [super viewDidAppear:animated];
    
    if (self.sourceType == UIImagePickerControllerSourceTypeCamera) {
        // バーコード用ビューをオーバーレイする
        UIImage *overlay = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BarcodeReader" ofType:@"png"]];
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        imgView.image = overlay;

        // iPhone OS 3.1
        self.cameraOverlayView = imgView;
        [imgView release];
    }

    timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerHandler:) userInfo:nil repeats:YES];
    [timer retain];
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"BarcodeScannerController: viewDidDisappear");
    [super viewDidDisappear:animated];
 
    [self _stopTimer];
}

- (void)_stopTimer
{
    if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
}

extern CGImageRef UIGetScreenImage(); // undocumented

/**
 Timer Handler
 */
- (void)timerHandler:(NSTimer*)timer
{
    //NSLog(@"timer");

    // バーコードキャプチャ
    CGImageRef capture = UIGetScreenImage();
    CGImageRef clipped = CGImageCreateWithImageInRect(capture, CGRectMake(0, 240-30, 320, 60));
    
    UIImage *image = [UIImage imageWithCGImage:clipped];
    
    CGImageRelease(capture);
    CGImageRelease(clipped);
    
    if ([reader recognize:image]) {
        NSString *code = reader.data;
        NSLog(@"Code = %@", code);

        if ([self isValidBarcode:code]) {
            [self _stopTimer];
            [self.delegate barcodeScannerController:(BarcodeScannerController*)self didRecognizeBarcode:(NSString*)code];
        } else {
            NSLog(@"Invalid code");
        }
    } else {
        NSLog(@"No code");
    }
}

- (BOOL)isValidBarcode:(NSString *)code
{
    int n[13];
    
    if ([code length] == 13) {
        // EAN, JAN
        @try {
            for (int i = 0; i < 13; i++) {
                NSString *c = [code substringWithRange:NSMakeRange(i, 1)];
                if ([c isEqualToString:@"X"]) {
                    n[i] = 10;
                } else {
                    n[i] = [c intValue];
                }
            }
        }
        @catch (NSException *exception) {
            return NO;
        }

        int x1 = n[1] + n[3] + n[5] + n[7] + n[9] + n[11];
        x1 *= 3;

        int x2 = n[0] + n[2] + n[4] + n[6] + n[8] + n[10];
        int x = x1 + x2;

        int cd = 10 - (x % 10);
        cd = cd % 10;

        if (n[12] == cd) {
            return YES;
        }
        return NO;
    }
    
    // UPC or other code...
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

@end
