#include <sys/time.h>

#import "PuzzlesFrontEnd.h"
#import "PuzzlesDrawingView.h"

#include "puzzles.h"

#pragma mark iPhone Front End


@implementation PuzzlesFrontEnd

@synthesize drawingView;
@synthesize statusLabel;

- (id)initWithGame:(const game*)aGame {
    if (self = [super init]) {
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

        if (midend_wants_statusbar(myMidend)) {
            CGRect labelFrame = self.view.bounds;
            labelFrame.size.height = 32; // TODO: fixed size here

            UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
            label.textAlignment = UITextAlignmentCenter;
            label.backgroundColor = [UIColor blackColor];
            label.textColor = [UIColor whiteColor];
            label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
	            UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
            self.statusLabel = label;
            [label release];
            [self.view addSubview:self.statusLabel];
        }

        CGRect viewFrame = self.view.bounds;
        if (self.statusLabel) {
            CGFloat labelHeight = self.statusLabel.frame.size.height;
            viewFrame.origin.y += labelHeight;
            viewFrame.size.height -= labelHeight;
        }

        int maxX = viewFrame.size.width, maxY = viewFrame.size.height;
        midend_size(myMidend, &maxX, &maxY, true);

        viewFrame.origin.x = viewFrame.origin.x + (viewFrame.size.width - maxX) / 2;
        viewFrame.origin.y = viewFrame.origin.y + (viewFrame.size.height - maxY) / 2;
        viewFrame.size.width = maxX;
        viewFrame.size.height = maxY;

        PuzzlesDrawingView *dv = [[PuzzlesDrawingView alloc] initWithFrame:viewFrame midend:myMidend];
        dv.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin
        	| UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        frontend_wrapper.drawingView = dv;
        self.drawingView = dv;
        [dv release];

        [self.view addSubview:dv];

        midend_redraw(myMidend);
    }
    return self;
}

// Assuming single touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *t = [touches anyObject];
    CGPoint p = [t locationInView:self.drawingView];
    midend_process_key(myMidend, p.x, p.y, LEFT_BUTTON);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *t = [touches anyObject];
    CGPoint p = [t locationInView:self.drawingView];
    midend_process_key(myMidend, p.x, p.y, LEFT_DRAG);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *t = [touches anyObject];
    CGPoint p = [t locationInView:self.drawingView];
    midend_process_key(myMidend, p.x, p.y, LEFT_RELEASE);
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *t = [touches anyObject];
    CGPoint p = [t locationInView:self.drawingView];
    midend_process_key(myMidend, p.x, p.y, LEFT_RELEASE);
}

+ (void)randomSeed:(void**)randseed size:(int*)randseedsize {
    time_t *tp = snew(time_t);
    time(tp);
    *randseed = (void *)tp;
    *randseedsize = sizeof(time_t);
}

+ (void)fatal:(NSString*)message {
    [NSException raise:@"FrontEndFatal" format:@"%@", message];
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
        [actions addObject:@"Solve"];
        [actions addObject:@"Restart"];
        [actions addObject:@"New"];
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

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        return;
    }
    else {
        NSString *action = [[self configurationActions] objectAtIndex:buttonIndex-1];
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
        else if ([action isEqualToString:@"Restart"]) {
            midend_restart_game(myMidend);
        }
        else if ([action isEqualToString:@"New"]) {
            midend_process_key(myMidend, -1, -1, 'n');
        }
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

- (void)viewDidUnload {
    self.drawingView = nil;
    self.statusLabel = nil;
}

- (void) dealloc {
    [configurationActions release];
    self.drawingView = nil;
    self.statusLabel = nil;
    midend_free(myMidend);
    [super dealloc];
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
