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

#import "BarcodePickerController.h"
#import "BarcodeReader.h"

@implementation BarcodePickerController

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

- (void)setDelegate:(id<BarcodePickerControllerDelegate>)delegate
{
    [super setDelegate:delegate];
}

- (id<BarcodePickerControllerDelegate>)delegate
{
    return (id<BarcodePickerControllerDelegate>)[super delegate];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"BarcodePickerController: viewDidAppear");
    [super viewDidAppear:animated];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerHandler:) userInfo:nil repeats:YES];
    [timer retain];
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"BarcodePickerController: viewDidDisappear");
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

- (void)timerHandler:(NSTimer*)timer
{
    //NSLog(@"timer");

    UIImage *image = [UIImage imageWithCGImage:UIGetScreenImage()];
    if ([reader recognize:image]) {
        NSString *code = reader.data;
        NSLog(@"Code = %@", code);

        [self.delegate barcodePickerController:(BarcodePickerController*)self didRecognizeBarcode:(NSString*)code];
    } else {
        NSLog(@"No code");
    }
}

@end
