# -*- coding: utf-8 -*-
from __future__ import unicode_literals, print_function
from Foundation import NSObject, NSBundle, NSData, NSDictionary, NSSize, NSRect, NSPoint
from Cocoa import NSMutableAttributedString, NSFont, NSRange, NSColor, NSFontManager, NSBoldFontMask, NSTextField, NSView, NSRectFill
from Cocoa import NSFontAttributeName, NSBackgroundColorAttributeName
from objc import nil, YES, NO, IBAction, IBOutlet, signature, selector

import re
import sys
import traceback
import cStringIO
import code
import json

sys.path.append('/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/Resources/Python')
import lldb


class CommandController(NSObject):
    xib = 'command'
    
    command = IBOutlet()
    contentView = IBOutlet()
    results = IBOutlet()

    @IBAction
    def updatedCommand_(self, sender):
        # XXX: prevent setting 's' e.g. command which will recurse on repeat
        self.plugin.refresh(self)
  
    def init(self):
        # outlets aren't fixed up here - so do everything useful in setup
        return super(CommandController, self).init()

    def load_into_view(self, view, title, args):
        if title != '↻':
            # set command to title if it's not a empty repeat or has paceholder
            self.command.setStringValue_(title)

        if len(args) > 0:
            if args[0] is not None:
                self.command.cell().setPlaceholderString_(args[0])
            if len(args) > 1 and args[1] is not None:
                self.command.setStringValue_(args[1])

        # disable wordwrap
        massive = NSSize(10000000, 10000000)
        self.results.setMaxSize_(massive)
        self.results.setHorizontallyResizable_(YES)
        self.results.textContainer().setWidthTracksTextView_(NO)
        self.results.textContainer().setContainerSize_(massive)
        
        # setup fonts
        self.font = NSFont.userFixedPitchFontOfSize_(11.0)
        fontManager = NSFontManager.sharedFontManager()
        self.bold = fontManager.convertFont_toHaveTrait_(self.font, NSBoldFontMask)

        # set the size of the views and add then to the view
        self.command.setFrame_(view.toolbar().frame())
        view.toolbar().addSubview_(self.command)
        
        self.contentView.setFrame_(view.content().frame())
        view.content().addSubview_(self.contentView)
        
    def updateResults(self, s):
        attrs = NSDictionary.dictionaryWithObject_forKey_(self.font, NSFontAttributeName);
        text = NSMutableAttributedString.alloc().initWithString_attributes_(s, attrs)
        if text is not None:
            self.results.textStorage().setAttributedString_(text)

#    def highlight(self, text, regex, attr, value):
#        for m in re.finditer(regex, text.string().UTF8String()):
#            for i in range(0, len(m.groups())):
#                text.addAttribute_value_range_(attr, value, NSRange(m.start(i), m.end(i)-m.start(i)))

    def execute(self, refresh=False):
#        stdout = sys.stdout
#        s = ''
#        try:
#            sys.stdout = cStringIO.StringIO()
#            c = code.compile_command(self.command.stringValue())
#            exec(c, self.plugin.state)
#            s = sys.stdout.getvalue()#.replace('\\n', '\n')
#        except:
#            s = traceback.format_exc()
#        finally:
#            sys.stdout = stdout
#            self.updateResults(s)
        res = lldb.SBCommandReturnObject()
        self.plugin.interpreter.HandleCommand(self.command.stringValue().encode('ascii'), res)
        out = res.GetOutput()
        self.updateResults(out)

#    def reg_r(self, text):
#        #text.addAttribute_value_range_(NSBackgroundColorAttributeName, NSColor.redColor(), NSRange(5, 3))
#        self.highlight(text, r'^(.*?)\n', NSFontAttributeName, self.bold)
#        self.highlight(text, r'(.*?=)', NSFontAttributeName, self.bold)


class ConsoleCommand(NSTextField):
    def awakeFromNib(self):
        self.history = []
        self.historyIdx = -1
    
    def intrinsicContentSize(self):
        sz = self.cell().cellSizeForBounds_(NSRect(NSPoint(0, 0), NSSize(self.frame().size.width, 10000000)))
        return sz

    # to invalidate the layout on text change, else it wouldn't grow by changing the text
    def textDidChange_(self, notification):
        super(ConsoleCommand, self).textDidChange_(notification)
        self.validateEditing()
        cellSize = self.intrinsicContentSize()
        frame = self.frame()
        if frame.size.height != cellSize.height:
            # XXX: 5 is padding or something?
            delta = cellSize.height - (frame.size.height - 5)
            frame.size.height = cellSize.height + 5
            self.setFrame_(frame)
            # but we also need to move the scroll view next to us
            for view in self.superview().subviews():
                if view is not self:
                    frame = view.frame()
                    frame.origin.y += delta
                    frame.size.height -= delta
                    view.setFrame_(frame)
                    view.setNeedsDisplay_(YES)

    @signature(NSTextField.textView_doCommandBySelector_.signature)
    def textView_doCommandBySelector_(self, field, sel):
        if str(sel) == 'moveUp:':
            if self.historyIdx < len(self.history)-1:
                self.historyIdx += 1
                self.setStringValue_(self.history[self.historyIdx])
                self.currentEditor().setSelectedRange_(NSRange(len(self.stringValue()), 0))
            return YES # handled don't pass it on
        elif str(sel) == 'moveDown:':
            if self.historyIdx > 0 and self.historyIdx < len(self.history):
                self.historyIdx -= 1
                self.setStringValue_(self.history[self.historyIdx])
                self.currentEditor().setSelectedRange_(NSRange(len(self.stringValue()), 0))
            else:
                self.historyIdx = -1
                self.setStringValue_('')
            return YES # handled don't pass it on
        elif str(sel) == 'insertNewline:':
            cmd = self.stringValue()
            if len(cmd.strip()) > 0:
                self.history.insert(0, cmd)
                self.historyIdx = -1
            # let the default handler run
        elif str(sel) == 'noop:':
            # ctrl-c etc
            self.historyIdx = -1
            # XXX: handle break
        return NO


