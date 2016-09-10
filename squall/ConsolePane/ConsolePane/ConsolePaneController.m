//
//  ConsolePaneController.m
//  ConsolePane
//
//  Created by cooper on 07/09/2016.
//  Copyright © 2016 cooper. All rights reserved.
//

#import "ConsolePaneController.h"

@implementation ConsolePaneController

@synthesize toolbar = _toolbar;
@synthesize content = _content;
@synthesize console = _console;
@synthesize results = _results;

@synthesize font = _font;
@synthesize bold = _bold;
@synthesize config = _config;


- (id)initWithConfig:(NSDictionary*)config inView:(MtConfigView*)view
{
    self = [super init];
    self.config = [NSMutableDictionary dictionaryWithDictionary:config];
    [[NSBundle bundleForClass:[ConsolePaneController class]] loadNibNamed:@"ConsolePane" owner:self topLevelObjects:nil];
    
    // load basic fonts
    NSNumber* fontsize = (NSNumber*) [config objectForKey:@"fontsize"];
    _font = [NSFontManager.sharedFontManager fontWithFamily:[config objectForKey:@"font"]
                                             traits:0
                                             weight:5
                                             size:fontsize.floatValue];
    _bold = [NSFontManager.sharedFontManager fontWithFamily:[config objectForKey:@"font"]
                                             traits:NSBoldFontMask
                                             weight:5
                                             size:fontsize.floatValue];
    return self;
}

- (NSDictionary*)archiveConfig
{
    return self.config;
}

- (IBAction)updated:(id)sender
{
    // should be overridden in subclass
}

- (void)updatePaneWithPrompt:(NSString*)prompt cmd:(NSString*)cmd result:(NSAttributedString*)s
{
    // highlight the command you typed
    NSColor* color = [NSColor grayColor];
    NSDictionary* font = [NSDictionary dictionaryWithObjects:@[_font, color] forKeys:@[NSFontAttributeName, NSForegroundColorAttributeName]];
    NSDictionary* bold = [NSDictionary dictionaryWithObject:_bold forKey:NSFontAttributeName];
    
    NSString* p = [NSString stringWithFormat:@"%@ ", prompt];
    NSMutableAttributedString* text = [[NSMutableAttributedString alloc] initWithString:p attributes:font];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:cmd attributes:bold]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    [text appendAttributedString:s];
    [self updatePaneWithState:text];
}

- (void)updatePaneWithState:(NSAttributedString*)s
{
    // we ned to strip trailing whitespace
    int i = (int)s.string.length - 1;
    while (i >= 0) {
        unichar c = [s.string characterAtIndex:i];
        if (c != '\n' && c != ' ' && c != '\r' && c != '\t') {
            break;
        }
        i--;
    }
    i++;
    NSMutableAttributedString* results = [[NSMutableAttributedString alloc] initWithAttributedString:s];
    [results deleteCharactersInRange:NSMakeRange(i, s.string.length - i)];

    // create a new pane
    NSTextField* field = [[NSTextField alloc] init];
    field.editable = NO;
    field.bezeled = NO;
    field.drawsBackground = NO;
    field.selectable = YES;
    field.allowsEditingTextAttributes = YES;
    field.attributedStringValue = results;
    NSSize sz = [field.cell cellSizeForBounds:NSMakeRect(0, 0, 10000000, 10000000)];
    field.frame = NSMakeRect(0, 0, sz.width, sz.height);
    [_results addSubview:field];
    [self.results setNeedsDisplay:YES];
    
    // clear the pane and scroll to bottom
    self.console.stringValue = @"";
    NSScrollView* scrollview = (NSScrollView*) self.results.superview.superview;
    [scrollview.documentView scrollPoint:NSMakePoint(0, 0)];
}

- (NSString*)getLastCommand
{
    NSString* retval = nil;
    if (self.console.history.count > 0) {
        retval = self.console.history[0];
    }
    return retval;
}

@end
