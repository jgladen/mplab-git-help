# Tool overview

- mplab-git-help automates specific git tasks for Mplab X projects
  - FreshenVersion pre-build, create/updates a "version" file to embed version label into produced firmware
  - StoreHex copies post-build automates the archival of hex files copies based on the same version details embedded in the firmware.

## FreshenVersion

- How can I embed automatically embed a version in firmware?

A box cannot contain itself. Git does version control well and provides a rich system for identifying versions. But any changes to the source code that are committed to a git repository change the commit hash.

The commit hash is the key identification for tracking versions. Therefore, the source code that labels the version in the firmware can't be committed/checked in and must be ignored. Great care must be taken to avoid side effects of version label changes. A label change must not affect the structure or function of the firmware. The label must be padded so as to take up the same amount of memory. There should be no compression or any branching instructions based on the contents of the label.

### FreshenVersion Setup

- FreshenVersion choreographs the version label in the source code and the version control system durring the build process
- Prerequisite: Mplab X project must use Git version control
- At least one Commit. Commiting `.gitignore` is a good idea on the first commit

1. The file mplab-git-help-v1.jar must be copied into the project folder. This file is a self-contained java archive and includes JGit for parsing and reviewing the Status of the Git Repository and Working folder
2. the pre-build target in the makefile must be updated. The makefile file can be found on the project tree under “Important Files”. Near line 56 the target looks like this:

```makefile
.build-pre:
# Add your pre 'build' code here...
```

make it look like this (The tab indent is important)

```makefile
.build-pre:
	${MP_JAVA_PATH}java -cp mplab-git-help-v1.jar FreshenVersion
# Add your pre 'build' code here...
```

+ FreshenVersion supports templates (see Templates below)

3. In Mplab X, **Build Project** or press (F11)
     +  verifies build process is working
     + generates `version.c`

  The **Output (Build,Load)** windows:

```
...
java -cp mplab-git-help-v1.jar FreshenVersion
describe: 7060fe9
version: "No version"
rev: "X:7060fe9_4613"
writing new: version.c
...
```

4.

5.  update `.gitignore` to ignore `version.c`

.build-post: .build-impl

# Add your post 'build' code here...

4.
5.

An "ignored" version file will label the hex file during the build process. Paramount

## FreshenVersion

- mplab-git-help is a pair of tools used with Microchip's (tm) MPLAB X toolchain.
- G
  automate manage Microchip IDE projects as a git repository with git
- Auto generates a string for embedding the git Hash into the hex file
- All builds are stored in folder "hex" by their build identifier
- Builds on uncommitted sources are marked as X with an encoded time of day

# Installation

1. copy mplab-git-help-v1.jar to project folder

2. update file: Makefile

```Makefile
.build-pre:
	./git_version_update.py

.build-post: .build-impl
     ./git_store_hex.py "${CND_ARTIFACT_PATH_${CONF}}"
```

2. update .gitignore

```.gitignore
# general build and cruft

*.d
*.pre
*.p1
*.lst
*.sym
*.obj
*.o
*.sdb
*.obj.dmp
html/
nbproject/private/
nbproject/Package-*.bash
build/
nbbuild/
dist/
nbdist/
nbactions.xml
nb-configuration.xml
funclist
nbproject/Makefile-*
disassembly/
*.map

# exclude helper generated output
hex/
/version.c
```

3. copy these files to the project folder:

```
git_version_update.py
git_store_hex.py
```
