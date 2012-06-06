#import <QuartzCore/QuartzCore.h>

#import "HelpViewController.h"

static CGFloat elastic_lower_limit(CGFloat limit, CGFloat x) {
    if (x >= limit) {
        return x;
    }
    else {
        CGFloat diff = limit-x;
        return limit - (0.5f * diff);
    }
}

@interface HelpViewController () <UIWebViewDelegate, UIGestureRecognizerDelegate> {
    NSString *_helpTopic;
    UIGestureRecognizer *_dismissGestureRecognizer;
    CGPoint _panningBeginCenter;
    CALayer *_gradientLayer;
    id<HelpViewControllerDelegate> _delegate;
}

@property (nonatomic, retain) NSString *helpTopic;

- (void) dismiss;
- (void)updatePanGesture:(UIGestureRecognizer*)gestureRecgonizer;

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

- (void)updatePanGesture:(UIGestureRecognizer *)gestureRecgonizer {
    if (gestureRecgonizer == _dismissGestureRecognizer) {
        UIPanGestureRecognizer *gr = (UIPanGestureRecognizer*) _dismissGestureRecognizer;
        switch (_dismissGestureRecognizer.state) {
            case UIGestureRecognizerStateBegan:
                _panningBeginCenter = self.view.center;
                break;

            case UIGestureRecognizerStateEnded: {
                CGFloat totalDragged = [gr translationInView:self.view].x;
                if (totalDragged > 0.33 * self.view.frame.size.width) {
                    // dismiss
                    [self dismiss];
                } else {
                    // restore
                    [UIView animateWithDuration:0.2f animations:^{
                        self.view.center = _panningBeginCenter;
                    }];
                }
                break;
            }

            case UIGestureRecognizerStateChanged: {
                CGPoint p = [gr translationInView:self.view];
                self.view.center = CGPointMake(elastic_lower_limit(_panningBeginCenter.x, _panningBeginCenter.x + p.x),
                                               _panningBeginCenter.y);
                break;
            }
            default:
                break;
        }
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIPanGestureRecognizer *dismissGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(updatePanGesture:)];
        dismissGestureRecognizer.delegate = self;
        _dismissGestureRecognizer = dismissGestureRecognizer;

        CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
        gradientLayer.frame = CGRectMake(-17, 0, 17, self.view.bounds.size.height);
        gradientLayer.colors = [NSArray arrayWithObjects:
                                (id)[UIColor colorWithRed:0.6f green:0.6f blue:0.6f alpha:1.0f].CGColor,
                                (id)[UIColor clearColor].CGColor,
                                nil];
        gradientLayer.startPoint = CGPointMake(1.0, 0.5);
        gradientLayer.endPoint = CGPointMake(0.0, 0.5);

        [self.view.layer addSublayer:gradientLayer];
        _gradientLayer = gradientLayer;

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
    return NO;
}

- (void)viewWillLayoutSubviews {
    // to avoid overriding UIView
    CGRect r = _gradientLayer.frame;
    r.size.height = self.view.bounds.size.height;
    _gradientLayer.frame = r;
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
