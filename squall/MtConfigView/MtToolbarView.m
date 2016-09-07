//
//  MtToolbarView.m
//  squall
//
//  Created by Cooper on 20/08/2012.
//  Copyright (c) 2012 mountainstorm. All rights reserved.
//

#import "MtToolbarView.h"

@implementation MtToolbarView

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
//		NSColor* fillStop1 = [NSColor colorWithCalibratedWhite:(239.0f / 255.0f) alpha:1];
//		NSColor* fillStop2 = [NSColor colorWithCalibratedWhite:(238.0f / 255.0f) alpha:1];
//		NSColor* fillStop3 = [NSColor colorWithCalibratedWhite:(244.0f / 255.0f) alpha:1];
//		NSColor* fillStop4 = [NSColor colorWithCalibratedWhite:(250.0f / 255.0f) alpha:1];
//		self->_fillGradient = [[NSGradient alloc] initWithColorsAndLocations:fillStop1, (CGFloat)0.0,
//																			 fillStop2, (CGFloat)0.45454,
//																			 fillStop3, (CGFloat)0.45454,
//																			 fillStop4, (CGFloat)1.0,
//																			 nil];
		self->_borderColor = [NSColor colorWithCalibratedWhite:(165.0f / 255.0f) alpha:1];
        self->_backgroundColor = [NSColor colorWithCalibratedWhite:(239.0f / 255.0f) alpha:1];
	}
	return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
	[super drawRect:dirtyRect];
	
	NSRect rect = NSInsetRect([self bounds], 0, 1);
	rect.size.height += 1.0; // TODO: make this automatic for whichever edge is against the parents
    [self->_backgroundColor set];
    NSRectFill(rect);
}

@end
