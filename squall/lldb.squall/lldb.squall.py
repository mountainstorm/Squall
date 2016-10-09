# -*- coding: utf-8 -*-
from __future__ import unicode_literals, print_function

from Cocoa import NSBundle, NSTimer, NSRunLoop, NSDefaultRunLoopMode, NSApp
from objc import lookUpClass, YES, NO, signature

import os
import sys
import traceback
import cStringIO

# load the root classes
sys.path.append(NSBundle.mainBundle().resourcePath())
from plugin import load_plugins, Plugin, Formatter

# load any python plugins in the users directory
load_plugins()

sys.path.append(NSBundle.mainBundle().builtInPlugInsPath())
sys.path.append('/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/Resources/Python')
import lldb


# == Enhancements ==
# 'process interrupt' to break in
# stdin support
# different core modules?
# menu items
# draw anywhere 'terminal' view


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
        result = self.plugin.command(cmd)
        self.formatter.update(result)


class Output(lookUpClass('TextPaneController')):
    def initWithConfig_inView_(self, config, view):
        self = super(Output, self).initWithConfig_inView_(config, view)
        self.formatter = Formatter(config, self.updatePane_)
        self.toolbar().setStringValue_(config.objectForKey_('title'))
        self.text = cStringIO.StringIO()
        return self

    def update(self, refresh=False):
        pass

    def append(self, s):
        self.text.write(s)
        self.formatter.update(self.text.getvalue())


class Console(lookUpClass('ConsolePaneController')):
    def initWithConfig_inView_(self, config, view):
        self = super(Console, self).initWithConfig_inView_(config, view)
        self.formatter = Formatter(config)
        return self

    def updated_(self, sender):
        self.plugin.refresh(self)

    def update(self, refresh=False):
        quit = ['quit', 'q']
        run = ['run', 'r']
        manual = quit + run
        if refresh is False:
            cmd = self.console().stringValue()
            if len(cmd.strip()) == 0:
                cmd = self.getLastCommand()
            if cmd is not None and len(cmd) > 0:
                # now we need to be careful as run and quit both cause the command
                # interpreter to ask the user questions - which I can't see to redirect
                matches = self.get_completions(cmd)
                if len(matches) == 1:
                    cmd = matches[0] # expand the the valid match
                process = None
                target = self.plugin.debugger.GetSelectedTarget()
                if target is not None:
                    process = target.GetProcess()
                if cmd in manual and process is not None and process.is_running:
                    # we're running and cmd will cause an annoying prompt
                    # XXX: some logic - perhaps ask the user
                    self.plugin.command('kill')
                    self.plugin.update_consoles('killing process to restart')

                result = self.plugin.command(cmd)
                self.updatePaneWithPrompt_cmd_result_(self.plugin.debugger.GetPrompt(), cmd, self.formatter.update(result))

    def get_completions(self, cmd):
        retval = []
        matches = lldb.SBStringList()
        self.plugin.interpreter.HandleCompletion(cmd.encode('ascii'), len(cmd), len(cmd), -1, matches)
        for i in range(0, matches.GetSize()):
            retval.append(matches.GetStringAtIndex(i))
        return retval


