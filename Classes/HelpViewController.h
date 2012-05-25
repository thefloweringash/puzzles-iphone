#import <UIKit/UIKit.h>

#import "HelpViewControllerDelegate.h"

@interface HelpViewController : UIViewController

- (id)initWithHelpTopic:(NSString*)helpTopic;

@property (nonatomic, retain) id<HelpViewControllerDelegate> delegate;

@end
