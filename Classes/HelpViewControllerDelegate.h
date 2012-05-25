#import <Foundation/Foundation.h>

@class HelpViewController;

@protocol HelpViewControllerDelegate <NSObject>

- (void)dismissHelpViewController:(HelpViewController *)helpViewController;

@end
