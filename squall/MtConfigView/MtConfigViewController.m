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

- (NSDictionary*)archiveLayout
{
    // out root view can only have a single child
    return [self archiveLayoutForView:_view.subviews.firstObject];
}

- (void)unarchiveLayout:(NSDictionary*)layout
{
    [_view.subviews.firstObject removeFromSuperview];
    [self unarchiveLayout:layout intoView:_view];
}

- (NSDictionary*)archiveLayoutForView:(NSView*)view
{
    NSDictionary* retval = nil;
    
    //[aCoder encodeRect:[view frame]];
    if ([view isKindOfClass:[NSSplitView class]]) {
        NSMutableDictionary* layout = [NSMutableDictionary dictionary];
        // archive a splitview
        NSSplitView* split = (NSSplitView*)view;
        NSView* first = split.subviews.firstObject;
        NSView* second = split.subviews.lastObject;
        
        [layout setObject:[self archiveLayoutForView:first] forKey:@"first"];
        [layout setObject:[self archiveLayoutForView:second]forKey:@"second"];
        
        // annoyingly there is no method to get the divider position - so we have to calculate it
        CGFloat ratio = 0.5;
        if (split.vertical) {
            [layout setObject:@"|" forKey:@"split"];
            ratio = first.frame.size.width / (split.frame.size.width - split.dividerThickness);
        } else {
            [layout setObject:@"-" forKey:@"split"];
            ratio = first.frame.size.height / (split.frame.size.height - split.dividerThickness);
        }
        [layout setObject:[NSNumber numberWithFloat:ratio] forKey:@"ratio"];
        retval = layout;
        
    } else {
        // archive content of a pane
        retval = [_delegate archiveConfigOfView:(MtConfigView*)view];
    }
    return retval;
}

- (void)unarchiveLayout:(NSDictionary*)layout intoView:(NSView*)parent
{
    NSString* dir = [layout objectForKey:@"split"];
    if (dir != nil) {
        // unarchive a splitview
        NSSplitView* split = [[NSSplitView alloc] initWithFrame:parent.frame];
        [split setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [split setDividerStyle:NSSplitViewDividerStyleThin];
        
        [split setVertical:[dir isEqualToString:@"|"]];
        // interesting quirk - when adding the split view resizes the children
        // after we have added them reset the sizes
        [self unarchiveLayout:layout[@"first"]  intoView:split];
        [self unarchiveLayout:layout[@"second"] intoView:split];
        CGFloat loc = 0.5;
        CGFloat ratio = [layout[@"ratio"] floatValue];
        if ([dir isEqualToString:@"|"]) {
            loc = (split.frame.size.width - split.dividerThickness) * ratio;
        } else {
            loc = (split.frame.size.height - split.dividerThickness) * ratio;
        }
        [split setPosition:loc ofDividerAtIndex:0];
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
        [_delegate unarchiveConfig:layout intoView:view];
    }
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
