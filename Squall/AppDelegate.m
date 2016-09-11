//
//  AppDelegate.m
//  Squall
//
//  Created by cooper on 10/09/2016.
//  Copyright © 2016 cooper. All rights reserved.
//

#import "AppDelegate.h"
#import "Error.h"
#include <syslog.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    [self loadBundles];

}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    BOOL retval = YES;
    
    for (NSString* arg in [[NSProcessInfo processInfo] arguments]) {
        syslog(1, "arg: %s", [arg UTF8String]);
        if ([arg isEqualToString:@"-silent"]) {
            // started via out apple event
            retval = NO;
        }
    }
    return retval;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

- (void)loadBundles
{
    NSString* dn = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
    NSArray* systemPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask | NSLocalDomainMask, YES);
    for (NSString* searchPath in systemPaths) {
        NSString* path = [searchPath stringByAppendingPathComponent:dn];
        path = [path stringByAppendingPathComponent:@"PlugIns"];
        [self loadBundlesInPath:path];
    }
    [self loadBundlesInPath:NSBundle.mainBundle.builtInPlugInsPath];
}

- (void)loadBundlesInPath:(NSString*)path
{
    NSFileManager* fileManager = NSFileManager.defaultManager;
    if ([fileManager fileExistsAtPath:path]) {
        NSArray* files = [fileManager contentsOfDirectoryAtPath:path error:nil];
        for (NSString* file in files) {
            if ([file.pathExtension isEqualToString:@"bundle"]) {
                NSString* s = [path stringByAppendingPathComponent:file];
                NSBundle* bundle = [NSBundle bundleWithPath:s];
                if (bundle == nil || [bundle load] == NO) {
                    [Error criticalError:@"Loading bundle" withString:s];
                    break;
                }
            }
        }
    }
}

@end
