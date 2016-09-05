//
//  NSView+HierarchicalDescription.h
//  squall
//
//  Created by Richard Cooper on 17/08/2012.
//  Copyright (c) 2012 mountainstorm. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSView (HierarchicalDescription)

- (NSString*)hierarchicalDescriptionOfView;

// private
+ (NSString*)hierarchicalDescriptionOfView:(NSView*)view 
									 level:(NSUInteger)level;

@end
