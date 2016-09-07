//
//  MtAppDelegate.m
//  squall
//
//  Created by Cooper on 15/08/2012.
//  Copyright (c) 2012 mountainstorm. All rights reserved.
//

#import "MtAppDelegate.h"
#import "PaneController.h"
#import "NSView+HierarchicalDescription.h"

@implementation MtAppDelegate

@synthesize window = _window;
@synthesize rootView = _rootView;
@synthesize configViewController = _configViewController;
@synthesize controllers = _controllers;

@synthesize config = _config;
@synthesize commands = _commands;
@synthesize plugin = _plugin;


- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    // load the settings
    NSError* error = nil;
     [self loadConfigWithError:&error];
    if (_config == nil) {
        [self criticalError:@"Unable to load config" withError:error];
    }
    
    _commands = _config[@"commands"];
    if (_commands == nil || [_commands isKindOfClass:[NSArray class]] == false) {
        [self criticalError:@"Unable to load config" withString:@"no 'commands' object present"];
    }
    
    // load all the other plugins
    [self loadPlugins];
    
    // load the plugin
    NSString* pluginName = _config[@"plugin"];
    if (pluginName == nil) {
        [self criticalError:@"Unable to load config" withString:@"no 'plugin' string present"];
    }
    NSString* pluginPath = [[NSBundle mainBundle].builtInPlugInsPath
                                    stringByAppendingPathComponent:pluginName];
    NSBundle* pluginBundle = [NSBundle bundleWithPath:pluginPath];
    NSString* errStr = [NSString stringWithFormat:@"plugin '%@' failed to load", pluginName];
    if ([pluginBundle load] == NO) {
        [self criticalError:@"Unable to load plugin" withString:errStr];
    }
    
    Class pluginClass = [pluginBundle principalClass];
    _plugin = [[pluginClass alloc] initWithConfig:_config];
    if (_plugin == nil) {
        [self criticalError:@"Unable to init plugin" withString:errStr];
    }

    // setup members
    _controllers = [NSMapTable strongToStrongObjectsMapTable];
    
    // setup adjustable view controller/view
    _configViewController = [[MtConfigViewController alloc] initWithFrame:_rootView.frame];
    [_rootView addSubview:_configViewController.view];
    _configViewController.delegate = self;
    
    // load the window layout - triggers the creation of objects
    NSData* layout = [NSUserDefaults.standardUserDefaults objectForKey:@"windowLayout"];
    if (layout) {
        //[_configViewController unarchiveLayout:layout];
    }
}

- (void)windowWillClose:(NSNotification*)notification
{
    // save the window layout
//	[NSUserDefaults.standardUserDefaults setObject:[_configViewController archiveLayout]
//											  forKey:@"windowLayout"];
	[NSUserDefaults.standardUserDefaults synchronize];
}

- (NSInteger)numberOfItemsInMenu:(NSMenu*)menu
{
    return _commands.count;
}

- (BOOL)menu:(NSMenu*)menu updateItem:(NSMenuItem*)item atIndex:(NSInteger)index shouldCancel:(BOOL)cancel
{
    NSDictionary* cmd = _commands[index];
    if ([cmd[@"title"] isEqualToString:@"--"]) {
        [menu removeItemAtIndex:index+2];
        [menu insertItem:NSMenuItem.separatorItem atIndex:index+2];
    } else {
        [item setTitle:cmd[@"title"]];
        [item setTag:index];
    }
    return YES;
}

- (void)createItem:(NSMenuItem*)item inView:(MtConfigView*)view
{
    // XXX: merge cmd and cmddefaults
    NSMutableDictionary* cmd = [NSMutableDictionary dictionaryWithDictionary:_config[@"command.defaults"]];
    [cmd addEntriesFromDictionary:_commands[item.tag]];
    [self createCommand:cmd inView:view];
}

