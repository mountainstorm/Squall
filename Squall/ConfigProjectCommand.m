//
//  ConfigProjectCommand.m
//  Squall
//
//  Created by cooper on 11/09/2016.
//  Copyright © 2016 cooper. All rights reserved.
//

#import "ConfigProjectCommand.h"


@implementation ConfigProjectCommand

- (id)performDefaultImplementation
{
    NSDictionary* args = [self evaluatedArguments];
    if (args.count < 1 || args.count > 2) {
        [self setScriptErrorNumber:-50];
        [self setScriptErrorString:@"Parameter Error: A JSON parameter is expected for the verb 'config'"];

    } else {
        NSString* jsonString = [args valueForKey:@"json"];
        NSError* error = nil;
        NSDictionary* config = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
        if (config == nil) {
            [self setScriptErrorNumber:-51];
            [self setScriptErrorString:@"Parameter Error: A JSON parameter is expected for the verb 'config'"];
        } else {
            NSString* project = nil;
            if (args.count == 2) {
                project = [args valueForKey:@"project"];
            }
            NSLog(@"got message: %@", config);
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"AppShouldLookupStringNotification" object:stringToSearch];
        }
    }
    return nil;
}

@end
