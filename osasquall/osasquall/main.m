//
//  main.m
//  osasquall
//
//  Created by cooper on 11/09/2016.
//  Copyright © 2016 cooper. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ScriptingBridge/ScriptingBridge.h>
#import "Squall.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString* project = nil;
        if (argc == 2) {
            project = [NSString stringWithUTF8String:argv[1]];
        }
        
        NSMutableString* json = [[NSMutableString alloc] init];
        NSFileHandle* input = [NSFileHandle fileHandleWithStandardInput];
        NSData* data = [input readDataToEndOfFile];
        if (data == nil) {
            [json appendString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        }
      
        // if we're not started - start us
        NSString* bid = @"uk.co.mountainstorm.Squall";
        SquallApplication* app = [SBApplication applicationWithBundleIdentifier:bid];
        if (!app.running) {
            // launch it so it doesn't open an untitled document
            NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
            
            NSURL* url = [workspace URLForApplicationWithBundleIdentifier:bid];
            NSDictionary* args = @{ NSWorkspaceLaunchConfigurationArguments: @[@"-silent"] };
            [workspace launchApplicationAtURL:url options:0 configuration:args error:nil];
            
        }
        [app activate];
        [app configJson:json project:project];
        
    }
    return 0;
}
