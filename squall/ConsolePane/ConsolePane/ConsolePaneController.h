//
//  ConsolePaneController.h
//  ConsolePane
//
//  Created by cooper on 07/09/2016.
//  Copyright © 2016 cooper. All rights reserved.
//

#import <squall/PaneController.h>
#import "ConsoleCommand.h"
#import "ConsoleResults.h"


@interface ConsolePaneController : NSObject

- (IBAction)updated:(id)sender;

- (void)updatePaneWithPrompt:(NSString*)prompt cmd:(NSString*)cmd result:(NSAttributedString*)s;
- (void)updatePaneWithState:(NSAttributedString*)s;
- (NSString*)getLastCommand;

@property (assign) IBOutlet NSTextField* toolbar;
@property (assign) IBOutlet NSView* content;
@property (assign) IBOutlet ConsoleCommand* console;
@property (assign) IBOutlet ConsoleResults* results;

@property (retain) NSFont* font;
@property (retain) NSFont* bold;
@property (retain) NSMutableDictionary* config;

@end
