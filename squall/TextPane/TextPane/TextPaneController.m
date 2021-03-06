//
//  TextPaneController.h
//  Squall
//
//  Created by cooper on 05/09/2016.
//  Copyright © 2016 mountainstorm. All rights reserved.
//

#import "TextPaneController.h"

@implementation TextPaneController

@synthesize toolbar = _toolbar;
@synthesize content = _content;

@synthesize font = _font;
@synthesize config = _config;


- (id)initWithConfig:(NSDictionary*)config inView:(MtConfigView*)view
{
    self = [super init];
    self.config = [NSMutableDictionary dictionaryWithDictionary:config];
    [[NSBundle bundleForClass:[TextPaneController class]] loadNibNamed:@"TextPane" owner:self topLevelObjects:nil];

    // prevent selection
    _toolbar.selectable = NO;

    // disable wordwrap
    NSSize massive = NSMakeSize(10000000, 10000000);
    [_results setMaxSize:massive];
    [_results setHorizontallyResizable:YES];
    [_results.textContainer setWidthTracksTextView:NO];
    [_results.textContainer setContainerSize:massive];

    // load basic fonts
    _font = [NSFont userFixedPitchFontOfSize:11.0];
    return self;
}

- (NSDictionary*)archiveSettings
{
    return @{ @"title": self.config[@"title"] };
}

- (void)makeEditable
{
    _toolbar.editable = YES;
    _toolbar.selectable = YES;
    _toolbar.font = _font;
}

- (IBAction)updated:(id)sender
{
    // should be overridden in subclass
}

- (void)updatePane:(NSAttributedString*)s
{
    // set the fixed with font and display
    [_results.textStorage setAttributedString:s];
}

@end
