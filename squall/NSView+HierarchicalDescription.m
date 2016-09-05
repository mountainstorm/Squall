//
//  NSView+HierarchicalDescription.m
//  squall
//
//  Created by Richard Cooper on 17/08/2012.
//  Copyright (c) 2012 mountainstorm. All rights reserved.
//

#import "NSView+HierarchicalDescription.h"

@implementation NSView (HierarchicalDescription)

- (NSString*)hierarchicalDescriptionOfView
{
	return [NSView hierarchicalDescriptionOfView:self level:0];
}

+ (NSString*)hierarchicalDescriptionOfView:(NSView*)view 
									 level:(NSUInteger)level
{
	
	// Ready the description string for this level
	NSMutableString* builtHierarchicalString = [NSMutableString string];
	
	// Build the tab string for the current level's indentation
	NSMutableString* tabString = [NSMutableString string];
	for (NSUInteger i = 0; i <= level; i++) {
		[tabString appendString:@"\t"];
	}
	
	// Get the view's title string if it has one
	NSString* titleString = ([view respondsToSelector:@selector(title)]) ? [NSString stringWithFormat:@"%@", [NSString stringWithFormat:@"\"%@\" ", [(NSButton*)view title]]] : @"";
	
	// Append our own description at this level
	NSRect rect = [view frame];
	[builtHierarchicalString appendFormat:@"\n%@<%@: %p> %@ {{%.0f, %.0f},{%.0f, %.0f}} (%li subviews)", tabString, [view className], view, titleString, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, [[view subviews] count]];  
	
	// Recurse for each subview ...
	for (NSView* subview in [view subviews]) {
		[builtHierarchicalString appendString:[NSView hierarchicalDescriptionOfView:subview 
																			  level:(level + 1)]];
	}	
	return builtHierarchicalString;
}

@end
