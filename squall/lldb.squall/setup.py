from distutils.core import setup
import py2app

#
# compile this in the virtual env
# > virtualenv venv
# > source venv/bin/activate
# > pip install moves
# > pip install six
# > pip install hg+https://bitbucket.org/ronaldoussoren/py2app/
# > python setup.py py2app
# > python setup.py py2app -A
#
# We build the real version first then the dev version (-A) as theres a bug
# in the dev versions generation of __boot__
#

setup(
    plugin = ['lldb.squall.py'],
    data_files=['command.xib', 'console.xib'],
    options=dict(
        py2app=dict(
            includes=['moves'],
            plist=dict(
                NSPrincipalClass='LLDBPlugin',
                CFBundleIdentifier='uk.co.mountainstorm.squall.lldb'
            )
       )
   )
)
