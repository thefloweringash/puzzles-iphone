#import <UIKit/UIKit.h>

#include "puzzles.h"

@interface PuzzlesDrawingView : UIView {
    midend *myMidend;
    NSArray *colours;
    CGContextRef backingContext;
    BOOL clipped;
    CGRect puzzleSubframe;
}

@property (nonatomic, assign) CGContextRef backingContext;
@property (nonatomic, assign) BOOL clipped;
@property (nonatomic, assign) midend *midend;
@property (nonatomic, readonly) NSArray *colours;


- (CGPoint)locationInViewToGamePoint:(CGPoint)p;

+ (const drawing_api*)drawingAPI;

@end
