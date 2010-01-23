#import <UIKit/UIKit.h>

#include "puzzles.h"

@protocol PuzzlesConfigurationDelegate;

@interface PuzzlesConfigurationChoicesViewController : UITableViewController {
    config_item *configItem;
    NSArray *choices;

    id<PuzzlesConfigurationDelegate> delegate;
}

@property (nonatomic, assign) id delegate;

- (id)initWithConfigItem:(config_item*)aConfigItem choicesCache:(NSArray*)theChoices;

@end
