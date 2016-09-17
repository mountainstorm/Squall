//
//  PluginDelegate.h
//  Squall
//
//  Created by cooper on 06/09/2016.
//  Copyright © 2016 mountainstorm. All rights reserved.
//

#ifndef PluginDelegate_h
#define PluginDelegate_h

#import <Foundation/Foundation.h>
#import <Squall/PaneController.h>

@protocol PluginDelegate

- (id)initWithDocument:(__weak NSDocument*)docuemnt andConfig:(NSDictionary*)config;
- (NSDictionary*)archiveSettings;

- (void)addedController:(id<PaneController>)controller;
- (void)removingController:(id<PaneController>)controller;

- (void)launch;
- (void)shutdown;

@end

#endif /* PluginDelegate_h */
