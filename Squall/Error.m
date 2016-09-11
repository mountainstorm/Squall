//
//  Error.m
//  Squall
//
//  Created by cooper on 11/09/2016.
//  Copyright © 2016 cooper. All rights reserved.
//

#import "Error.h"

@implementation Error


+ (void)criticalError:(NSString*)title withError:(NSError*)error
{
    [Error criticalError:title withString:error.localizedDescription];
}

+ (void)criticalError:(NSString*)title withString:(NSString*)error
{
    NSAlert* alert = [[NSAlert alloc] init];
    alert.informativeText = error;
    alert.messageText = title;
    alert.alertStyle = NSCriticalAlertStyle;
    NSLog(@"%@, %@", title, error);
    [alert runModal];
    [NSApp terminate:nil];
}

@end
