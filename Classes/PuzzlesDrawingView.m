#import <CoreGraphics/CoreGraphics.h>
#import "PuzzlesDrawingView.h"
#import "PuzzlesFrontEnd.h"

#include "puzzles.h"

#pragma mark -
#pragma mark Bitmap Context

static CGContextRef create_bitmap_context(int w, int h) {
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(w,h), YES, 0.0);
    context = UIGraphicsGetCurrentContext();
    CGContextRetain(context);
    UIGraphicsEndImageContext();

    CGContextTranslateCTM(context, 0, h);
    CGContextScaleCTM(context, 1.0, -1.0);

    CGColorSpaceRelease(colorSpace);
    return context;
}

void destroy_bitmap_context(CGContextRef context) {
    CGContextRelease(context);
}

#pragma mark -
#pragma mark Drawing API Methods

static inline PuzzlesDrawingView *drawingView_from_handle(void *handle) {
    PuzzlesDrawingView *view = ((frontend*)handle)->drawingView;
    return view;
}

static void iphone_dr_draw_text(void *handle, int x, int y, int fonttype, int fontsize,
                                int align, int color, char *text)
{
    PuzzlesDrawingView *view = drawingView_from_handle(handle);
    NSArray *colours = view.colours;
    CGContextRef c = view.backingContext;

    const char *fontname = fonttype == FONT_FIXED ? "Monaco" : "Helvetica";
    UIFont *font = [UIFont fontWithName:[NSString stringWithCString:fontname encoding:NSASCIIStringEncoding] size:fontsize];

    CGContextSetAllowsAntialiasing(c, YES);
    CGColorRef textColor = [[colours objectAtIndex:color] CGColor];
    CGContextSetStrokeColorWithColor(c, textColor);
    CGContextSetFillColorWithColor(c, textColor);
    CGContextSetTextMatrix(c, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0));

    CGContextSelectFont(c, fontname, fontsize, kCGEncodingMacRoman);

    CGContextSetTextDrawingMode(c, kCGTextInvisible);
    CGContextShowTextAtPoint(c, 0, 0, text, strlen(text));

    CGPoint p = CGContextGetTextPosition(c);
    int textWidth = p.x, textHeight = font.capHeight;

    if (align & ALIGN_HRIGHT) {
        x -= textWidth;
    }
    else if (align & ALIGN_HCENTRE) {
        x -= textWidth / 2;
    }

    if (align & ALIGN_VCENTRE) {
        y += textHeight / 2;
    }
    else {
        y += textHeight;
    }

    CGContextSetTextDrawingMode(c, kCGTextFillStroke);
    CGContextShowTextAtPoint(c, x, y, text, strlen(text));
}

static void iphone_dr_draw_rect(void *handle, int x, int y, int w, int h, int colour)
{
    PuzzlesDrawingView *view = ((frontend*)handle)->drawingView;
    NSArray *colours = view.colours;
    CGContextRef c = view.backingContext;

    CGContextSetAllowsAntialiasing(c, YES);
    CGContextSetFillColorWithColor(c, [[colours objectAtIndex:colour] CGColor]);
    CGContextFillRect(c, CGRectMake(x, y, w, h));

}

static void iphone_dr_draw_line(void *handle, int x1, int y1, int x2, int y2,
                                int colour)
{
    PuzzlesDrawingView *view = ((frontend*)handle)->drawingView;
    NSArray *colours = view.colours;
    CGContextRef c = view.backingContext;
    CGContextSetLineCap(c, kCGLineCapSquare);

    CGContextSetAllowsAntialiasing(c, YES);
    CGContextSetStrokeColorWithColor(c, [[colours objectAtIndex:colour] CGColor]);
    CGContextBeginPath(c);
    CGContextMoveToPoint(c, x1 + 0.5f, y1 + 0.5f);
    CGContextAddLineToPoint(c, x2 + 0.5f, y2 + 0.5f);

    CGContextStrokePath(c);
}

