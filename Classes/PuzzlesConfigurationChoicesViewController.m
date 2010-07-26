#import "PuzzlesConfigurationChoicesViewController.h"
#import "PuzzlesConfigurationDelegate.h"

@implementation PuzzlesConfigurationChoicesViewController

@synthesize delegate;

- (id)initWithConfigItem:(config_item*)aConfigItem choicesCache:(NSArray*)theChoices {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        configItem = aConfigItem;
        choices = [theChoices retain];
        self.navigationItem.title = [NSString stringWithCString:configItem->name encoding:NSASCIIStringEncoding];
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    else {
        return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

	// Release any cached data, images, etc that aren't in use.
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [choices count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    cell.textLabel.text = [choices objectAtIndex:indexPath.row];
    cell.accessoryType = indexPath.row == configItem->ival ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int oldSelection = configItem->ival;
    int newSelection = indexPath.row;
    if (oldSelection != newSelection) {
        UITableViewCell *oldSelectionCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:oldSelection inSection:0]];
        oldSelectionCell.accessoryType = UITableViewCellAccessoryNone;

        UITableViewCell *newSelectionCell = [tableView cellForRowAtIndexPath:indexPath];
        newSelectionCell.accessoryType = UITableViewCellAccessoryCheckmark;

        configItem->ival = newSelection;
        [delegate gameConfigItemChanged:configItem];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)dealloc {
    [choices release];
    choices = nil;
    [super dealloc];
}


@end

