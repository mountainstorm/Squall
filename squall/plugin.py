# -*- coding: utf-8 -*-
from __future__ import unicode_literals, print_function

from Cocoa import NSAttributedString, NSData, NSObject, NSBundle
from Cocoa import NSSearchPathForDirectoriesInDomains, NSApplicationSupportDirectory, NSUserDomainMask, NSLocalDomainMask
from objc import selector, pyobjc_unicode, YES

import os
import sys

from pygments import highlight
from pygments.lexers import guess_lexer
import pygments.lexers
import pygments.util
from pygments.formatters import RtfFormatter


class Plugin(NSObject):
    def initWithConfig_(self, config):
        self = super(Plugin, self).init()
        self.config = config
        self.controllers = []
        return self
    
    def launchWithArguments_(self, args):
        pass
    
    def archiveConfig(self):
        return self.config

    def addedController_(self, controller):
        controller.plugin = self
        self.controllers.append(controller)
        controller.update()

    def removingController_(self, controller):
        self.controllers.remove(controller)
    
    def refresh(self, first=None):
        if first is not None:
            first.update()
        for controller in self.controllers:
            if first is None or controller is not first:
                controller.update(refresh=True)


class Formatter(object):
    def __init__(self, config, sel=None):
        self.sel = None
        if sel is not None:
            self.sel = selector(sel, signature='v@:@')
        self.lexer = config.objectForKey_('lexer')
        if self.lexer is not None:
            if isinstance(self.lexer, pyobjc_unicode):
                self.lexer = getattr(pygments.lexers, self.lexer)
                if self.lexer is None:
                    # perhaps its a private one
                    parts = self.lexer.split('.')
                    mod = __import__(parts[:-2])
                    self.lexer = getattr(mod, parts[-1])
            elif self.lexer is False:
                self.lexer = None # don't lex
        self.style = config.objectForKey_('style')
        self.font = config.objectForKey_('font')
        self.fontsize = config.objectForKey_('fontsize')

    def update(self, s):
        retval = None
        # find format
        fmt = 'string'
        if isinstance(s, NSAttributedString):
            fmt = 'NSAttributedString'
        elif isinstance(s, NSData):
            fmt = 'rtf'
        # we only do highlighting if string is supplied
        if fmt == 'string':
            # format the output
            try:
                lexer = guess_lexer(s) if self.lexer is True else self.lexer
            except pygments.util.ClassNotFound:
                lexer = None
            if lexer is not None:
                rtf = highlight(
                    s,
                    lexer(),
                    RtfFormatter(
                        style=self.style,
                        fontface=self.font,
                        fontsize=self.fontsize*2 # *2 as it wants half points
                    )
                ).encode('utf-8')
                data = NSData.dataWithBytes_length_(rtf, len(rtf))
                retval = self.update(data)
            else:
                # fallback - the string unformatted
                retval = NSAttributedString.alloc().initWithString_(s)
                if self.sel is not None:
                    self.sel(retval)
        elif fmt == 'rtf':
            a = NSAttributedString.alloc().initWithRTF_documentAttributes_(s, None)
            retval = a[0]
            if self.sel is not None:
                self.sel(a[0])
        elif fmt == 'NSAttributedString':
            retval = s
            if self.sel is not None:
                self.sel(s)
        else:
            raise ValueError('unsupported format; %s' % fmt)
        return retval


def load_plugins():
    dn = NSBundle.mainBundle().objectForInfoDictionaryKey_('CFBundleExecutable')
    system_paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask | NSLocalDomainMask, YES);
    for search_path in system_paths:
        plugins = os.path.join(search_path, dn, 'PlugIns')
        if os.path.isdir(plugins):
            load_plugins_in_path(plugins)
    load_plugins_in_path(NSBundle.mainBundle().builtInPlugInsPath())


def load_plugins_in_path(root):
    sys.path.append(root)
    for fn in os.listdir(root):
        _, ext = os.path.splitext(fn)
        path = os.path.join(root, fn)
        if fn == '.py' or os.path.isfile(os.path.join(path, '__init__.py')):
            __import__(os.path.basename(path))

