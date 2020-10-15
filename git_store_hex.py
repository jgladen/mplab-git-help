#!/usr/bin/python
__author__ = "Jason Gladen"
__date__ = "$Aug 24, 2020 2:53:30 PM$"


COMMIT_HEX_COMMIT_DIR = ['hex', 'commit']
COMMIT_HEX_EXPERIMENT_DIR = ['hex', 'experimental']


if __name__ == "__main__":
    from subprocess import PIPE, Popen
    from os import path, makedirs
    from time import localtime, struct_time
    from math import floor
    import re
    from shutil import copyfile
    from sys import argv
    from errno import EEXIST

    def usage():

        print('Usage: {} "PATH_TO_HEX_FILE"'.format(argv[0]))
        print(' ----8<----- in Makefile try: --------')
        print('.build-post: .build-impl')
        print('     ./git_store_hex.py "${CND_ARTIFACT_PATH_${CONF}}"')
        print(' ----8<----- in Makefile try: --------')
        quit(-2)

    if len(argv) != 2:
        print(
            '{} requires only a single command-line argument'.format(path.basename(argv[0])))
        usage()

    if not path.exists(argv[1]):
        print('{} can not find file "{}"'.format(
            path.basename(argv[0]), argv[1]))
        usage()

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

    tagVersion = re.sub(r'[<>:",/\\|?*]', '_', tagVersion.strip())
    revision = re.sub(r'[<>:",/\\|?*]', '_', revision.strip())

    safe_file_name = '{}, {}.hex'.format(tagVersion, revision)

    commit_dir = COMMIT_HEX_EXPERIMENT_DIR if len(
        status_mtimes) else COMMIT_HEX_COMMIT_DIR

    hex_file = path.join(working_folder_root, *commit_dir, safe_file_name)

    if not path.exists(path.dirname(hex_file)):
        try:
            makedirs(path.dirname(hex_file))
        except OSError as exc:  # Guard against race condition
            if exc.errno != EEXIST:
                raise

    copyfile(argv[1], hex_file)
    print('**** Saved copy of hex as: "{}"'.format(hex_file))
