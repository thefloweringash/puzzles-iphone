#import "CenteringScrollView.h"

@implementation CenteringScrollView

@synthesize viewToCenter = _viewToCenter;

// delicious copy pasta from PhotoScroller, simplified for single subview

- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    const UIView *v = _viewToCenter;

    // center the image as it becomes smaller than the size of the screen
    
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = v.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    v.frame = frameToCenter;
}

@end
