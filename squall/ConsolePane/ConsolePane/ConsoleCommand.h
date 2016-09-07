//
//  ConsoleCommand.h
//  ConsolePane
//
//  Created by cooper on 07/09/2016.
//  Copyright © 2016 cooper. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ConsoleCommand : NSTextField
{
    long _historyIdx;
}

@property (retain) NSMutableArray* history;

@end
