#import <UIKit/UIKit.h>

#include "puzzles.h"

@interface PuzzlesConfigurationChoicesViewController : UITableViewController {
    config_item *configItem;
    NSArray *choices;
}

- (id)initWithConfigItem:(config_item*)aConfigItem choicesCache:(NSArray*)theChoices;

@end
