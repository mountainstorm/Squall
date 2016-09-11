Squall
======


Squall is a simple OSX UI for lldb, which wraps the command line interface and provides a configurable window layout.  It's similar to the 'gui' lldb command or Voltron, but easier to use and you won't find yourself fighting the terminal as much.

The main program provides a configurabe view layout system; MtConfigView; then loads all the plugins it can find and launches the python plugin - lldb.squall.plugin.

This then uses pyObjc to extend various Objc classes and provide feedback.

It's easy to extend and has builtin support for coloring output using pygments.

Download, build, enjoy.


How it works
------------

### Configuration ###

#### Customization ####

On startup Squal loads a config json file from multiple places.  Each subsequent file overwrites any top level dictionary keys with their value; thus providing a level of customization.

The files loaded, if present, are as follows:

1. /Applications/Squall.app/Contents/Resources/config.json
2. /Library/Application Support/Squall/config.json
3. ~/Library/Application Support/Squall/config.json
4. <project>.squall

This allows you to change a setting for all users, a specific user or a specific project.

If you run without a project the configured state will be saved into the user specific config file



