#import "PuzzlesAppDelegate.h"

@implementation PuzzlesAppDelegate

@synthesize window;
@synthesize initialViewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    window.frame = [[UIScreen mainScreen] bounds];
    [window addSubview:initialViewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
