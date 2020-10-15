#!/usr/bin/python
__author__ = "Jason Gladen"
__date__ = "$Aug 20, 2020 12:35:30 PM$"

TEMPLATE = """// DO NOT EDIT Generated in version-update.py
// see: https://github.com/jgladen/mplab-git-extensions-helpers

#include "version.h"
const char __attribute__((section("version"), space(prog))) GIT_VERSION[32] = "{0:s}";
const char __attribute__((section("version"), space(prog))) GIT_REVISION[32] = "{1:s}";
"""

VERSION_FILE_PATH = ['version.c']

if __name__ == "__main__":
    from subprocess import PIPE, Popen
    from os import path
    from time import localtime, struct_time
    from math import floor
    import re

    #    from collections import Counter

    def exec_git_line(command):
        pipe = Popen(['git'] + command, stdout=PIPE)
        ret = pipe.stdout.read().rstrip().decode('utf-8')
        pipe.stdout.close()
        return ret

    def exec_git_many(command):
        pipe = Popen(['git'] + command, stdout=PIPE)
        return [x.rstrip().decode('utf-8)') for x in pipe.stdout]

    working_folder_root = exec_git_line(['rev-parse', '--show-cdup'])
    version_output_file = path.join(working_folder_root, *VERSION_FILE_PATH)

    working_folder_status = exec_git_many(['status', '--porcelain', '-u', '.'])

    print('working_folder_root: "{}"'.format(working_folder_root))

    status_paths = [working_folder_root + line[3:]
                    for line in working_folder_status]

    # using localtime as working folder is in localtime and result is ends up in a git-ignored
    status_mtimes = [localtime(path.getmtime(filepath))
                     for filepath in status_paths if path.exists(filepath)]

    latest_hex = None

    if len(status_mtimes):
        latest_mtime = max(status_mtimes)

        latest_struct = struct_time(latest_mtime)

        # paking time into 4 hexidecimal digits MMMn WHERE:
        #   MMM is hex minute of day
        #   n is 1/16 fraction of a minute
        #   noon -> 2D00, 23:59:59 -> 59FF
        latest_hex = "{:03X}{:01X}".format(
            latest_struct.tm_hour*60 + latest_struct.tm_min,
            floor(latest_struct.tm_sec/3.75))

        print('Latest Last Modified: {:02d}:{:02d}:{:02d} -> {} of {} files from: git status'.format(
            latest_struct.tm_hour, latest_struct.tm_min, latest_struct.tm_sec,
            latest_hex,
            len(status_mtimes)))

    versionCmd = ['describe']
    versionCmd.append('--tags')
    versionCmd.append('--long')
    versionCmd.append('--dirty=_' + (latest_hex or 'X'))
    versionCmd.append('--abbrev=7')
    versionCmd.append('--always')

    versionDesc = exec_git_line(versionCmd)

    reVersion = re.compile(
        r'^(.*?)(?:-0)?(?:-g?)?([0-9a-f]{7}(?:_(?:X|[0-9A-F]{4}))?)')

    match = reVersion.match(versionDesc)
    if match == None:
        raise Exception('could not parse version "{}" from: git {}'.format(
            versionDesc, ' '.join(versionCmd)))

    # print(versionDesc)

    tagVersion = match.group(1) or 'No Version'
    revPrefix = 'X:' if len(status_paths) else 'rev:'
    revision = revPrefix + match.group(2)

    print('version: "{}"'.format(tagVersion))
    print('rev: "{}"'.format(revision))

    revised_content = TEMPLATE.format(tagVersion, revision)

    current_content = None

    if path.exists(version_output_file):
        file = open(version_output_file, 'r')
        current_content = file.read()
        file.close()
    
    if revised_content == current_content:
        print('Version file is up to date: {}'.format(version_output_file))
    else:
        print('Updating version file: {}'.format(version_output_file))
        file = open(version_output_file, 'w')
        file.write(revised_content)
        file.close()
