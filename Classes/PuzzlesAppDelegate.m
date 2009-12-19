#import "PuzzlesAppDelegate.h"

@implementation PuzzlesAppDelegate

@synthesize window;
@synthesize initialViewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {

    [window addSubview:initialViewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
