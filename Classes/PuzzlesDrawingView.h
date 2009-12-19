#import <UIKit/UIKit.h>

#include "puzzles.h"

@interface PuzzlesDrawingView : UIView {
    midend *myMidend;
    NSArray *colours;
    CGContextRef backingContext;
    BOOL clipped;
}

@property (nonatomic, assign) CGContextRef backingContext;
@property (nonatomic, assign) BOOL clipped;
@property (nonatomic, retain) NSArray *colours;
- (id)initWithFrame:(CGRect)frame midend:(midend*)aMidend;

+ (const drawing_api*)drawingAPI;

@end
