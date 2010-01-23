#import "PuzzlesConfigurationViewController.h"

#import "PuzzlesParametersDelegate.h"
#import "PuzzlesConfigurationChoicesViewController.h"

#include "puzzles.h"

static const int kPuzzlesConfigurationViewControllerPresetsSection = 0;
static const int kPuzzlesConfigurationViewControllerCustomConfigSection = 1;


@implementation PuzzlesConfigurationViewController

@synthesize configSectionTitle;

- (id)initWithDelegate:(id<PuzzlesParametersDelegate>)paramDelegate midend:(midend*)aMidend game:(const game*)aGame {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        delegate = paramDelegate;
        myMidend = aMidend;
        myGame = aGame;
        oldPreset = midend_which_preset(myMidend);
        isCustom = oldPreset == -1;

        canConfigure = myGame->can_configure;
        if (canConfigure) {
            char *wintitle;
            configItems = midend_get_config(myMidend, CFG_SETTINGS, &wintitle);
            self.configSectionTitle = [NSString stringWithCString:wintitle encoding:NSASCIIStringEncoding];
            sfree(wintitle);

            NSMutableDictionary *mutableCache = [NSMutableDictionary dictionary];
            NSMutableDictionary *mutableTextFields = [NSMutableDictionary dictionary];
            config_item *ci = configItems;
            while (ci->type != C_END) {
                switch (ci->type) {
                    case C_CHOICES: {
                        [mutableCache setObject:[[self class] splitChoices:ci->sval]
                                         forKey:[NSNumber numberWithInt:configItemCount]];
                        break;
                    }
                    case C_STRING: {
                        UITextField *tf = [[UITextField alloc] initWithFrame:CGRectZero];
                        tf.delegate = self;
                        [mutableTextFields setObject:tf
                                              forKey:[NSNumber numberWithInt:configItemCount]];
                        break;
                    }
                }

                configItemCount++;
                ci++;
            }
            persistentTextFields = [mutableTextFields retain];
            configCache = [mutableCache retain];
        }
    }
    return self;
}

+(NSArray*)splitChoices:(const char*)choices {
    NSString *choicesString = [NSString stringWithCString:choices encoding:NSASCIIStringEncoding];
    NSString *seperator = [choicesString substringToIndex:1];
    return [[choicesString substringFromIndex:1] componentsSeparatedByString:seperator];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"Configure";
}


