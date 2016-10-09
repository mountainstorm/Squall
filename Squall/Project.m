//
//  Document.m
//  Squall
//
//  Created by cooper on 10/09/2016.
//  Copyright © 2016 cooper. All rights reserved.
//

#import "Project.h"
#import "Error.h"
#import "ConfigProjectCommand.h"

@interface Project ()

@end

@implementation Project

@synthesize config = _config;
@synthesize panes = _panes;
@synthesize plugin = _plugin;

@synthesize configViewController = _configViewController;
@synthesize controllers = _controllers;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _controllers = [[NSMapTable alloc] init];
    
        // load the basic config - this is the combination of:
        // 1. builtin
        // 2. system
        // 3. user config
        NSError* error = nil;
        _config = [self loadConfigWithError:&error];
        if (_config) {
            _panes = _config[@"panes"];
            if (_panes == nil) {
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : @"no 'panes' field in config" }];
            }
        }
        
        if (error != nil) {
            NSLog(@"%@", error.localizedDescription);
        }
    }
    return _panes != nil ? self: nil;
}

- (instancetype)initWithType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError
{
    self = [self init];
    if (self) {
        if (g_customization != nil) {
            [_config addEntriesFromDictionary:g_customization];
            g_customization = nil;
        }
    
        NSError* error = nil;
         _plugin = [self loadPluginWithError:&error];
        
        if (error != nil) {
            NSLog(@"%@", error.localizedDescription);
        }
    }
    return _plugin != nil ? self: nil;
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

- (IBAction)saveDocumentAs:(id)sender
{
    NSMenuItem* item = sender;
    if ([item.title isEqualToString:@"Save As Default"]) {
        // save to
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString* applicationSupportDirectory = [paths objectAtIndex:0];
        NSString* exe = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
        NSString* path = [applicationSupportDirectory stringByAppendingPathComponent:exe];
        
        NSFileManager* fileManager = [NSFileManager defaultManager];
        if ([fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil]) {
            path = [path stringByAppendingPathComponent:@"config.json"];
            NSURL* userconfig = [NSURL fileURLWithPath:path isDirectory:NO];
            [self saveToURL:userconfig ofType:@"SquallProject" forSaveOperation:NSSaveOperation completionHandler:^(NSError *errorOrNil) {} ];
        }
    } else {
        [super saveDocumentAs:sender];
    }
}

- (void)close
{
    [super close];
    if (_plugin != nil) {
        [_plugin shutdown];
    }
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Project";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    
    // save the layout
    NSMutableDictionary* project = [NSMutableDictionary dictionary];
    NSDictionary* value = [_configViewController archiveLayout];
    if (value != nil) {
        [project setObject:value forKey:@"layout"];
    }
    value = [_plugin archiveSettings];
    if (value != nil) {
        [project setObject:value forKey:@"project"];
    }
    return [NSJSONSerialization dataWithJSONObject:project options:NSJSONWritingPrettyPrinted error:outError];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL retval = NO;
    // 4. load project configuration
    NSDictionary* config = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:outError];
    if (config != nil) {
        [_config addEntriesFromDictionary:config];

        if (g_customization != nil) {
            [_config addEntriesFromDictionary:g_customization];
            g_customization = nil;
        }

        NSError* error = nil;
        _plugin = [self loadPluginWithError:&error];
        if (_plugin == nil) {
            NSLog(@"%@", error.localizedDescription);
        } else {
            retval = YES;
        }
    }
    return retval;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    // XXX: get customization if its present and update _config

    // nib has loaded - we can now get init the config view
    NSView* root = [[[self windowControllers] objectAtIndex:0] window].contentView;
    _configViewController = [[MtConfigViewController alloc] initWithFrame:root.frame];
    [root addSubview:_configViewController.view];
    _configViewController.delegate = self;
    
    // load the window layout from the config
    NSDictionary* layout = [_config objectForKey:@"layout"];
    if (layout) {
        [_configViewController unarchiveLayout:layout];
        [_plugin launch];
    }
}

- (void)updateChangeCount:(NSDocumentChangeType)changeType {
    // overridden to do nothing. Thus preventing save dialog on quit
}

- (NSMutableDictionary*)loadConfigWithError:(NSError**)outError
{
    NSMutableDictionary* retval = nil;
    
    // 1. load the builtin configuation
    NSError* error = nil;
    NSString* path = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"json"];
    NSMutableDictionary* config = [NSMutableDictionary dictionaryWithDictionary:[self loadJson:path error:&error]];
    if (config != nil) {
        NSFileManager* fileManager = NSFileManager.defaultManager;
        NSString* exe = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
        
        // 2. and 3. overload with system, then user config
        NSArray* systemPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask | NSLocalDomainMask, YES);
        for (NSString* searchPath in [systemPaths reverseObjectEnumerator]) {
            path = [searchPath stringByAppendingPathComponent:exe];
            // make the full path
            path = [path stringByAppendingPathComponent:@"config.json"];
            if ([fileManager fileExistsAtPath:path]) {
                NSDictionary* c = [self loadJson:path error:&error];
                if (c == nil) {
                    config = nil;
                    break;
                }
                // and overrride
                [config addEntriesFromDictionary:c];
            }
        }
    }
    
    if (config != nil) {
        retval = config;
    }
    return retval;
}


// delegate methods
- (NSInteger)numberOfItemsInMenu:(NSMenu*)menu
{
    return _panes.count;
}

