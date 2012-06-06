#include <sys/time.h>

#import "PuzzlesFrontEnd.h"
#import "PuzzlesDrawingView.h"
#import "PuzzlesConfigurationViewController.h"

#import "HelpViewController.h"

#include "puzzles.h"

static void midend_serialise_block(struct midend *me, void (^write)(void *data, int size));
static char *midend_deserialise_block(struct midend *me, int (^read)(void *data, int size));


#pragma mark iPhone Front End

@interface PuzzlesFrontEnd () <HelpViewControllerDelegate> {
    BOOL _showingHelp;

    IBOutlet UIView *_puzzleViewContainer;
    id _resignActiveObserver;
    HelpViewController *_helpViewController;
}

- (void)listenForResignActive;
- (void)stopListeningForResignActive;

- (NSURL*)applicationDataDirectory;
- (NSURL*)pathForSaveGame;
- (NSURL*)ensureSaveDirectory;

- (void)saveGame;
- (void)loadGame;

@end

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
                                                           action:@selector(showConfigureMenu:)]
             autorelease];

        myMidend = midend_new(&frontend_wrapper, myGame,
                              [PuzzlesDrawingView drawingAPI],
                              &frontend_wrapper);
        midend_new_game(myMidend);

        [self loadGame];
        [self listenForResignActive];
    }
    return self;
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    else {
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
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
        [actions addObject:@"Help"];
        configurationActions = [actions retain];
    }
    return configurationActions;
}

- (IBAction)showConfigureMenu:(id)sender {
    BOOL isPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    BOOL isPhone = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;

    if (isPad && popoverConfigurationMenu) {
        return;
    }

    UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:@"Configure"
                                                        delegate:self
                                               cancelButtonTitle:nil
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:nil]
                            autorelease];
    if (isPad) {
        popoverConfigurationMenu = [sheet retain];
    }
    if (isPhone) {
        [sheet addButtonWithTitle:@"Cancel"];
        sheet.cancelButtonIndex = 0;
    }
    for (NSString *action in [self configurationActions]) {
        [sheet addButtonWithTitle:action];
    }
    if (isPad) {
        [sheet showFromBarButtonItem:sender animated:YES];
    }
    else {
        [sheet showInView:self.view];
    }
}

- (IBAction)hideConfigureMenu:(id)sender {
    [self viewWillAppear:YES];
    [self dismissModalViewControllerAnimated:YES];
    [self viewDidAppear:YES];
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

- (void)gameParametersChanged {
    gameParamsChanged = YES;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [popoverConfigurationMenu release];
    popoverConfigurationMenu = nil;
    if (buttonIndex == actionSheet.cancelButtonIndex) {
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
            UIViewController *vc = [[PuzzlesConfigurationViewController alloc] initWithDelegate:self midend:myMidend game:myGame];
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
                vc.navigationItem.rightBarButtonItem =
                    [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                   target:self
                                                                   action:@selector(hideConfigureMenu:)]
                     autorelease];
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
                nc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
                [self presentModalViewController:nc animated:YES];
                [nc release];
                [self viewDidDisappear:YES];
            }
            else {
                [self.navigationController pushViewController:vc animated:YES];
            }
            [vc release];
        }
        else if ([action isEqualToString:@"Help"]) {
            if (_showingHelp) {
                return;
            }
            _showingHelp = YES;

            HelpViewController *vc = [[HelpViewController alloc] initWithHelpTopic:
                                      [NSString stringWithCString:myGame->htmlhelp_topic encoding:NSASCIIStringEncoding]];
            vc.delegate = self;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                // we don't have the screen realestate to do anything fancy on a phone
                // just pop over a web view
                [self.navigationController pushViewController:vc animated:YES];
                [vc release];
            }
            else {
                // split main content view in half
                CGRect lhs, rhs;
                CGRectDivide(_puzzleViewContainer.bounds, &rhs, &lhs, _puzzleViewContainer.bounds.size.width / 2, CGRectMaxXEdge);

                vc.view.frame = CGRectOffset(rhs, rhs.size.width, 0);
                [_puzzleViewContainer addSubview:vc.view];

                [UIView animateWithDuration:0.3f animations:^{
                    self.puzzleView.frame = lhs;
                    vc.view.frame = rhs;
                }];
                _helpViewController = vc;
            }
        }
    }
}

