# -*- coding: utf-8 -*-
from __future__ import unicode_literals, print_function

from Foundation import NSBundle, NSObject, NSData, NSDictionary, NSSize, NSRect, NSPoint
from Cocoa import NSMutableAttributedString, NSFont, NSRange, NSColor, NSFontManager, NSBoldFontMask, NSTextField, NSView, NSRectFill
from Cocoa import NSFontAttributeName, NSBackgroundColorAttributeName, NSAttributedString
from objc import lookUpClass, YES, NO, IBAction, IBOutlet, signature

import sys
import traceback
import json

# load the root classes
sys.path.append(NSBundle.mainBundle().resourcePath())
from plugin import load_plugins, Plugin, Formatter

# load any python plugins in the users directory
load_plugins()

sys.path.append(NSBundle.mainBundle().builtInPlugInsPath())
sys.path.append('/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/Resources/Python')
import lldb


class Command(lookUpClass('TextPaneController')):
    def initWithConfig_inView_(self, config, view):
        self = super(Command, self).initWithConfig_inView_(config, view)
        self.formatter = Formatter(config, self.updatePane_)
        self.cmd = None
        cmd = config.objectForKey_('cmd')
        cmd = cmd if cmd is not None else ''
        editable = config.objectForKey_('editable')
        if editable is True:
            # editable field
            self.toolbar().setStringValue_(cmd)
            self.makeEditable()
        else:
            # non editable
            self.cmd = cmd
            self.toolbar().setStringValue_(config.objectForKey_('title'))
        return self

    def updated_(self, sender):
        # XXX: prevent setting 's' e.g. command which will recurse on repeat
        self.plugin.refresh(self)

    def update(self, refresh=False):
        cmd = self.cmd if self.cmd is not None else self.toolbar().stringValue()

        res = lldb.SBCommandReturnObject()
        self.plugin.interpreter.HandleCommand(cmd.encode('ascii'), res)
        self.formatter.update(res.GetOutput())


class Console(lookUpClass('ConsolePaneController')):
    def updated_(self, sender):
        self.plugin.refresh(self)

    def update(self, refresh=False):
        print('execute')
        if refresh is False:
            cmd = self.console().stringValue()
            if len(cmd.strip()) > 0:
                res = lldb.SBCommandReturnObject()
                self.plugin.interpreter.HandleCommand(cmd.encode('ascii'), res)
                cmd = '(lldb) %s' % cmd
                print(cmd)
                s = '%s\n%s' % (cmd, res.GetOutput())
                # highlight the command you typed
                attrs = NSDictionary.dictionaryWithObject_forKey_(self.font, NSFontAttributeName);
                text = NSMutableAttributedString.alloc().initWithString_attributes_(s, attrs)
                text.addAttribute_value_range_(NSFontAttributeName, self.bold, NSRange(0, len(cmd)))

                self.updatePane_(text)
                self.console().setStringValue_('')
                scrollview = self.results().superview().superview()
                scrollview.documentView().scrollPoint_(NSPoint(0, 0))

    def addOutput(self, text):
        field = NSTextField.alloc().init()
        field.setEditable_(NO)
        field.setBezeled_(NO)
        # XXX: set font and bold (lldb) cmd line
        field.setDrawsBackground_(NO)
        field.setSelectable_(YES)
        field.setAllowsEditingTextAttributes_(YES)
        field.setStringValue_(text)
        sz = field.cell().cellSizeForBounds_(NSRect(NSPoint(0, 0), NSSize(10000000, 10000000)))
        frame = NSRect(NSPoint(0, 0), sz)
        height = frame.size.height + 1 # gap
        field.setFrame_(frame)
        # XXX: move into above layout
        # adjust the size of results
        sz = self.results.frame().size
        sz.width = max(
            sz.width,
            frame.size.width,
            self.results.superview().frame().size.width
        )
        sz.height += height
        self.results.setFrameSize_(sz)
        # move all the other subviews up
        for view in self.results.subviews():
            frame = view.frame()
            frame.origin.y += height
            view.setFrame_(frame)
        self.results.addSubview_(field)
        # scroll to bottom
        scrollview = self.results.superview().superview()
        scrollview.documentView().scrollPoint_(NSPoint(0, 0))


class LLDBPlugin(Plugin):
    def initWithConfig_(self, config):
        self = super(LLDBPlugin, self).initWithConfig_(config)
        
        # lldb strings must be a ascii
        exe = '/Users/cooper/Library/Developer/Xcode/DerivedData/squall-hhryogohhkstsyclrvqcvcwneaib/Build/Products/Debug/squall.app/Contents/MacOS/squall'.encode('ascii')
        launch_info = lldb.SBLaunchInfo([])
        self.debugger = lldb.SBDebugger.Create()
        self.debugger.SetAsync(True)
        self.interpreter = self.debugger.GetCommandInterpreter()
        self.target = self.debugger.CreateTargetWithFileAndArch(exe, lldb.LLDB_ARCH_DEFAULT)
        bp = self.target.BreakpointCreateByName('main'.encode('ascii'), self.target.GetExecutable().GetFilename())
        error = lldb.SBError()
        launch_info = lldb.SBLaunchInfo(None)
        launch_info.SetExecutableFile(lldb.SBFileSpec(exe), True)
        process = self.target.Launch(launch_info, error)
        return self
    
    @signature('@@:@')
    def archiveConfigOfView_(self, view):
        # we can't archive the class so do it's name
        retval = None
        if view in self.controllers:
            cmd, _ = self.controllers[view]
            tmp = list(cmd)
            tmp[1] = cmd[1].__name__
            # XXX: encode settings
            data = json.dumps(tmp)
            retval = NSData.dataWithBytes_length_(data, len(data))
        return retval

    @signature('v@:@@')
    def unarchiveConfig_intoView_(self, data, view):
        if data is not None:
            s = ''
            # XXX: how do I do this without the loop
            for c in data.bytes():
                s += c
            tmp = json.loads(s)
            cmd = list(tmp)
            cmd[1] = globals()[tmp[1]]
            # XXX: decode settings
            self.create_command_in_view(cmd, view)



##        stdout = sys.stdout
##        s = ''
##        try:
##            sys.stdout = cStringIO.StringIO()
##            c = code.compile_command(self.command.stringValue())
##            exec(c, self.plugin.state)
##            s = sys.stdout.getvalue()#.replace('\\n', '\n')
##        except:
##            s = traceback.format_exc()
##        finally:
##            sys.stdout = stdout
##            self.updateResults(s)