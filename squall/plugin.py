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
        self.controllers = []
        return self

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
    def __init__(self, config, sel):
        self.sel = selector(sel, signature='v@:@')
        self.lexer = config.objectForKey_('lexer')
        if self.lexer is not None:
            if isinstance(self.lexer, pyobjc_unicode):
                self.lexer = getattr(pygments.lexers, self.lexer)
            elif self.lexer is False:
                self.lexer = None # don't lex
        self.style = config.objectForKey_('style')

    def update(self, s, fmt=None):
        # find format
        if fmt is None:
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
                rtf = highlight(s, lexer(), RtfFormatter(style=self.style)).encode('utf-8')
                data = NSData.dataWithBytes_length_(rtf, len(rtf))
                self.update(data)
            else:
                # fallback - the string unformatted
                self.sel(NSAttributedString.alloc().initWithString_(s))
        elif fmt == 'rtf':
            a = NSAttributedString.alloc().initWithRTF_documentAttributes_(s, None)
            self.sel(a[0])
        elif fmt == 'NSAttributedString':
            self.self(s)
        else:
            raise ValueError('unsupported format; %s' % fmt)


def load_plugins():
    dn = NSBundle.mainBundle().objectForInfoDictionaryKey_('CFBundleExecutable')
    system_paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask | NSLocalDomainMask, YES);
    for search_path in system_paths:
        plugins = os.path.join(search_path, dn, 'PlugIns')
        if os.path.isdir(plugins):
            load_plugins_in_path(plugins)
    load_plugins_in_path(NSBundle.mainBundle().builtInPlugInsPath())


def load_plugins_in_path(root):
    added = False
    for fn in os.listdir(root):
        path = os.path.join(root, fn)
        if os.path.isfile(os.path.join(path, '__init__.py')):
            if added is False:
                added = True
                sys.path.append(root)
            __import__(os.path.basename(path))

