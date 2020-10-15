
# Tool overview
- Used with MPLAB X
- Helpers to manage Microchip IDE projects as a git repository with git
- Auto generates a string for embedding the git Hash into the hex file
- All builds are stored in folder "hex" by their build identifier
- Builds on uncommitted sources are marked as X with an encoded time of day  

# Installation

1. update file: Makefile
``` Makefile
.build-pre:
	./git_version_update.py

.build-post: .build-impl
     ./git_store_hex.py "${CND_ARTIFACT_PATH_${CONF}}"
```

2. update .gitignore
``` .gitignore
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

  

