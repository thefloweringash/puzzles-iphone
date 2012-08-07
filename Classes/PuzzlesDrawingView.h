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
@property (nonatomic, assign) midend *midend;
@property (nonatomic, readonly) NSArray *colours;

+ (const drawing_api*)drawingAPI;

@end