- (BOOL)menu:(NSMenu*)menu updateItem:(NSMenuItem*)item atIndex:(NSInteger)index shouldCancel:(BOOL)cancel
{
    NSDictionary* pane = _panes[index];
    if ([pane[@"title"] isEqualToString:@"--"]) {
        [menu removeItemAtIndex:index+2];
        [menu insertItem:NSMenuItem.separatorItem atIndex:index+2];
    } else {
        [item setTitle:pane[@"title"]];
        [item setTag:index];
    }
    return YES;
}

- (void)createItem:(NSMenuItem*)item inView:(MtConfigView*)view
{
    // XXX: merge cmd and cmddefaults
    NSMutableDictionary* config = [NSMutableDictionary dictionaryWithDictionary:_config[@"global"]];
    [config addEntriesFromDictionary:_panes[item.tag]];
    [self createPane:config inView:view];
}

- (void)createPane:(NSDictionary*)config inView:(MtConfigView*)view
{
    Class cls = NSClassFromString(config[@"class"]);
    if (cls != nil) {
        id<PaneController> controller = [[cls alloc] initWithConfig:config inView:view];
        [_controllers setObject:controller forKey:view];
        
        // load it into the view
        // set the size of the views and add then to the view
        [controller.toolbar setFrameSize:view.toolbar.frame.size];
        [view.toolbar addSubview:controller.toolbar];

        [controller.content setFrameSize:view.content.frame.size];
        [view.content addSubview:controller.content];
        [_plugin addedController:controller];
    }
}

- (void)removingView:(MtConfigView*)view
{
    id<PaneController> controller = [_controllers objectForKey:view];
    if (controller) {
        [_plugin removingController:controller];
        [_controllers removeObjectForKey:view];
    }
}

- (NSDictionary*)archiveConfigOfView:(MtConfigView*)view
{
    id<PaneController> controller = [_controllers objectForKey:view];
    NSDictionary* retval = [controller archiveSettings];
    if (retval == nil) {
        retval = [NSDictionary dictionary];
    }
    return retval;
}

- (void)unarchiveConfig:(NSDictionary*)settings intoView:(MtConfigView*)view
{
    if (settings != nil) {
        NSMutableDictionary* config = [NSMutableDictionary dictionaryWithDictionary:_config[@"global"]];
        NSString* title = settings[@"title"];
        for (NSDictionary* pane in _panes) {
            if ([pane[@"title"] isEqualToString:title]) {
                // found pane config
                [config addEntriesFromDictionary:pane];
                break;
            }
        }
        // even if we didn't find the base config, extend and try creating it
        [config addEntriesFromDictionary:settings];
        [self createPane:config inView:view];
    }
}


// internal functions
- (NSDictionary*)loadJson:(NSString*)path error:(NSError**)outError
{
    NSDictionary* retval = nil;
    NSData* json = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:outError];
    if (json != nil) {
        retval = [NSJSONSerialization JSONObjectWithData:json options:kNilOptions error:outError];
    }
    return retval;
}

- (id<PluginDelegate>)loadPluginWithError:(NSError**)outError
{
    id<PluginDelegate> retval = nil;
    // get the plugin name
    NSString* name = _config[@"plugin"];
    if (name == nil) {
        NSString* description = @"Config invalid, no 'plugin' string in config";
        *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : description }];
        
    } else {
        // go look for the plugin
        NSString* exe = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
        NSArray* systemPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask | NSLocalDomainMask, YES);
        for (NSString* searchPath in [systemPaths reverseObjectEnumerator]) {
            NSString* path = [searchPath stringByAppendingPathComponent:exe];
            path = [path stringByAppendingPathComponent:@"PlugIns"];
            retval = [self loadPlugin:name inPath:path error:outError];
            if (retval != nil) {
                break;
            }
        }
        if (retval == nil) {
            retval = [self loadPlugin:name inPath:NSBundle.mainBundle.builtInPlugInsPath error:outError];
        }
        
        if (retval == nil && *outError == nil) {
            NSString* description = [NSString stringWithFormat:@"Unable to find plugin '%@'", name];
            *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : description }];
        }
    }
    return retval;
}

- (id<PluginDelegate>)loadPlugin:(NSString*)name inPath:(NSString*)path error:(NSError**)outError
{
    id<PluginDelegate> retval = nil;
    NSFileManager* fileManager = NSFileManager.defaultManager;
    NSString* fn = [path stringByAppendingPathComponent:name];
    if ([fileManager fileExistsAtPath:fn]) {
        NSBundle* pluginBundle = [NSBundle bundleWithPath:fn];
        if ([pluginBundle load] == NO) {
            NSString* description = [NSString stringWithFormat:@"Unable to load plugin '%@'", fn];
            *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : description }];
        } else {
            Class pluginClass = [pluginBundle principalClass];
            retval = [[pluginClass alloc] initWithDocument:self andConfig:_config];
            if (retval == nil) {
                NSString* description = [NSString stringWithFormat:@"Unable to init plugin '%@'", fn];
                *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : description }];
            }
        }
    }
    return retval;
}

- (NSArray*)args
{
    NSArray* retval = [NSArray array];
    // only pass the arguments if we're the going to be the first document
    if ([NSDocumentController sharedDocumentController].documents.count == 0) {
        retval = [[NSProcessInfo processInfo] arguments];
    }
    return retval;
}

@end
