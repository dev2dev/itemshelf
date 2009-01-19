@interface UICameraScanner : UIImagePickerController
@end

@implementation UICameraScanner

#define SOURCETYPE UIImagePickerControllerSourceTypeCamera

- (void)init
{
    self = [super init];

    if ([UIImagePickerController isSourceTypeAvailable:SOURCETYPE]) {
        self.sourceType = SOURCETYPE;
    }
    [self performSelector:@selector(updateView) withObject:NULL afterDelay:2.0f];

    reader = [[BarcodeReader alloc] init];

    return self;
}

- (void)dealloc
{
    [reader release];
    [super dealloc];
}

- (void)updateView
{
    // Remove the overlay views
    UIView *plView = [[[[[[self.view subviews] lastObject] subviews] lastObject] subviews] lastObject];
    [[[plView subviews] objectAtIndex:3] removeFromSuperview];

    [self performSelector:@selector(scanImage) withObject:NULL afterDelay:1.0f];
}

- (void)scanImage
{
    UIImage *image = [UIImage imageWithCGImage:UIGetScreenImage()];

    if ([reader recognize:image]) {
        // ok!
        [delegate cameraScannerDone:(NSString *)reader.data];
    }
    else {
        // retry
        [self performSelector:@selector(scanImage) withObject:NULL afterDelay:1.0f];
    }
}

@end
