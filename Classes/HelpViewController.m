#import "HelpViewController.h"

@interface HelpViewController () <UIWebViewDelegate, UIGestureRecognizerDelegate> {
    NSString *_helpTopic;
    UIGestureRecognizer *_dismissGestureRecognizer;
    id<HelpViewControllerDelegate> _delegate;
}

@property (nonatomic, retain) NSString *helpTopic;

- (void) dismiss;

@end

@implementation HelpViewController

@synthesize delegate = _delegate;
@synthesize helpTopic = _helpTopic;

- (id)initWithHelpTopic:(NSString*)helpTopic {
    if (self = [self initWithNibName:@"HelpViewController" bundle:nil]) {
        self.helpTopic = helpTopic;
    }
    return self;
}

- (void)dismiss {
    [_delegate dismissHelpViewController:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UISwipeGestureRecognizer *dismissGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        dismissGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        dismissGestureRecognizer.numberOfTouchesRequired = 1;
        dismissGestureRecognizer.delegate = self;
        _dismissGestureRecognizer = dismissGestureRecognizer;

        [self.view addGestureRecognizer:_dismissGestureRecognizer];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    UIWebView *wv = (UIWebView*) self.view;
    NSURL *helpURL = [[NSBundle mainBundle] URLForResource:_helpTopic withExtension:@"html"];
    [wv loadRequest:[NSURLRequest requestWithURL:helpURL]];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if ([[UIApplication sharedApplication] openURL:[request URL]]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [_helpTopic release];
    [_dismissGestureRecognizer release];
    [super dealloc];
}

@end
