//
//  MtConfigView.m
//  squall
//
//  Created by cooper on 30/08/2016.
//  Copyright © 2016 mountainstorm. All rights reserved.
//

#import "MtConfigView.h"
#import "MtConfigViewDelegate.h"
#import "../NSView+HierarchicalDescription.h"


typedef enum eMtConfigViewAdd {
    kMtConfigViewAddAbove,
    kMtConfigViewAddRight,
    kMtConfigViewAddBelow,
    kMtConfigViewAddLeft
} MtConfigViewAdd;


@implementation MtConfigView


@synthesize removeMenuItem = _removeMenuItem;
@synthesize content = _content;
@synthesize toolbar = _toolbar;

@synthesize controller = _controller;

+ (id)configView
{
    MtConfigView* view = nil;
    NSArray* top = nil;
    [[NSBundle mainBundle] loadNibNamed:@"MtConfigView" owner:nil topLevelObjects:&top];
    for (id obj in top) {
        if ([obj isKindOfClass:[MtConfigView class]]) {
            view = obj;
        }
    }
    return view;
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    return self;
}

- (void)viewDidMoveToSuperview
{
    [super viewDidMoveToSuperview];
    [self setFrame:[[self superview] frame]];
}


- (IBAction)addViewAbove:(id)sender
{
    [self insertConfigView:kMtConfigViewAddAbove];
}

- (IBAction)addViewRight:(id)sender
{
    [self insertConfigView:kMtConfigViewAddRight];
}

- (IBAction)addViewBelow:(id)sender
{
    [self insertConfigView:kMtConfigViewAddBelow];
}

- (IBAction)addViewLeft:(id)sender
{
    [self insertConfigView:kMtConfigViewAddLeft];
}

- (IBAction)removeView:(id)sender
{
    NSView* parent = self.superview;
    NSView* grandfather = parent.superview;
    NSUInteger idx = [parent.subviews indexOfObject:self];
    MtConfigView* sibling = [parent.subviews objectAtIndex:idx == 0 ? 1: 0];
    if (   ![grandfather isKindOfClass:[NSSplitView class]]
        && [sibling isKindOfClass:[MtConfigView class]]) {
        // our sibling will be the top level view - so disable it's
        [sibling.removeMenuItem setEnabled:NO];
    }
    // the frame are going to get messed up as we add/remove so save and restore
    NSRect f1 = [grandfather.subviews.firstObject frame];
    NSRect f2 = [grandfather.subviews.lastObject frame];
    [grandfather addSubview:sibling positioned:NSWindowBelow relativeTo:parent];
    [((id<MtConfigViewDelegate>)_controller) removingView:self];
    [parent removeFromSuperview];
    [grandfather.subviews.firstObject setFrame:f1];
    [grandfather.subviews.lastObject setFrame:f2];
    [grandfather setNeedsDisplay:YES];
    
//    NSView* top = sibling;
//    while ([top superview] != nil) {
//        top = [top superview];
//    }
//    NSLog(@"%@", [top hierarchicalDescriptionOfView]);
}

- (IBAction)changeContent:(id)sender
{
    BOOL content = NO; // XXX: not technically right - you might not add views
    NSArray* subviews = _toolbar.subviews;
    for (id view in subviews) {
        [view removeFromSuperview];
        content = YES;
    }
    subviews = _content.subviews;
    for (id view in subviews) {
        [view removeFromSuperview];
        content = YES;
    }
    if (content) {
        [((id<MtConfigViewDelegate>)_controller) removingView:self];
    }
    [((id<MtConfigViewDelegate>)_controller) createItem:sender inView:self];
}


- (void)insertConfigView:(MtConfigViewAdd)where
{
    NSView* parent = self.superview; // parent is the paneFrame
    
    // we don't need to replace _view with split, or even remove it as that
    // happens when we add it into split.  If we try we get wierd issues where
    // it's unresponsive
    NSSplitView* split = [[NSSplitView alloc] initWithFrame:[self frame]];
    [split setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [split setDividerStyle:NSSplitViewDividerStyleThin];
    [parent addSubview:split positioned:NSWindowBelow relativeTo:self];
    
    if (where == kMtConfigViewAddAbove) {
        [split setVertical:NO];
        MtConfigView* view = [MtConfigView configView];
        view.controller = _controller;
        [split addSubview:view];
        [split addSubview:self];
        
    } else if (where == kMtConfigViewAddRight) {
        [split setVertical:YES];
        [split addSubview:self];
        MtConfigView* view = [MtConfigView configView];
        view.controller = _controller;
        [split addSubview:view];
        
    } else if (where == kMtConfigViewAddBelow) {
        [split setVertical:NO];
        [split addSubview:self];
        MtConfigView* view = [MtConfigView configView];
        view.controller = _controller;
        [split addSubview:view];
        
    } else if (where == kMtConfigViewAddLeft) {
        [split setVertical:YES];
        MtConfigView* view = [MtConfigView configView];
        view.controller = _controller;
        [split addSubview:view];
        [split addSubview:self];
        
    }
    for (MtConfigView* view in [split subviews]) {
        [view.removeMenuItem setEnabled:YES];
    }
    [split adjustSubviews];
    [parent setNeedsDisplay:YES];
    
//    NSView* top = self;
//    while ([top superview] != nil) {
//        top = [top superview];
//    }
//    NSLog(@"%@", [top hierarchicalDescriptionOfView]);
}

// NSMenuDelegate - route to the controller which sends them to the delegate
- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu
{
    return [_controller numberOfItemsInMenu:menu]+2;
}

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
    BOOL retval = YES;
    if (index < 2) {
        [item setTitle:@"Layout"];
    } else {
        [item setTarget:self];
        [item setAction:@selector(changeContent:)];
        retval = [_controller menu:menu updateItem:item atIndex:index-2 shouldCancel:shouldCancel];
    }
    return retval;
}

@end
