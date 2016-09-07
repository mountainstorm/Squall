from distutils.core import setup
import py2app


setup(
    plugin = ['lldb.squall.py'],
    options=dict(
        py2app=dict(
            includes=['moves', 'six', 'pygments'],
            plist=dict(
                NSPrincipalClass='LLDBPlugin',
                CFBundleIdentifier='uk.co.mountainstorm.squall.lldb'
            )
       )
   )
)
