#import <UIKit/UIKit.h>

@class PuzzlesFrontEnd;

#include "puzzles.h"

@interface PuzzlesConfigurationViewController : UITableViewController<UITextFieldDelegate> {
    PuzzlesFrontEnd *puzzlesFrontEnd;
    midend *myMidend;
    const game *myGame;
    int oldPreset;

    BOOL canConfigure;
    int configItemCount;
    config_item *configItems;
    NSString *configSectionTitle;
    NSDictionary *configCache;
}

@property (nonatomic, retain) NSString *configSectionTitle;

+ (NSArray*)splitChoices:(const char *)choices;

- (id)initWithFrontEnd:(PuzzlesFrontEnd*)aPuzzlesFrontEnd midend:(midend*)aMidend game:(const game*)aGame;

- (void)reapplyConfigItems:(BOOL)reload;

@end