class ConsoleResults(NSView):
    def drawRect_(self, dirtyRect):
        super(ConsoleResults, self).drawRect_(dirtyRect)
        # we're going to draw the color of the divider then over draw the result bg color
        NSColor.colorWithCalibratedWhite_alpha_(239.0 / 255.0, 1).set()
        NSRectFill(self.frame())
        
        NSColor.whiteColor().set()
        for view in self.subviews():
            frame = view.frame()
            frame.size.width = max(
                frame.size.width,
                self.frame().size.width,
                self.superview().frame().size.width,
            )
            NSRectFill(frame)

#    def resizeSubviewsWithOldSize_(self, _):
#        self.layout()
#        print('resizeSubviewsWithOldSize_')
#        # go through subview in order and fix their location and size
#        # so the most recent window is at the bottom
#        y = 0
#        for view in reversed(self.subviews()):
#            frame = view.frame()
#            frame.origin.y = y
#            view.setFrame_(frame)
#            y += frame.size.height + 1 # tiny line between each pane


class ConsoleController(NSObject):
    xib = 'console'
    
    title = IBOutlet()
    console = IBOutlet()
    contentView = IBOutlet()
    results = IBOutlet()
    
    @IBAction
    def updatedCommand_(self, sender):
        self.plugin.refresh(self)
    
    def init(self):
        # outlets aren't fixed up here - so do everything useful in setup
        self = super(ConsoleController, self).init()
        self.font = NSFont.userFixedPitchFontOfSize_(11.0)
        fontManager = NSFontManager.sharedFontManager()
        self.bold = fontManager.convertFont_toHaveTrait_(self.font, NSBoldFontMask)
        return self
    
    def load_into_view(self, view, title, args):
        # set the size of the views and add then to the view
        self.title.setFrame_(view.toolbar().frame())
        view.toolbar().addSubview_(self.title)
        
        self.contentView.setFrame_(view.content().frame())
        view.content().addSubview_(self.contentView)

    def execute(self, refresh=False):
        if refresh is False:
            cmd = self.console.stringValue()
            if len(cmd.strip()) > 0:
                res = lldb.SBCommandReturnObject()
                self.plugin.interpreter.HandleCommand(cmd.encode('ascii'), res)
                cmd = '(lldb) %s' % cmd
                s = '%s\n%s' % (cmd, res.GetOutput())
                # highlight the command you typed
                attrs = NSDictionary.dictionaryWithObject_forKey_(self.font, NSFontAttributeName);
                text = NSMutableAttributedString.alloc().initWithString_attributes_(s, attrs)
                text.addAttribute_value_range_(NSFontAttributeName, self.bold, NSRange(0, len(cmd)))

                self.addOutput(text)
                self.console.setStringValue_('')

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


class LLDBPlugin(NSObject):
    def init(self):
        self = super(LLDBPlugin, self).init()
        self.bundle = NSBundle.bundleWithIdentifier_('uk.co.mountainstorm.squall.lldb')
        self.controllers = {}
        self.commands = [
            # title, class, initWithParams params
            ('(lldb)', ConsoleController),
            ('↻', CommandController),
            ('reg read', CommandController),
            ('disas -f', CommandController),
            ('bt', CommandController),
            ('f', CommandController),
            ('frame variable', CommandController),
            ('memory read', CommandController, 'm r -c 0x100 <address>', 'm r -c 0x100 $rax'),
        ]
        #self.state = {}
        
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
        self.create_command_in_view(cmd, view)

    @signature('v@:@')
    def removingView_(self, view):
        if view in self.controllers:
            del self.controllers[view]

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

    def create_command_in_view(self, cmd, view):
        controller = cmd[1].alloc().init()
        controller.plugin = self
        self.controllers[view] = (cmd, controller)
        self.bundle.loadNibNamed_owner_topLevelObjects_(cmd[1].xib, controller, None)
        controller.load_into_view(view, cmd[0], cmd[2:])
        controller.execute()

    def refresh(self, first=None):
        if first is not None:
            first.execute()
        for _, controller in self.controllers.values():
            if first is None or controller is not first:
                controller.execute(refresh=True)
