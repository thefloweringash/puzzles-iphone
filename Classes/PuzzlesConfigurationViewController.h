#import <UIKit/UIKit.h>

@class PuzzlesFrontEnd;
@protocol PuzzlesParametersDelegate;

#include "puzzles.h"

#import "PuzzlesConfigurationDelegate.h"

@interface PuzzlesConfigurationViewController : UITableViewController<UITextFieldDelegate,PuzzlesConfigurationDelegate> {
    PuzzlesFrontEnd *puzzlesFrontEnd;
    midend *myMidend;
    const game *myGame;
    int oldPreset;

    BOOL canConfigure;
    int configItemCount;
    config_item *configItems;
    NSString *configSectionTitle;
    NSDictionary *configCache;
    NSDictionary *persistentTextFields;

    BOOL isCustom;
    id<PuzzlesParametersDelegate> delegate;
}

@property (nonatomic, retain) NSString *configSectionTitle;

+ (NSArray*)splitChoices:(const char *)choices;

- (id)initWithDelegate:(id<PuzzlesParametersDelegate>)paramDelegate midend:(midend*)aMidend game:(const game*)aGame;

- (void)reapplyConfigItems:(BOOL)reload;
- (void)writeTextFieldConfigItems;

@end
