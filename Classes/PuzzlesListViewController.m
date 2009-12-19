#import "PuzzlesListViewController.h"
#import "PuzzlesFrontEnd.h"

#include "puzzles.h"

@implementation PuzzlesListViewController

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return gamecount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    const game *g = gamelist[indexPath.row];
    cell.textLabel.text = [NSString stringWithCString:g->name encoding:NSASCIIStringEncoding];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    const game *g = gamelist[indexPath.row];
    PuzzlesFrontEnd *frontEnd = [[PuzzlesFrontEnd alloc] initWithGame:g];
    [self.navigationController pushViewController:frontEnd animated:YES];
    [frontEnd release];
}

- (void)dealloc {
    [super dealloc];
}


@end