- (void)dismissHelpViewController:(HelpViewController *)helpViewController {
    _showingHelp = NO;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [UIView animateWithDuration:0.5f
                         animations:^{
                             self.puzzleView.frame = _puzzleViewContainer.bounds;
                             CGRect oldHelpFrame = helpViewController.view.frame;
                             helpViewController.view.frame = CGRectOffset(oldHelpFrame, oldHelpFrame.size.width, 0);
                         }
                         completion:^(BOOL b) {
                             [helpViewController.view removeFromSuperview];
                             [_helpViewController release];
                             _helpViewController = nil;
                         }];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
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
    [self listenForResignActive];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (popoverConfigurationMenu) {
        [popoverConfigurationMenu dismissWithClickedButtonIndex:popoverConfigurationMenu.cancelButtonIndex animated:YES];
    }
    [self stopListeningForResignActive];
    [self saveGame];
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
        CGRect puzzleFrame = _puzzleViewContainer.frame;
       _puzzleViewContainer.frame = CGRectUnion(puzzleFrame, labelFrame);
    }

    [self.puzzleView layoutSubviews];
}

- (void)viewDidUnload {
    [_helpViewController.view removeFromSuperview];
    [_helpViewController release];

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


#pragma mark -
#pragma mark Game persistence

- (void)listenForResignActive {
    if (!_resignActiveObserver) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        _resignActiveObserver = [[nc addObserverForName:UIApplicationWillResignActiveNotification
                                                 object:[UIApplication sharedApplication]
                                                  queue:NSOperationQueuePriorityNormal
                                             usingBlock:^(NSNotification *note) {
                                                 [self saveGame];
                                             }] retain];
    }
}

- (void)stopListeningForResignActive {
    if (_resignActiveObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_resignActiveObserver];
        [_resignActiveObserver release];
        _resignActiveObserver = nil;
    }
}

- (NSURL*)applicationDataDirectory {
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    NSArray* possibleURLs = [sharedFM URLsForDirectory:NSApplicationSupportDirectory
                                             inDomains:NSUserDomainMask];
    NSURL* appSupportDir = nil;
    NSURL* appDirectory = nil;

    if ([possibleURLs count] >= 1) {
        // Use the first directory (if multiple are returned)
        appSupportDir = [possibleURLs objectAtIndex:0];
    }

    // If a valid app support directory exists, add the
    // app's bundle ID to it to specify the final directory.
    if (appSupportDir) {
        NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
        appDirectory = [appSupportDir URLByAppendingPathComponent:appBundleID];
    }

    return appDirectory;
}

- (NSURL*)ensureSaveDirectory {
    NSURL *dir = [self applicationDataDirectory];

    BOOL isDir;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:[dir path] isDirectory:&isDir]) {
        if (!isDir) {
            NSLog(@"Save game directory exists but is not directory");
            return nil;
        }
    }
    else {
        NSError *err;
        if ([fm createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:&err] == NO) {
            NSLog(@"Failed creating save game directory: %@", err);
            return nil;
        }
    }

    return dir;
}

- (NSURL*)pathForSaveGame {
    return [[self applicationDataDirectory] URLByAppendingPathComponent:[NSString stringWithCString:myGame->name encoding:NSASCIIStringEncoding]];
}

- (void)saveGame {
    NSMutableData *serialized = [[NSMutableData alloc] init];
    midend_serialise_block(myMidend, ^(void *data, int size){
        [serialized appendBytes:data length:size];
    });

    if (![self ensureSaveDirectory]) {
        NSLog(@"No save directory available, aborting save");
        return;
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL saveOK = [fm createFileAtPath:[[self pathForSaveGame] path]
                              contents:serialized
                            attributes:nil];
    if (!saveOK) {
        NSLog(@"Save failed");
    }
    [serialized release];
}

- (void)loadGame {
    NSFileManager *fm = [NSFileManager defaultManager];

    NSURL *savePath = [self pathForSaveGame];
    if (![fm fileExistsAtPath:[savePath path]]) {
        return;
    }

    NSData *serialized = [fm contentsAtPath:[savePath path]];
    __block int offset = 0;
    char *result = midend_deserialise_block(myMidend, ^int (void *data, int size) {
        int readLen = offset + size > [serialized length] ? [serialized length] - offset : size;
        [serialized getBytes:data range:NSMakeRange(offset, readLen)];
        offset += readLen;
        return readLen;
    });

    // result is error message or NULL
    if (result) {
        NSLog(@"Couldn't load game: %s", result);
    }
}

@end

#pragma mark -
#pragma mark C Stubs

static void midend_serialise_block_trampoline(void *ctx, void *data, int size) {
    void (^write)(void *, int) = ctx;
    write(data, size);
}

static void midend_serialise_block(struct midend *me, void (^write)(void *data, int size)) {
    midend_serialise(me, midend_serialise_block_trampoline, write);
}

static int midend_deserialise_block_trampoline(void *ctx, void *data, int size) {
    int (^read)(void *, int) = ctx;
    return read(data, size);
}

static char *midend_deserialise_block(struct midend *me, int (^read)(void *data, int size)) {
    return midend_deserialise(me, midend_deserialise_block_trampoline, read);
}

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
