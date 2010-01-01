#include <sys/time.h>

#import "PuzzlesFrontEnd.h"
#import "PuzzlesDrawingView.h"
#import "PuzzlesConfigurationViewController.h"

#include "puzzles.h"

#pragma mark iPhone Front End


@implementation PuzzlesFrontEnd

@synthesize statusLabel;
@synthesize puzzleView;

- (id)initWithGame:(const game*)aGame {
    if (self = [super initWithNibName:@"PuzzlesFrontEnd" bundle:nil]) {
        frontend_wrapper.object = self;

        myGame = aGame;

        self.navigationItem.title =
        	[NSString stringWithCString:myGame->name
                               encoding:NSASCIIStringEncoding];

        self.navigationItem.rightBarButtonItem =
        	[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                           target:self
                                                           action:@selector(showConfigureMenu)]
             autorelease];

        myMidend = midend_new(&frontend_wrapper, myGame,
                              [PuzzlesDrawingView drawingAPI],
                              &frontend_wrapper);
        midend_new_game(myMidend);
    }
    return self;
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.puzzleView layoutSubviews];
}


// Assuming single touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *t = [touches anyObject];
    CGPoint p = [t locationInView:self.puzzleView];
    p = [self.puzzleView locationInViewToGamePoint:p];
    midend_process_key(myMidend, p.x, p.y, LEFT_BUTTON);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *t = [touches anyObject];
    CGPoint p = [t locationInView:self.puzzleView];
    p = [self.puzzleView locationInViewToGamePoint:p];
    midend_process_key(myMidend, p.x, p.y, LEFT_DRAG);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *t = [touches anyObject];
    CGPoint p = [t locationInView:self.puzzleView];
    p = [self.puzzleView locationInViewToGamePoint:p];
    midend_process_key(myMidend, p.x, p.y, LEFT_RELEASE);
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *t = [touches anyObject];
    CGPoint p = [t locationInView:self.puzzleView];
    p = [self.puzzleView locationInViewToGamePoint:p];
    midend_process_key(myMidend, p.x, p.y, LEFT_RELEASE);
}

- (void)defaultColour:(float*)output {
    output[0] = output[1] = output[2] = 0.8f;
}

- (void)activateTimer
{
    if (timer) {
        return;
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:0.02
                                             target:self
                                           selector:@selector(timerTick:)
                                           userInfo:nil
                                            repeats:YES];
    gettimeofday(&last_time, NULL);
}

- (void)deactivateTimer
{
    [timer invalidate];
    timer = nil;
}

- (void)timerTick:(id)sender
{
    struct timeval now;
    float elapsed;
    gettimeofday(&now, NULL);
    elapsed = ((now.tv_usec - last_time.tv_usec) * 0.000001F +
               (now.tv_sec - last_time.tv_sec));
    midend_timer(myMidend, elapsed);
    last_time = now;
}

- (void)setStatusText:(NSString*)status {
    self.statusLabel.text = status;
}

- (NSArray*)configurationActions {
    if (!configurationActions) {
        NSMutableArray *actions = [NSMutableArray array];
        if (myGame->can_solve) {
            [actions addObject:@"Solve"];
        }
        [actions addObject:@"Configure"];
        configurationActions = [actions retain];
    }
    return configurationActions;
}

- (void)showConfigureMenu {
    UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:@"Configure"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:nil]
                            autorelease];
    for (NSString *action in [self configurationActions]) {
        [sheet addButtonWithTitle:action];
    }
    [sheet showInView:self.view];
}

#pragma mark -
#pragma mark Game Interface

- (IBAction)undo:(id)sender {
    midend_process_key(myMidend, -1, -1, 'u');
}

- (IBAction)redo:(id)sender {
    midend_process_key(myMidend, -1, -1, 'r');
}

- (IBAction)restart:(id)sender {
    midend_restart_game(myMidend);
}

- (IBAction)new:(id)sender {
    midend_process_key(myMidend, -1, -1, 'n');
}

- (void)gameParamsChanged {
    gameParamsChanged = YES;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        return;
    }
    else {
        NSString *action = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([action isEqualToString:@"Solve"]) {
            char *result = midend_solve(myMidend);
            if (result) {
                [[[[UIAlertView alloc] initWithTitle:@"Solve Failed"
                                             message:[NSString stringWithCString:result encoding:NSASCIIStringEncoding]
                                            delegate:nil
                                   cancelButtonTitle:@"Dismiss"
                                   otherButtonTitles:nil]
                  autorelease]
                 show];
            }
        }
        else if ([action isEqualToString:@"Configure"]) {
            UIViewController *vc = [[PuzzlesConfigurationViewController alloc] initWithFrontEnd:self midend:myMidend game:myGame];
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
        }
    }
}


#pragma mark -
#pragma mark View Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    if (gameParamsChanged) {
        gameParamsChanged = NO;
        [self new:self];
        [self.puzzleView layoutSubviews];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    if (wasTiming) {
        [self activateTimer];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    wasTiming = timer != nil;
    [self deactivateTimer];
}

- (void)viewDidLoad {
    self.puzzleView.midend = myMidend;
    frontend_wrapper.drawingView = self.puzzleView;

    if (!midend_wants_statusbar(myMidend)) {
        CGRect labelFrame = self.statusLabel.frame;
        CGRect puzzleFrame = self.puzzleView.frame;
        self.puzzleView.frame = CGRectUnion(puzzleFrame, labelFrame);
    }

    [self.puzzleView layoutSubviews];
}

- (void)viewDidUnload {
    self.statusLabel = nil;
    self.puzzleView = nil;
}

- (void) dealloc {
    [configurationActions release];
    self.statusLabel = nil;
    self.puzzleView = nil;
    midend_free(myMidend);
    [super dealloc];
}

#pragma mark -
#pragma mark Non-Game Frontend

+ (void)randomSeed:(void**)randseed size:(int*)randseedsize {
    time_t *tp = snew(time_t);
    time(tp);
    *randseed = (void *)tp;
    *randseedsize = sizeof(time_t);
}

+ (void)fatal:(NSString*)message {
    [NSException raise:@"FrontEndFatal" format:@"%@", message];
}


@end

#pragma mark -
#pragma mark C Stubs

void frontend_default_colour(frontend *fe, float *output) {
    [fe->object defaultColour:output];
}

void activate_timer(frontend *fe) {
    [fe->object activateTimer];
}

void deactivate_timer(frontend *fe) {
    [fe->object deactivateTimer];
}

void fatal(char *fmt, ...) {
    // varargs are annoying, I package this up myself
    char *ret;

    va_list list;
    va_start(list, fmt);

    vasprintf(&ret, fmt, list);
    NSString *message = [NSString stringWithCString:ret encoding:NSASCIIStringEncoding];
    free(ret);

    va_end(list);

    [PuzzlesFrontEnd fatal:message];

}

void get_random_seed(void **randseed, int *randseedsize) {
    [PuzzlesFrontEnd randomSeed:randseed size:randseedsize];
}

void document_add_puzzle(document *doc, const game *game, game_params *par,
                         game_state *st, game_state *st2)
{
    // I can't see this port ever supporting printing.
    // This method is required by the midend
}