- (void)reapplyConfigItems:(BOOL)reload {
    if (!canConfigure) {
        return;
    }

    if (reload) {
        char *wintitle;
        free_cfg(configItems);
        configItems = midend_get_config(myMidend, CFG_SETTINGS, &wintitle);
        sfree(wintitle);
    }

    config_item *item = configItems;
    int row = 0;
    while (item->type != C_END) {
        UITableViewCell *cell =
        	[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row
                                                                     inSection:kPuzzlesConfigurationViewControllerCustomConfigSection]];

        switch (item->type) {
            case C_BOOLEAN: {
                UISwitch *sw = (UISwitch*)cell.accessoryView;
                sw.on = item->ival;
                break;
            }
            case C_CHOICES: {
                NSArray *choices = [configCache objectForKey:[NSNumber numberWithInt:row]];
                cell.detailTextLabel.text = [choices objectAtIndex:item->ival];
                break;
            }
            case C_STRING: {
                UITextField *tf = (UITextField*)cell.accessoryView;
                tf.text = [NSString stringWithCString:item->sval encoding:NSASCIIStringEncoding];
                break;
            }
        }

        [cell setNeedsLayout];
        item++;
        row++;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reapplyConfigItems:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (isCustom) {
        [self writeTextFieldConfigItems];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

	// Release any cached data, images, etc that aren't in use.
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (canConfigure && isCustom) {
        return 2;
    }
    else {
        return 1;
    }
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kPuzzlesConfigurationViewControllerPresetsSection) {
        return midend_num_presets(myMidend) + (canConfigure ? 1 : 0);
    }
    else if (section == kPuzzlesConfigurationViewControllerCustomConfigSection) {
        return configItemCount;
    }
    else {
        return 0;
    }
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    if (indexPath.section == kPuzzlesConfigurationViewControllerPresetsSection) {
        static NSString *CellIdentifier = @"PresetCell";

        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }

        if (midend_num_presets(myMidend) == indexPath.row) {
            cell.textLabel.text = @"Custom";
            cell.accessoryType = isCustom ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        else {
            char *name;
            game_params *params;
            midend_fetch_preset(myMidend, indexPath.row, &name, &params);
            cell.textLabel.text = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
            cell.accessoryType = indexPath.row == oldPreset ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }

    }
    else if (indexPath.section == kPuzzlesConfigurationViewControllerCustomConfigSection) {
        config_item *item = &configItems[indexPath.row];
        if (item->type == C_STRING) {
            static NSString *CellIdentifier = @"ConfigCell_String";

            UITextField *tf = [persistentTextFields objectForKey:[NSNumber numberWithInt:indexPath.row]];

            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                cell.selectionStyle = UITableViewCellSeparatorStyleNone;

                CGFloat width = cell.contentView.bounds.size.width;
                CGFloat height = cell.contentView.bounds.size.height;
                tf.frame = CGRectMake(0, 0, width / 3, height / 2);
            }

            cell.accessoryView = tf;
            tf.text = [NSString stringWithCString:item->sval encoding:NSASCIIStringEncoding];
        }
        else if (item->type == C_BOOLEAN) {
            static NSString *CellIdentifier = @"ConfigCell_Boolean";

            UISwitch *sw;

            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                cell.selectionStyle = UITableViewCellSeparatorStyleNone;

                sw = [[UISwitch alloc] initWithFrame:CGRectZero];
                [sw addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = sw;
                [sw release];
            }
            else {
                sw = (UISwitch*)cell.accessoryView;
            }

            sw.on = item->ival;
        }
        else if (item->type == C_CHOICES) {
            static NSString *CellIdentifier = @"ConfigCell_Choices";

            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }

            NSArray *choices = [configCache objectForKey:[NSNumber numberWithInt:indexPath.row]];
            cell.detailTextLabel.text = [choices objectAtIndex:item->ival];
        }

        cell.textLabel.text = [NSString stringWithCString:item->name encoding:NSASCIIStringEncoding];

    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == kPuzzlesConfigurationViewControllerPresetsSection) {
        return @"Presets";
    }
    else if (section == kPuzzlesConfigurationViewControllerCustomConfigSection) {
        return configSectionTitle;
    }
    else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kPuzzlesConfigurationViewControllerPresetsSection) {
        BOOL presetDidChange = NO;
        int newPreset = -1;

        if (indexPath.row == midend_num_presets(myMidend)) {
            if (!isCustom) {
                presetDidChange = YES;
                isCustom = YES;

                [tableView insertSections:[NSIndexSet indexSetWithIndex:kPuzzlesConfigurationViewControllerCustomConfigSection]
                         withRowAnimation:UITableViewRowAnimationTop];

                [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kPuzzlesConfigurationViewControllerCustomConfigSection]
                                 atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        }
        else {
            if (isCustom) {
                isCustom = NO;
                [tableView deleteSections:[NSIndexSet indexSetWithIndex:kPuzzlesConfigurationViewControllerCustomConfigSection]
                         withRowAnimation:UITableViewRowAnimationTop];

                UITableViewCell *customCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:midend_num_presets(myMidend)
                                                                                                  inSection:kPuzzlesConfigurationViewControllerPresetsSection]];
                customCell.accessoryType = UITableViewCellAccessoryNone;
            }

            newPreset = indexPath.row;
            if (newPreset != oldPreset) {
                presetDidChange = YES;
                char *name;
                game_params *params;
                midend_fetch_preset(myMidend, newPreset, &name, &params);
                midend_set_params(myMidend, params);

                [self reapplyConfigItems:YES];
                [delegate gameParametersChanged];
            }
        }

        if (presetDidChange && oldPreset >= 0) {
            UITableViewCell *oldPresetCell =
            	[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:oldPreset
                                                                    inSection:kPuzzlesConfigurationViewControllerPresetsSection]];
            oldPresetCell.accessoryType = UITableViewCellAccessoryNone;
        }
        oldPreset = newPreset;

        UITableViewCell *newPresetCell = [tableView cellForRowAtIndexPath:indexPath];
        newPresetCell.accessoryType = UITableViewCellAccessoryCheckmark;

        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if (indexPath.section == kPuzzlesConfigurationViewControllerCustomConfigSection) {
        config_item *item = &configItems[indexPath.row];
        NSArray *choicesCache = [configCache objectForKey:[NSNumber numberWithInt:indexPath.row]];
        if (item->type == C_CHOICES) {
            PuzzlesConfigurationChoicesViewController *vc =  [[PuzzlesConfigurationChoicesViewController alloc] initWithConfigItem:item choicesCache:choicesCache];
            vc.delegate = self;
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField*)textField {
    // TODO: would be nicer to only select tf's items
    [self writeTextFieldConfigItems];
}

- (void)gameConfigItemChanged:(config_item *)item {
    char *error = midend_set_config(myMidend, CFG_SETTINGS, configItems);
    if (error) {
        NSLog(@"Error setting game parameters: %s", error);
    }
    [delegate gameParametersChanged];
}

- (void)switchValueChanged:(id)sender {
    UISwitch *sw = sender;

    config_item *item = configItems;
    int row = 0;
    while (item->type != C_END) {
        if (item->type == C_BOOLEAN) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row
                                                                                             inSection:kPuzzlesConfigurationViewControllerCustomConfigSection]];
            if (cell.accessoryView == sw) {
                item->ival = sw.on;
                [self gameConfigItemChanged:item];
                break;
            }
        }

        item++;
        row++;
    }
}

- (void)writeTextFieldConfigItems {
    config_item *item = configItems;
    int row = 0;
    BOOL didChange = NO;
    while (item->type != C_END) {
        if (item->type == C_STRING) {
            UITextField *tf = [persistentTextFields objectForKey:[NSNumber numberWithInt:row]];
            const char *newValue = [tf.text cStringUsingEncoding:NSASCIIStringEncoding];
            if (newValue && strcmp(newValue, item->sval)) {
                free(item->sval);
                item->sval = strdup([tf.text cStringUsingEncoding:NSASCIIStringEncoding]);
                didChange = YES;
            }
        }

        item++;
        row++;
    }

    if (didChange) {
        char *error = midend_set_config(myMidend, CFG_SETTINGS, configItems);
        if (error) {
            NSLog(@"Error setting game parameters: %s", error);
        }
        [delegate gameParametersChanged];
    }
}

- (void)dealloc {
    if (configItems) {
        free_cfg(configItems);
        configItems = NULL;
    }
    [persistentTextFields release];
    persistentTextFields = nil;
    [configCache release];
    configCache = nil;
    [super dealloc];
}


@end

