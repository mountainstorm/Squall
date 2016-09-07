//
//  MtConfigViewController.m
//  squall
//
//  Created by Cooper on 16/08/2012.
//  Copyright (c) 2012 mountainstorm. All rights reserved.
//

#import "MtConfigViewController.h"
#import "../NSView+HierarchicalDescription.h"


@implementation MtConfigViewController

@synthesize delegate = _delegate;
@synthesize view = _view;


- (id)initWithFrame:(NSRect)frame
{
    _view = [[NSView alloc] initWithFrame:frame];
    [_view setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    MtConfigView* view = [MtConfigView configView];
    view.controller = self;
    [view setFrame:_view.frame];
    [_view addSubview:view];
    return self;
}

- (NSData*)archiveLayout
{
    // out root view can only have a single child
    return [self archiveLayoutForView:_view.subviews.firstObject];
}

- (void)unarchiveLayout:(NSData*)layout
{
    [_view.subviews.firstObject removeFromSuperview];
    [self unarchiveLayout:layout intoView:_view];
    
//    NSView* top = _view;
//    while ([top superview] != nil) {
//        top = [top superview];
//    }
//    NSLog(@"%@", [top hierarchicalDescriptionOfView]);
}

- (NSData*)archiveLayoutForView:(NSView*)view
{
    NSMutableData* retval = [NSMutableData data];
    NSKeyedArchiver* aCoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:retval];
    
    [aCoder encodeRect:[view frame]];
    [aCoder encodeBool:[view isKindOfClass:[NSSplitView class]]
                forKey:@"isSplitView"];
    
    if ([view isKindOfClass:[NSSplitView class]]) {
        // archive a splitview
        NSSplitView* split = (NSSplitView*)view;
        NSView* first = split.subviews.firstObject;
        NSView* second = split.subviews.lastObject;
        
        [aCoder encodeBool:[split isVertical] forKey:@"isVertical"];
        [aCoder encodeDataObject:[self archiveLayoutForView:first]];
        [aCoder encodeDataObject:[self archiveLayoutForView:second]];
        
    } else {
        // archive content of a pane
        [aCoder encodeDataObject:[_delegate archiveConfigOfView:(MtConfigView*)view]];
    }
    [aCoder finishEncoding];
    return retval;
}

- (NSRect)unarchiveLayout:(NSData*)layout intoView:(NSView*)parent
{
    NSKeyedUnarchiver* aDecoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:layout];
    
    NSRect frame = [aDecoder decodeRect];
    if ([aDecoder decodeBoolForKey:@"isSplitView"]) {
        // unarchive a splitview
        NSSplitView* split = [[NSSplitView alloc] initWithFrame:parent.frame];
        [split setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [split setDividerStyle:NSSplitViewDividerStyleThin];
        
        [split setVertical:[aDecoder decodeBoolForKey:@"isVertical"]];
        // interesting quirk - when adding the split view resizes the children
        // after we have added them reset the sizes
        NSRect f1 = [self unarchiveLayout:[aDecoder decodeDataObject] intoView:split];
        NSRect f2 = [self unarchiveLayout:[aDecoder decodeDataObject] intoView:split];
        if (split.vertical) {
            f1.size.width = parent.frame.size.width;
            f2.size.width = parent.frame.size.width;
        } else {
            f1.size.height = parent.frame.size.height;
            f2.size.height = parent.frame.size.height;
        }
        [split.subviews.firstObject setFrame:f1];
        [split.subviews.lastObject setFrame:f2];
        [parent addSubview:split];
        
    } else {
        // unarchive a MtConfigView
        MtConfigView* view = [MtConfigView configView];
        view.controller = self;
        [view setFrame:parent.frame];
        [parent addSubview:view];
        if ([parent isKindOfClass:[NSSplitView class]]) {
            // there is more than one of us
            [view.removeMenuItem setEnabled:YES];
        }
        [_delegate unarchiveConfig:[aDecoder decodeDataObject] intoView:view];
    }
    [aDecoder finishDecoding];
    return frame;
}

// NSMenuDelegate
- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu
{
    return [_delegate numberOfItemsInMenu:menu];
}

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
    return [_delegate menu:menu updateItem:item atIndex:index shouldCancel:shouldCancel];
}

- (void)createItem:(NSMenuItem*)item inView:(MtConfigView*)view
{
    [_delegate createItem:item inView:view];
}

- (void)removingView:(MtConfigView*)view
{
    [_delegate removingView:view];
}

@end