static void iphone_dr_draw_polygon(void *handle, int *coords, int npoints,
                                   int fillcolour, int outlinecolour)
{
    PuzzlesDrawingView *view = ((frontend*)handle)->drawingView;
    NSArray *colours = view.colours;
    CGContextRef c = view.backingContext;

    CGContextSetAllowsAntialiasing(c, YES);
    CGContextSetLineCap(c, kCGLineCapSquare);

    CGContextBeginPath(c);
    CGContextMoveToPoint(c, coords[0] + 0.5f, coords[1] + 0.5f);
    for (int p = 1; p < npoints; p++) {
        int x = coords[2*p];
        int y = coords[2*p+1];
        CGContextAddLineToPoint(c, x + 0.5f, y + 0.5f);
    }
    CGContextClosePath(c);

    if (outlinecolour != -1)
        CGContextSetStrokeColorWithColor(c, [[colours objectAtIndex:outlinecolour] CGColor]);
    if (fillcolour != -1)
        CGContextSetFillColorWithColor(c, [[colours objectAtIndex:fillcolour] CGColor]);

    CGPathDrawingMode drawingMode;

    if (fillcolour != -1 && outlinecolour != -1) {
        drawingMode = kCGPathFillStroke;
    }
    else if (fillcolour != -1) {
        drawingMode = kCGPathFill;
    }
    else if (outlinecolour != -1) {
        drawingMode = kCGPathStroke;
    }
    else {
        return;
    }
    CGContextDrawPath(c, drawingMode);
}

static void iphone_dr_draw_circle(void *handle, int cx, int cy, int radius,
                                  int fillcolour, int outlinecolour)
{
    PuzzlesDrawingView *view = ((frontend*)handle)->drawingView;
    NSArray *colours = view.colours;
    CGContextRef c = view.backingContext;

    CGContextSetAllowsAntialiasing(c, YES);
    CGContextSetStrokeColorWithColor(c, [[colours objectAtIndex:outlinecolour] CGColor]);

    CGContextAddEllipseInRect(c, CGRectMake(cx-radius+1, cy-radius+1, radius*2-1, radius*2-1));

    if (fillcolour != -1) {
        CGContextSetFillColorWithColor(c, [[colours objectAtIndex:fillcolour] CGColor]);
        CGContextDrawPath(c, kCGPathFillStroke);
    }
    else {
        CGContextStrokePath(c);
    }
}

static void iphone_dr_draw_update(void *handle, int x, int y, int w, int h)
{
    PuzzlesDrawingView *view = drawingView_from_handle(handle);
    CGPoint offset = [view locationInViewToGamePoint:CGPointZero];
    [view setNeedsDisplayInRect:CGRectOffset(CGRectMake(x, y, w, h),
                                             -offset.x, -offset.y)];
}

static void iphone_dr_clip(void *handle, int x, int y, int w, int h)
{
    PuzzlesDrawingView *view = drawingView_from_handle(handle);
    CGContextRef c = view.backingContext;

    if (view.clipped) {
        CGContextRestoreGState(c);
    }
    else {
        view.clipped = YES;
    }

    CGContextSaveGState(c);
    CGContextClipToRect(view.backingContext, CGRectMake(x, y, w, h));
}

static void iphone_dr_unclip(void *handle)
{
    PuzzlesDrawingView *view = drawingView_from_handle(handle);

    if (view.clipped) {
        CGContextRestoreGState(view.backingContext);
        view.clipped = NO;
    }
}

static void iphone_dr_start_draw(void *handle)
{
}

static void iphone_dr_end_draw(void *handle)
{
}

static void iphone_dr_status_bar(void *handle, char *text)
{
    PuzzlesFrontEnd *fe = ((frontend*)handle)->object;
    [fe setStatusText:[NSString stringWithCString:text encoding:NSASCIIStringEncoding]];
}

struct blitter {
    CGRect rect;
    CGImageRef image;
};

static blitter *iphone_dr_blitter_new(void *handle, int w, int h)
{
    struct blitter *bl = malloc(sizeof(blitter));
    bzero(bl, sizeof(*bl));
    bl->rect.size = CGSizeMake(w, h);

    return bl;

}
static void iphone_dr_blitter_free(void *handle, blitter *bl)
{
    if (bl->image) {
        CGImageRelease(bl->image);
    }
    free(bl);
}

