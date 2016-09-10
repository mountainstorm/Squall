//
//  ConsoleResults.m
//  ConsolePane
//
//  Created by cooper on 07/09/2016.
//  Copyright © 2016 cooper. All rights reserved.
//

#import "ConsoleResults.h"

#define max(a,b) ((a) > (b) ? (a) : (b))

@implementation ConsoleResults

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    // we're going to draw the color of the divider then over draw the result bg color
    [[NSColor colorWithCalibratedWhite:(239.0f / 255.0f) alpha:1.0] set];
    NSRectFill(self.frame);
    
    [[NSColor whiteColor] set];
    for (NSView* view in self.subviews) {
        NSRect frame = view.frame;
        frame.size.width = self.frame.size.width;
        NSRectFill(frame);
    }
}

- (void)addSubview:(NSView *)view
{
    [super addSubview:view];
    // go through subview in order and fix their location and size
    // so the most recent window is at the bottom
    float y = 0;
    float width = 0;
    for (NSView* view in [self.subviews reverseObjectEnumerator]) {
        NSRect frame = view.frame;
        frame.origin.y = y;
        view.frame = frame;
        width = max(width, frame.size.width);
        y += frame.size.height + 1.0; // tiny line between each pane
    }
    _minWidth = width;
    self.frame = NSMakeRect(0, 0, max(width, self.superview.frame.size.width), y);
}

- (void)resizeWithOldSuperviewSize:(NSSize)sz
{
    // dont call super as it will try to resize us
    if (self.superview.frame.size.width > _minWidth) {
        // grow us
        NSRect frame = self.frame;
        frame.size.width = self.superview.frame.size.width;
        [self setFrameSize:frame.size];
        self.needsDisplay = YES;
    } else if (self.superview.frame.size.width < _minWidth) {
        NSRect frame = self.frame;
        frame.size.width = _minWidth;
        [self setFrameSize:frame.size];
        self.needsDisplay = YES;
    }
    // otherwise do nothing - as we'll cause a loop
}

@end
