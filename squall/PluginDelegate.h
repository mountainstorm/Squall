//
//  PluginDelegate.h
//  squall
//
//  Created by cooper on 06/09/2016.
//  Copyright © 2016 mountainstorm. All rights reserved.
//

#ifndef PluginDelegate_h
#define PluginDelegate_h

#import <Foundation/Foundation.h>
#import <squall/PaneController.h>

@protocol PluginDelegate

- (id)initWithConfig:(NSDictionary*)config;
- (NSDictionary*)archiveConfig;
- (void)addedController:(id<PaneController>)controller;
- (void)removingController:(id<PaneController>)controller;
- (void)launchWithArguments:(NSArray*)args;
- (void)shutdown;

@end

#endif /* PluginDelegate_h */
