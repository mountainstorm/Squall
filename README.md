Squall
======


Squall is a simple OSX UI for lldb, which wraps the command line interface and provides a configurable window layout.  It's similar to the 'gui' lldb command or Voltron, but easier to use and you won't find yourself fighting the terminal as much.

The main program provides a configurabe view layout system; MtConfigView; then loads all the plugins it can find and launches the python plugin - lldb.squall.plugin.

This then uses pyObjc to extend various Objc classes and provide feedback.

It's easy to extend and has builtin support for coloring output using pygments.

Download, build, enjoy.

