//
//  MtAppDelegate.h
//  squall
//
//  Created by Cooper on 15/08/2012.
//  Copyright (c) 2012 mountainstorm. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MtConfigView/MtConfigViewController.h"
#import "MtConfigViewDelegate.h"
#import "PluginDelegate.h"
#import "PaneController.h"


@interface MtAppDelegate : NSObject <NSApplicationDelegate, MtConfigViewDelegate>

@property (assign) IBOutlet NSWindow* window;
@property (assign) IBOutlet NSView* rootView;

@property (retain) MtConfigViewController* configViewController;

@property (retain) NSMapTable<MtConfigView*, id<PaneController>>* controllers;
@property (retain) NSMutableDictionary* config;
@property (retain) NSArray* commands;
@property (retain) id<PluginDelegate> plugin;

@end
