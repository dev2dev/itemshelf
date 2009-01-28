// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-

//
//  main.m
//

#import <UIKit/UIKit.h>
#import <unistd.h>

#ifndef ENABLE_VALGRIND
#define ENABLE_VALGRIND 0
#endif

#define VALGRIND_PATH   "/usr/local/valgrind/bin/valgrind"

int main(int argc, char *argv[])
{
#if ENABLE_VALGRIND
    // check if in the simulator
    NSString *model = [[UIDevice currentDevice] model];
    if ([model isEqualToString:@"iPhone Simulator"]) {

        // execute myself with valgrind
        if (argc < 2 || strcmp(argv[1], "--valgrind") != 0) {
            execl(VALGRIND_PATH, VALGRIND_PATH, "--leak-check=full", argv[0], "--valgrind", NULL);
        }
    }
#endif

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
