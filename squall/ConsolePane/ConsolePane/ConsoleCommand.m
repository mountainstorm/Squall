//
//  ConsoleCommand.m
//  ConsolePane
//
//  Created by cooper on 07/09/2016.
//  Copyright © 2016 cooper. All rights reserved.
//

#import "ConsoleCommand.h"

@implementation ConsoleCommand

@synthesize history = _history;

- (void)awakeFromNib
{
    _history = [NSMutableArray array];
    _historyIdx = -1;
}

- (NSSize)intrinsicContentSize
{
    NSRect bounds = NSMakeRect(0, 0, self.frame.size.width, 10000000);
    return [self.cell cellSizeForBounds:bounds];
}

- (void)textDidChange:(NSNotification*)notification
{
    [super textDidChange:notification];
    [self validateEditing];
    NSSize cellSize = [self intrinsicContentSize];
    NSRect frame = self.frame;
    if (frame.size.height != cellSize.height) {
        // XXX: 5 is padding or something?
        float delta = cellSize.height - (frame.size.height - 5);
        frame.size.height = cellSize.height + 5.0;
        self.frame = frame;
        // but we also need to move the scroll view next to us
        for (NSView* view in self.superview.subviews) {
            if (view != self) {
                frame = view.frame;
                frame.origin.y += delta;
                frame.size.height -= delta;
                view.frame = frame;
                [view setNeedsDisplay:YES];
            }
        }
    }
}

- (void)cancelOperation:(id)sender
{
    _historyIdx = -1;
    self.stringValue = @"";
}

- (BOOL)textView:(NSTextField*)field doCommandBySelector:(SEL)sel
{
    BOOL retval = NO;
    if (sel == @selector(moveUp:)) {
        long cnt = _history.count;
        if (_historyIdx < cnt-1) {
            _historyIdx += 1;
            self.stringValue = _history[_historyIdx];
            [self.currentEditor setSelectedRange:NSMakeRange(self.stringValue.length, 0)];
        }
        retval = YES; // handled don't pass it on
    } else if (sel == @selector(moveDown:)) {
        if (_historyIdx > 0 && _historyIdx < _history.count) {
            _historyIdx -= 1;
            self.stringValue = _history[_historyIdx];
            [self.currentEditor setSelectedRange:NSMakeRange(self.stringValue.length, 0)];
        } else {
            _historyIdx = -1;
            self.stringValue = @"";
        }
        retval = YES; // handled don't pass it on
    } else if (sel == @selector(insertNewline:)) {
        NSString* cmd = self.stringValue;
        NSString* cmds = [cmd stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (cmds.length > 0) {
            [_history insertObject:cmd atIndex:0];
            _historyIdx = -1;
        }
        // let the default handler run
    }
    return retval;
}

@end