class LLDBPlugin(Plugin):
    def input_reader_callback(self, input_reader, notification, bytes):
        print(notification, bytes)
        return len(bytes)


    def initWithDocument_andConfig_(self, document, config):
        self = super(LLDBPlugin, self).initWithDocument_andConfig_(document, config)

        # setup debugger
        self.debugger = lldb.SBDebugger.Create()
        self.debugger.SetAsync(True)
        self.debugger.SetTerminalWidth(80) # XXX: should really be set in resize handler

        self.interpreter = self.debugger.GetCommandInterpreter()
        self.listener = self.debugger.GetListener()
        self.listener.StartListeningForEvents(self.interpreter.GetBroadcaster(),
                            lldb.SBCommandInterpreter.eBroadcastBitThreadShouldExit |
                            lldb.SBCommandInterpreter.eBroadcastBitResetPrompt |
                            lldb.SBCommandInterpreter.eBroadcastBitQuitCommandReceived |
                            lldb.SBCommandInterpreter.eBroadcastBitAsynchronousOutputData |
                            lldb.SBCommandInterpreter.eBroadcastBitAsynchronousErrorData
        )
                            
        self.event_timer = NSTimer.timerWithTimeInterval_target_selector_userInfo_repeats_(0.05, self, '_event_handler', None, YES)
        loop = NSRunLoop.currentRunLoop()
        loop.addTimer_forMode_(self.event_timer, NSDefaultRunLoopMode)

        self.first_stop = True
        self.launch_info = None
        return self
    
    def launch(self):
        # SourceInitFileInHomeDirectory
        # SourceInitFileInCurrentWorkingDirectory
        self.update_consoles(self.debugger.GetVersionString())
        if 'onlaunch' in self.config:
            for cmd in self.config['onlaunch']:
                result = self.command(cmd)
                if result is not None:
                    self.update_consoles(result, cmd=cmd)

    def _event_handler(self):
        try:
            self.event_handler()
        except:
            print(traceback.format_exc()) # catch errors and print useful error
            NSApp.terminate_(None)
            
    def event_handler(self):
        found_events = False
        event = lldb.SBEvent()
        while self.listener.GetNextEvent(event):
            found_events = True
            ev_type = event.GetType()
            if lldb.SBProcess.EventIsProcessEvent(event):
                state = lldb.SBProcess.GetStateFromEvent(event)
                if state == lldb.eStateInvalid:
                    # Not a state event
                    self.update_consoles('process event = %s' % (event))
                else:
                    if state == lldb.eStateStopped:
                        self.command('thread info', update=True)
                    elif state == lldb.eStateExited:
                        # suppress errors as if we're exiting it will error
                        self.command('process status', update=True, suppress=True)
                    elif state == lldb.eStateCrashed:
                        self.command('thread info', update=True)
                    elif state == lldb.eStateDetached:
                        self.update_consoles('process %u detached' % (pid))
                    elif state == lldb.eStateRunning:
                        pass # say nothing
                    else:
                        self.update_consoles('process state changed event: %s' % (lldb.SBDebugger.StateAsCString(state)))
            elif event.BroadcasterMatchesRef(self.interpreter.GetBroadcaster()):
                if ev_type == lldb.SBCommandInterpreter.eBroadcastBitQuitCommandReceived:
                    self.document.close()#NSApp.terminate_(None)
                else:
                    print('broadcast', ev_type, lldb.SBEvent.GetCStringFromEvent(event))
            else:
                print('unexpected event', event, ev_type)
            event = lldb.SBEvent()
        # handle stdout/err
        target = self.debugger.GetSelectedTarget()
        if target is not None:
            process = target.GetProcess()
            if process is not None:
                # I tried registering for process events - but we never get them
#                process.broadcaster.AddListener(self.listener,
#                      lldb.SBProcess.eBroadcastBitStateChanged |
#                      lldb.SBProcess.eBroadcastBitInterrupt |
#                      lldb.SBProcess.eBroadcastBitSTDOUT |
#                      lldb.SBProcess.eBroadcastBitSTDERR)
                out = cStringIO.StringIO()
                data = process.GetSTDOUT(4096)
                while data is not None:
                    out.write(data)
                    data = process.GetSTDOUT(4096)
                if len(out.getvalue()) > 0:
                    #sys.stdout.write(out.getvalue())
                    self.update_stdout(out.getvalue())
                out = cStringIO.StringIO()
                data = process.GetSTDERR(4096)
                while data is not None:
                    out.write(data)
                    data = process.GetSTDERR(4096)
                if len(out.getvalue()) > 0:
                    #sys.stdout.write(out.getvalue())
                    self.update_stdout(out.getvalue())
        if found_events is True:
            self.refresh()

    def command(self, cmd, update=False, suppress=False):
        retval = None
        res = lldb.SBCommandReturnObject()
        self.interpreter.HandleCommand(cmd.encode('ascii'), res)
        if res.Succeeded():
            retval = res.GetOutput()
        else:
            if suppress is False:
                retval = res.GetError()
        if update is True and retval is not None:
            self.update_consoles(retval)
        return retval

    def update_consoles(self, result, cmd=None):
        for controller in self.controllers:
            if isinstance(controller, Console):
                # do usual formatting
                if cmd is None:
                    controller.updatePaneWithState_(controller.formatter.update(result))
                else:
                    controller.updatePaneWithPrompt_cmd_result_(self.debugger.GetPrompt(), cmd, controller.formatter.update(result))


    def update_stdout(self, result, inferior=False):
        for pane in self.controllers:
            if isinstance(pane, Console):
                pane.updatePaneWithStdout_(result)
            elif isinstance(pane, Output):
                pane.append(result)

    def shutdown(self):
        self.event_timer.invalidate()
        if self.debugger is not None:
            lldb.SBDebugger.Destroy(self.debugger)
        #lldb.SBDebugger.Terminate() # XXX: if we can this we can't create other instances
