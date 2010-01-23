#include "puzzles.h"

@protocol PuzzlesConfigurationDelegate

- (void)gameConfigItemChanged:(config_item*)item;

@end
