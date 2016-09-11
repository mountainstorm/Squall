//
//  Document.h
//  Squall
//
//  Created by cooper on 10/09/2016.
//  Copyright © 2016 cooper. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MtConfigViewController.h"
#import "PluginDelegate.h"

@interface Project : NSDocument <MtConfigViewDelegate>

@property (retain) NSMutableDictionary* config;
@property (retain) NSArray* panes;
@property (retain) id<PluginDelegate> plugin;

@property (retain) MtConfigViewController* configViewController;
@property (retain) NSMapTable<MtConfigView*, id<PaneController>>* controllers;

@end

