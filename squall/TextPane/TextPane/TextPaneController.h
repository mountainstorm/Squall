//
//  TextPaneController.h
//  squall
//
//  Created by cooper on 05/09/2016.
//  Copyright © 2016 mountainstorm. All rights reserved.
//

#import <squall/PaneController.h>


@interface TextPaneController : NSObject <PaneController>

- (IBAction)updated:(id)sender;

- (void)updatePane:(NSAttributedString*)s;

@property (assign) IBOutlet NSTextField* toolbar;
@property (assign) IBOutlet NSView* content;
@property (assign) IBOutlet NSTextView* results;

@property (retain) NSFont* font;
@property (retain) NSMutableDictionary* config;

@end
