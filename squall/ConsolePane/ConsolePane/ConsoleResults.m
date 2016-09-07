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
    [[NSColor colorWithCalibratedWhite:(239.0 / 255.0) alpha:1.0] set];
    NSRectFill(self.frame);
    
    [[NSColor whiteColor] set];
    for (NSView* view in self.subviews) {
        NSRect frame = view.frame;
        frame.size.width = max(
            max(
                frame.size.width,
                self.frame.size.width
            ),
            self.superview.frame.size.width
        );
        NSRectFill(frame);
    }
}

- (void)addSubview:(NSView *)view
{
    [super addSubview:view];
    [self resizeSubviewsWithOldSize:NSMakeSize(0, 0)];
}

- (void)resizeSubviewsWithOldSize:(NSSize)sz
{
    // go through subview in order and fix their location and size
    // so the most recent window is at the bottom
    float y = 0;
    for (NSView* view in self.subviews) {
        NSRect frame = view.frame;
        frame.origin.y = y;
        view.frame = frame;
        y += frame.size.height + 1.0; // tiny line between each pane
    }
}

@end
