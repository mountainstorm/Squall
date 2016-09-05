//
//  MtConfigView.h
//  squall
//
//  Created by cooper on 30/08/2016.
//  Copyright © 2016 mountainstorm. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MtConfigView : NSView<NSMenuDelegate>

// methods
+ (id)configView;

// action
- (IBAction)addViewAbove:(id)sender;
- (IBAction)addViewRight:(id)sender;
- (IBAction)addViewBelow:(id)sender;
- (IBAction)addViewLeft:(id)sender;
- (IBAction)removeView:(id)sender;
- (IBAction)changeContent:(id)sender;

// properties
@property (assign) IBOutlet NSMenuItem* removeMenuItem; // remove button
@property (assign) IBOutlet NSView* content; // the content view
@property (assign) IBOutlet NSView* toolbar; // the toolbar view

@property (assign) id<NSMenuDelegate> controller;

@end
