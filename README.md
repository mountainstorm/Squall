Squall
======


Squall is a simple OSX UI for lldb, which wraps the command line interface and provides a configurable window layout.  It's similar to the 'gui' lldb command or Voltron, but easier to use and you won't find yourself fighting the terminal as much.

The aim is to provide an easily hackable framework on which more advanced tools/views can be easily built - without the inconvinience of terminal sessions, incorrect line heights etc.

The main program provides a configurable view layout system; MtConfigView; then loads all the plugins it can find and launches a python plugin to glue everything together.  This then uses pyObjc to extend various Objc classes and save writing loads of code.

It's easy to extend and has builtin support for coloring output using pygments.

Download, build, enjoy.


Launching
---------

To support working with the Squall from the command line a tool called osasquall is included.  This can be used to open a document in Squall (much like using open 'project.squall') but also apply launch specific customizations e.g. override the initial command.

osasquall takes an optional project file parameter and reads JSON configuration from stdin.  Once the EOF is reached it instructs Squall to launch and open either the specified project or the default document - with the customizations applied.


How it works
------------

### Configuration ###

On startup Squal loads a config json file from multiple places.  Each subsequent file overwrites any top level dictionary keys with their value; thus providing a level of customization.

The files loaded, if present, are as follows:

1. /Applications/Squall.app/Contents/Resources/config.json
2. /Library/Application Support/Squall/config.json
3. ~/Library/Application Support/Squall/config.json
4. <project>.squall
5. <launch specific customizations>

This allows you to change a setting for all users, a specific user or a specific project.

If you run without a project the configured state will be saved into the user specific config file


### Extensions ###

There are two types of extensions, bundles (typically nibs and objc code) and plugins (python glue).  When the Squall starts up it loads all the bundles in the following directories.  

1. /Applications/Squall.app/Contents/Resources/PlugIns/
2. /Library/Application Support/Squall/PlugIns/
3. ~/Library/Application Support/Squall/PlugIns/

Once complete the `plugin` field of the config will be searched for in the same directories, and loaded; with an instance of it's PrimaryClass being created to manage the project.

### Panes ###

At this point, if you have a new project, the project window is created and can be customized.  Alternativly if an existing project is loaded the `layout`, stored in the configuration, will be loaded into the view.

Either way the pane menu (gear menu) will consist of a set of layout options and a selection of panes which can be created.

When a pane is create (or loaded from the configuration) an instance of the `class` field is instanciated and a `initWithConfig:inView:` message is sent.  The config is a combination of the following - from the config file (resulting from the earlier load procedure):

1. the 'global' dictionary is use
2. the pane dictionary is added from the `panes` array (matched on the `title` field)
3. the pane dictionary from the `layout` is added (matched on the `title` field)

When saving a layout the pane controller is sent an `archiveSettings` message.  It should only archive settings into the layout that have changed or we're added and the 'title' field used to find the base config.

Finally the plugin is sent am `archiveSettings` message and the output stored in the `project` key

### Plugin ###

Once the windows layout has been created the plugin is launched by calling `launch`.  When the window is close `shutdown` is called.