static void iphone_dr_blitter_save(void *handle, blitter *bl, int x, int y)
{
    PuzzlesDrawingView *view = drawingView_from_handle(handle);
    if (bl->image) {
        CGImageRelease(bl->image);
    }
    bl->rect.origin = CGPointMake(x, y);

    CGImageRef image = CGBitmapContextCreateImage(view.backingContext);
    CGRect transformed = bl->rect;
    const CGFloat uiscale = view.contentScaleFactor;
    transformed = CGRectApplyAffineTransform(transformed, CGAffineTransformMakeScale(uiscale, uiscale));
    transformed.origin.y = CGImageGetHeight(image) - transformed.origin.y - transformed.size.height;
    bl->image = CGImageCreateWithImageInRect(image, transformed);
    CGImageRelease(image);
}
static void iphone_dr_blitter_load(void *handle, blitter *bl, int x, int y)
{
    PuzzlesDrawingView *view = drawingView_from_handle(handle);
    CGContextRef c = view.backingContext;
    CGRect targetRect = bl->rect;
    if (x != BLITTER_FROMSAVED || y != BLITTER_FROMSAVED) {
        targetRect.origin.x = x;
        targetRect.origin.y = y;
    }
    CGContextDrawImage(c, targetRect, bl->image);
}
static void iphone_dr_line_width(void *handle, float width)
{
    PuzzlesDrawingView *view = drawingView_from_handle(handle);
    CGContextRef c = view.backingContext;
    CGContextSetLineWidth(c, width);
}

static void iphone_dr_line_dotted(void *handle, int dotted)
{
    PuzzlesDrawingView *view = drawingView_from_handle(handle);
    CGContextRef c = view.backingContext;

    NSLog(@"UNIMPLEMENTED iphone_dr_line_dotted");
}

#pragma mark -
@implementation PuzzlesDrawingView

@synthesize backingContext;
@synthesize clipped;
@synthesize midend = myMidend;

- (void)setMidend:(midend *)aMidend {
    myMidend = aMidend;
}

- (NSArray*)colours {
    if (!colours) {
        NSMutableArray *mutableColors = [NSMutableArray array];
        int ncolours;
        float *values = midend_colours(myMidend, &ncolours);
        float *current = values;

        for (int colour = 0; colour < ncolours; colour++) {
            [mutableColors addObject:[UIColor colorWithRed:current[0] green:current[1] blue:current[2] alpha:1.0f]];
            current += 3;
        }
        colours = [mutableColors retain];
        sfree(values);
    }
    return colours;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef c = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(c, [[colours objectAtIndex:0] CGColor]);
    CGContextFillRect(c, rect);

    CGImageRef image = CGBitmapContextCreateImage(backingContext);
    CGContextDrawImage(c, puzzleSubframe, image);
    CGImageRelease(image);
}

- (CGPoint)locationInViewToGamePoint:(CGPoint)p {
    return CGPointMake(p.x - puzzleSubframe.origin.x,
                       p.y - puzzleSubframe.origin.y);
}

- (void)layoutSubviews {
    if (backingContext) {
        destroy_bitmap_context(backingContext);
        backingContext = NULL;
    }
    if (myMidend) {
        puzzleSubframe.size = self.bounds.size;
        {
            int maxX = puzzleSubframe.size.width;
            int maxY = puzzleSubframe.size.height;
            midend_size(myMidend, &maxX, &maxY, true);
            puzzleSubframe.size = CGSizeMake(maxX, maxY);
        }
        puzzleSubframe.origin.x = floor((self.bounds.size.width - puzzleSubframe.size.width) / 2);
        puzzleSubframe.origin.y = floor((self.bounds.size.height - puzzleSubframe.size.height) / 2);

        backingContext = create_bitmap_context(puzzleSubframe.size.width, puzzleSubframe.size.height);
        [self setNeedsDisplay];
        midend_redraw(myMidend);
    }
}

- (void)dealloc {
    [colours release];
    colours = nil;
    if (backingContext) {
        destroy_bitmap_context(backingContext);
        backingContext = NULL;
    }
    [super dealloc];
}

const static struct drawing_api kPuzzlesDrawingView_drawing_api = {
    iphone_dr_draw_text,
    iphone_dr_draw_rect,
    iphone_dr_draw_line,
    iphone_dr_draw_polygon,
    iphone_dr_draw_circle,
    iphone_dr_draw_update,
    iphone_dr_clip,
    iphone_dr_unclip,
    iphone_dr_start_draw,
    iphone_dr_end_draw,
    iphone_dr_status_bar,
    iphone_dr_blitter_new,
    iphone_dr_blitter_free,
    iphone_dr_blitter_save,
    iphone_dr_blitter_load,
    NULL, // begin_doc
    NULL, // begin_page
    NULL, // begin_puzzle
    NULL, // end_puzzle
    NULL, // end_page
    NULL, // end_doc
    iphone_dr_line_width,
    iphone_dr_line_dotted,
};

+ (const drawing_api*)drawingAPI {
    return &kPuzzlesDrawingView_drawing_api;
}


@end
