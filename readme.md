
#Tool overview
- Used with MPLAB 8 and MPLAB X
- Helpers to manage Microchip IDE projects as a git repository with git Extensions on windows
- Auto generates a string for embedding the git Hash into the hex file
- All builds are stored in folder "hex" by their build identifier
- Builds on uncommitted sources are marked as X with an encoded time of day  

# For C projects on MPLAB X #

Modify the .build-pre and .build-post rules in the Makefile to look like this...

    .build-pre:    
            cscript.exe /nologo git_version.vbs
    # Add your pre 'build' code here...

    .build-post: .build-impl
            cscript.exe /nologo git_store_hex.vbs "${CND_ARTIFACT_PATH_${CONF}}"
    # Add your post 'build' code here...

... and copy these two script files to the same folder:

	git_version.vbs
	git_store_hex.vbs


  Add this to your .gitignore:

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
    !*.hex
    /version.c
    hex/





# For ASM projects on MPLAB 8 #


Set Prebuild step to:

	cscript /nologo git_ver_asm.vbs

or for retlw instead of db use this instead...

	cscript /nologo git_ver_asm_retlw.vbs

Set Post build step to:

	cscript /nologo git_store_hex.vbs REPLACE_THIS_WITH_TARGET_FILENAME.HEX

!!! Don't for get to replace REPLACE_THIS_WITH_TARGET_FILENAME output hex file name

... and copy these two script files to the same folder:

	git_ver_asm_retlw.vbs
	git_store_hex.vbs


## Add these to .gitignore: ##

	*.cof
	*.err
	*.hex
	*.lst
	*.map
	*.mcs
	*.o
	version.inc
