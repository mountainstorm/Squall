# -*- coding: utf-8 -*-
from __future__ import unicode_literals, print_function
from Foundation import NSObject, NSBundle, NSData, NSDictionary, NSSize
from Cocoa import NSMutableAttributedString, NSFont, NSRange, NSColor, NSFontManager, NSBoldFontMask
from Cocoa import NSFontAttributeName, NSBackgroundColorAttributeName
from objc import nil, YES, NO, IBAction, IBOutlet, signature

import re
import sys
import traceback
import cStringIO
import code


class CommandController(NSObject):
    xib = 'command'
    
    command = IBOutlet()
    contentView = IBOutlet()
    results = IBOutlet()

    @IBAction
    def updatedCommand_(self, sender):
        self.plugin.refresh()
  
    def init(self):
        # outlets aren't fixed up here - so do everything useful in setup
        return super(CommandController, self).init()

    def load_into_view(self, view, title, args):
        if len(args) > 0:
            self.command.cell().setPlaceholderString_(args[0])
            self.command.setStringValue_(args[1])
        elif title != '↻':
            # set command to title if it's not a empty repeat or has paceholder
            self.command.setStringValue_(title)

        # disable wordwrap
        massive = NSSize(10000000, 10000000)
        self.results.setMaxSize_(massive)
        self.results.setHorizontallyResizable_(YES)
        self.results.textContainer().setWidthTracksTextView_(NO)
        self.results.textContainer().setContainerSize_(massive)

        # set the size of the views and add then to the view
        self.command.setFrame_(view.toolbar().frame())
        view.toolbar().addSubview_(self.command)
        
        self.contentView.setFrame_(view.content().frame())
        view.content().addSubview_(self.contentView)
        
    def updateResults(self, s):
        # XXX: load some output
        font = NSFont.userFixedPitchFontOfSize_(11.0)
        fontManager = NSFontManager.sharedFontManager()
        bold = fontManager.convertFont_toHaveTrait_(font, NSBoldFontMask)
        
        attrs = NSDictionary.dictionaryWithObject_forKey_(font, NSFontAttributeName);
        text = NSMutableAttributedString.alloc().initWithString_attributes_(s, attrs)
        if text is not None:
            self.highlight(text, r'(\(.*?\))', NSFontAttributeName, bold)
            self.results.textStorage().setAttributedString_(text)

    def highlight(self, text, regex, attr, value):
        for m in re.finditer(regex, text.string().UTF8String()):
            for i in range(0, len(m.groups())):
                #text.addAttribute_value_range_(NSBackgroundColorAttributeName, NSColor.redColor(), NSRange(5, 10))
                text.addAttribute_value_range_(attr, value, NSRange(m.start(i), m.end(i)-m.start(i)))

    def execute(self):
        stdout = sys.stdout
        s = ''
        try:
            sys.stdout = cStringIO.StringIO()
            c = code.compile_command(self.command.stringValue())
            exec(c, self.plugin.state)
            s = sys.stdout.getvalue().replace('\\n', '\n')
        except:
            s = traceback.format_exc()
        finally:
            sys.stdout = stdout
            self.updateResults(s)


class LLDBPlugin(NSObject):
    def init(self):
        self = super(LLDBPlugin, self).init()
        self.bundle = NSBundle.bundleWithIdentifier_('uk.co.mountainstorm.squall.lldb')
        self.controllers = {}
        self.commands = [
            # title, class, initWithParams params
            ('(lldb)', CommandController), # XXX different controller
            ('↻', CommandController),
            ('reg r', CommandController),
            ('p/x', CommandController, 'p/x <address>', '0000000000000000')
        ]
        self.state = {}
        return self
    
    @signature('I@:@')
    def numberOfItemsInMenu_(self, menu):
        return len(self.commands)
    
    @signature('c@:@@ic')
    def menu_updateItem_atIndex_shouldCancel_(self, menu, item, idx, cancel):
        item.setTitle_(self.commands[idx][0])
        item.setTag_(idx)
        return True

    @signature('v@:@@')
    def createItem_inView_(self, item, view):
        cmd = self.commands[item.tag()]
        
        controller = cmd[1].alloc().init()
        controller.plugin = self
        self.controllers[view] = controller
        self.bundle.loadNibNamed_owner_topLevelObjects_(cmd[1].xib, controller, None)
        controller.load_into_view(view, cmd[0], cmd[2:])

    @signature('v@:@')
    def removingView_(self, view):
        del self.controllers[view]

    @signature('@@:@')
    def archiveConfigOfView_(self, view):
        print('archiveConfigOfView_')
        return None

    @signature('v@:@@')
    def unarchiveConfig_intoView_(self, data, view):
        print('unarchiveConfig_intoView_')
        pass

    def refresh(self):
        for controller in self.controllers.values():
            controller.execute()
