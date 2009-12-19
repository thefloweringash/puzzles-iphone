#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include "puzzles.h"

@class PuzzlesFrontEnd, PuzzlesDrawingView;

struct frontend {
    PuzzlesFrontEnd *object;
    PuzzlesDrawingView *drawingView;
};

@interface PuzzlesFrontEnd : UIViewController<UIActionSheetDelegate> {
    frontend frontend_wrapper;
    const game *myGame;
    midend *myMidend;

    NSTimer *timer;
    struct timeval last_time;
    BOOL wasTiming;

    PuzzlesDrawingView* drawingView;
    UILabel *statusLabel;
    NSArray *configurationActions;
}

@property (nonatomic, retain) PuzzlesDrawingView *drawingView;
@property (nonatomic, retain) UILabel *statusLabel;

- (id)initWithGame:(const game*)aGame;

+ (void)randomSeed:(void**)randseed size:(int*)randseedsize;
+ (void)fatal:(NSString*)format;

- (void)defaultColour:(float*)output;
- (void)activateTimer;
- (void)deactivateTimer;

- (void)setStatusText:(NSString*)status;

- (NSArray*)configurationActions;
- (void)showConfigureMenu;

@end
