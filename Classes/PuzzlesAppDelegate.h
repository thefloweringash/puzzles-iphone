#import <UIKit/UIKit.h>

@interface PuzzlesAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UIViewController *initialViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *initialViewController;

@end

