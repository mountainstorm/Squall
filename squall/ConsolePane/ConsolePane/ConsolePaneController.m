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


- (id)initWithConfig:(NSDictionary*)config inView:(MtConfigView*)view
{
    self = [super init];
    [[NSBundle bundleForClass:[ConsolePaneController class]] loadNibNamed:@"ConsolePane" owner:self topLevelObjects:nil];
    
    // load basic fonts
    _font = [NSFont userFixedPitchFontOfSize:11.0];
    _bold = [NSFontManager.sharedFontManager convertFont:_font toHaveTrait:NSBoldFontMask];
    return self;
}

- (BOOL)control: (NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    NSLog(@"entered control area = %@", NSStringFromSelector(commandSelector));
    return YES;
}

- (IBAction)updated:(id)sender
{
    // should be overridden in subclass
}

- (void)updatePane:(NSAttributedString*)s
{
    // set the fixed with font and display
    NSMutableAttributedString* text = [[NSMutableAttributedString alloc] initWithAttributedString:s];
    if (text) {
        [text addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, text.length)];
        
        // create a new pane
        NSTextField* field = [[NSTextField alloc] init];
        field.editable = NO;
        field.bezeled = NO;
        field.drawsBackground = NO;
        field.selectable = YES;
        field.allowsEditingTextAttributes = YES;
        //field.attributedStringValue = text;
        field.stringValue = @"fdjsfjsfkfhdkhfdkhfdk";
        NSSize sz = [field.cell cellSizeForBounds:NSMakeRect(0, 0, 10000000, 10000000)];
        field.frame = NSMakeRect(0, 0, sz.width, sz.height);
        [_results addSubview:field];
        [self.results setNeedsDisplay:YES];
    }
}

@end
