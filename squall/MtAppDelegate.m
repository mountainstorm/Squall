//
//  MtAppDelegate.m
//  squall
//
//  Created by Cooper on 15/08/2012.
//  Copyright (c) 2012 mountainstorm. All rights reserved.
//

#import "MtAppDelegate.h"
#import "NSView+HierarchicalDescription.h"

@implementation MtAppDelegate

@synthesize window = _window;
@synthesize rootView = _rootView;
@synthesize configViewController = _configViewController;


- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    _configViewController = [[MtConfigViewController alloc] init];
    [_configViewController.view setFrame: [_rootView frame]];
    [_rootView addSubview:_configViewController.view];
   
    NSDictionary* config = [self loadConfig];
    if (config) {
        NSString *pluginPath = [[NSBundle mainBundle].builtInPlugInsPath
                                    stringByAppendingPathComponent:
                                        [config objectForKey:@"plugin"]];
        NSBundle *pluginBundle = [NSBundle bundleWithPath:pluginPath];
        id<MtConfigViewDelegate> plugin = nil;
        if ([pluginBundle load] == YES) {
            Class pluginClass = [pluginBundle principalClass];
            plugin = [[pluginClass alloc] init];
            if (plugin != nil) {
                _pythonDelegate = plugin;
                _configViewController.delegate = plugin;
            }
        }
        if (plugin == nil) {
            [self criticalError:@"Citrical Error" withText:@"Unable to initialize scripting core"];
        }

        NSData* layout = [[NSUserDefaults standardUserDefaults] objectForKey:@"windowLayout"];
        if (layout) {
            [_configViewController unarchiveLayout:layout];
        }
    }
}

- (void)windowWillClose:(NSNotification*)notification
{
	[[NSUserDefaults standardUserDefaults] setObject:[_configViewController archiveLayout]
											  forKey:@"windowLayout"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDictionary*)loadConfig
{
    NSDictionary* retval = nil;
    NSError* error = nil;
    NSString* path = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"config.json"];
    NSData* data = [NSData dataWithContentsOfFile:path options:kNilOptions error:&error];
    if (data == nil) {
        [self criticalError:@"Critical error; reading config.json" withError:error];
    } else {
        retval = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (retval == nil) {
            [self criticalError:@"Critical error; reading config.json" withError:error];
        }
    }
    return retval;
}

- (void)criticalError:(NSString*)title withError:(NSError*)error
{
    [self criticalError:title withText:error.localizedDescription];
}

- (void)criticalError:(NSString*)title withText:(NSString*)error
{
    NSAlert* alert = [[NSAlert alloc] init];
    alert.informativeText = error;
    alert.messageText = title;
    alert.alertStyle = NSCriticalAlertStyle;
    NSLog(@"CriticalError: %@", title);
    [alert runModal];
    [NSApp terminate:nil];
}

@end
