//
//  Error.h
//  Squall
//
//  Created by cooper on 11/09/2016.
//  Copyright © 2016 cooper. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Error : NSObject

+ (void)criticalError:(NSString*)title withError:(NSError*)error;
+ (void)criticalError:(NSString*)title withString:(NSString*)error;

@end
