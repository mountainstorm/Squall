//
//  TextController.h
//  squall
//
//  Created by cooper on 05/09/2016.
//  Copyright © 2016 mountainstorm. All rights reserved.
//

#import "TextController.h"

@implementation TextController

- (id)initWithConfig:(NSDictionary*)config inView:(MtConfigView*)view
{
    self = [super initWithConfig:config inView:view];
    [[NSBundle mainBundle] loadNibNamed:@"TextPane" owner:self topLevelObjects:nil];

    // disable wordwrap
    NSSize massive = NSMakeSize(10000000, 10000000);
    [_results setMaxSize:massive];
    [_results setHorizontallyResizable:YES];
    [_results.textContainer setWidthTracksTextView:NO];
    [_results.textContainer setContainerSize:massive];

    // add support for label rather than textfield
    return self;
}

- (void)makeLabel
{
    NSTextField* toolbar = (NSTextField*) self.toolbar;
    toolbar.editable = NO;
    toolbar.selectable = NO;
    toolbar.font = [NSFont labelFontOfSize:self.font.pointSize];
    NSRect frame = toolbar.frame;
    frame.origin.y -= 3;
    toolbar.frame = frame;
}

- (IBAction)updated:(id)sender
{
    // should be overridden in subclass
}

//- (void)executeAsRefresh:(BOOL)refresh
//{
//    NSTextField* field = (NSTextField*) self.toolbar;
//    [self updateResults:field.stringValue];
//}

- (void)updateResults:(NSAttributedString*)s
{
    NSMutableAttributedString* text = [[NSMutableAttributedString alloc] initWithAttributedString:s];
    if (text) {
        [text addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, text.length)];
        [_results.textStorage setAttributedString:text];
    }
}

@end