- (void)createCommand:(NSDictionary*)cmd inView:(MtConfigView*)view
{
    Class cls = NSClassFromString(cmd[@"controller"]);
    id<PaneController> controller = [[cls alloc] initWithConfig:cmd inView:view];
    [_controllers setObject:controller forKey:view];
    // load it into the view

    // set the size of the views and add then to the view
    [controller.toolbar setFrameSize:view.toolbar.frame.size];
    [view.toolbar addSubview:controller.toolbar];
    
    // XXX: I dont know why this is needed - but view.content appears to be too big?
    NSSize sz = view.content.frame.size;
    sz.height = view.superview.frame.size.height - view.toolbar.frame.size.height;
    [controller.content setFrameSize:view.content.frame.size];
    [view.content addSubview:controller.content];
    [_plugin addedController:controller];
}

- (void)removingView:(MtConfigView*)view
{
    id<PaneController> controller = [_controllers objectForKey:view];
    if (controller) {
        [_plugin removingController:controller];
        [_controllers removeObjectForKey:view];
    }
}

- (NSDictionary*)loadJson:(NSString*)path error:(NSError**)error
{
    NSDictionary* retval = nil;
    NSData* json = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:error];
    if (json != nil) {
        retval = [NSJSONSerialization JSONObjectWithData:json options:kNilOptions error:error];
    }
    return retval;
}

- (void)loadConfigWithError:(NSError**)error
{
    _config = [NSMutableDictionary dictionaryWithDictionary:[self loadJson:[[NSBundle mainBundle] pathForResource:@"config" ofType:@"json"] error:error]];
    if (_config != nil) {
        // now load any config in the local domain or user domain
        NSFileManager* fileManager = NSFileManager.defaultManager;
        NSString* dn = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
        NSArray* systemPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask | NSLocalDomainMask, YES);
        for (NSString* searchPath in systemPaths) {
            NSString* path = [searchPath stringByAppendingPathComponent:dn];
            path = [path stringByAppendingPathComponent:@"config.json"];
            if ([fileManager fileExistsAtPath:path]) {
                NSDictionary* c = [self loadJson:[[NSBundle mainBundle] pathForResource:@"config" ofType:@"json"] error:error];
                if (c == nil) {
                    _config = nil;
                    return;
                }
                // and overrride
                [_config addEntriesFromDictionary:c];
            }
        }
    }
}

- (void)loadPlugins
{
    NSString* dn = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
    NSArray* systemPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask | NSLocalDomainMask, YES);
    for (NSString* searchPath in systemPaths) {
        NSString* path = [searchPath stringByAppendingPathComponent:dn];
        path = [path stringByAppendingPathComponent:@"PlugIns"];
        [self loadPluginsInPath:path];
    }
    [self loadPluginsInPath:NSBundle.mainBundle.builtInPlugInsPath];
}

- (void)loadPluginsInPath:(NSString*)path
{
    NSFileManager* fileManager = NSFileManager.defaultManager;
    if ([fileManager fileExistsAtPath:path]) {
        NSArray* files = [fileManager contentsOfDirectoryAtPath:path error:nil];
        for (NSString* file in files) {
            if ([file.pathExtension isEqualToString:@"bundle"]) {
                NSBundle* bundle = [NSBundle bundleWithPath:file];
                if (bundle == nil || [bundle load] == NO) {
                    [self criticalError:@"Loading bundle" withString:file];
                }
            }
        }
    }
}

- (void)criticalError:(NSString*)title withError:(NSError*)error
{
    [self criticalError:title withString:error.localizedDescription];
}

- (void)criticalError:(NSString*)title withString:(NSString*)error
{
    NSAlert* alert = [[NSAlert alloc] init];
    alert.informativeText = error;
    alert.messageText = title;
    alert.alertStyle = NSCriticalAlertStyle;
    NSLog(@"Critical Error: %@", title);
    [alert runModal];
    [NSApp terminate:nil];
}

@end
