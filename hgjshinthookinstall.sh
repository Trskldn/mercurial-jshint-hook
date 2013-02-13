#! /bin/bash
hsName="[hooks]"
basedir=~/project/babylon/
hgrc=$basedir/.hg/hgrc

if [[ ! -z "$@" ]]; then
  basedir=$1
fi
if [[ ! -d "$basedir" ]]; then
    echo "Babylon directory doesnt find, specify it as input parameter"
	exit 1;
fi


hsExists=$( grep -Fx "$hsName" $hgrc )
if [ -z "$hsExists" ]; then
	echo "add [hooks] section to hgrc"
	echo -e "$hsName\n" >> $hgrc
fi

echo "Add jshint precommit hook hook to $hgrc"
sed /jshintcheck/d -i  $hgrc
sed '/\[hooks\]/a precommit.jshintcheck = python:~/project/babylon/.hg/jshintcheck.py:check' -i $hgrc

sudo npm install --global jshint
sudo apt-get install python

cat > $basedir/.hg/jshintcheck.py << "EOF"
import subprocess,os,re
import commands
import os.path
from mercurial import ui
from random import randrange
from time import time

checked_exts = [".js"]
ignored_exts = []
ignored_files = []
ignored_patterns = ["middleware"]
ctx = None
globUi = ""

def is_relevant(file):
        import re

        if file in ignored_files:
            globUi.debug('checkfiles: ignoring %s (explicit ignore)\n' % file)
            return False

        if any(map(lambda e:file.endswith(e), ignored_exts)):
            globUi.debug('checkfiles: ignoring %s (ignored extension)\n' % file)
            return False

        if not any(map(lambda e:file.endswith(e), checked_exts)):
            globUi.debug('checkfiles: ignoring %s (non-checked extension)\n' % file)
            return False

        if any(map(lambda e:re.search(e, file) is not None, ignored_patterns)):
            globUi.debug('checkfiles: ignoring %s (ignored pattern)\n' % file)
            return False

        try:
            fctx = ctx[file]
        except LookupError:
            globUi.debug('checkfiles: skipping %s (deleted)\n' % file)
            return False

        if fctx == None:
            globUi.debug('checkfiles: skipping %s (deleted)\n' % file)
            return False

        try:
            data = fctx.data()
        except:
            globUi.debug('checkfiles: skipping %s (deleted)\n' % file)
            return False

        if '\0' in fctx.data():
            globUi.debug('checkfiles: skipping %s (binary)\n' % file)
            return False

        return True

def check(ui, repo, hooktype, **kwargs):
    global globUi
    globUi = ui
    global ctx
    ctx = repo[None]
    files = ctx.files()
    error = ""
    temp_file = ""

    for curFile in filter(is_relevant, files):
        out = ""
        ui.debug('checkfiles: checking %s ...\n' % curFile)
        try:
            out = subprocess.check_output('jshint --config=%s/.hg/.jshintrc %s  | grep -E "Extra comma|Missing semicolon"' % (repo.root, os.path.join(repo.root, curFile)), stderr=subprocess.STDOUT, shell=True)
        except subprocess.CalledProcessError, e:
            ui.debug(e.output)
        error += out

    if error != "":
        ui.warn("******************************************************\n" + error + "******************************************************\n")
        return 1
    return 0
EOF

cat > $basedir/.hg/.jshintrc << "EOF"
{
	"maxerr":    1000000
}

EOF

cat <<EOF

jsHint mercurial hook installed! 

EOF
