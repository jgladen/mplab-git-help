Used with MPLAB 8 and MPLAB X
Manage Microchip IDE projects as a git reposotory with git Extensions


******* For C projects on MPLAB X ******

Add theses lines to the Makefile ...


# ====== START COPY HERE =======8<----paste between build and clean


.build-pre:
# Add your pre 'build' code here...
	cscript.exe /nologo git_version.vbs

.build-post: .build-impl
# Add your post 'build' code here...
	cscript.exe /nologo git_store_hex.vbs "${CND_ARTIFACT_PATH_${CONF}}"

# ------ STOP COPY HERE -------->8====paste between build and clean

... and copy the two script files to the sm git_version.vbs and git_store_hex.vbs


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







******* For ASM projects on MPLAB 8 *********


Set Prebuild step to: 
cscript /nologo git_ver_asm_retlw.vbs

Set Post build step to:
cscript /nologo git_store_hex.vbs REPLACE_THIS_WITH_TARGET_FILENAME.HEX

!!! Don't for get to replace REPLACE_THIS_WITH_TARGET_FILENAME output hex file name

and copy the two script files to the sm git_ver_asm_retlw.vbs and git_store_hex.vbs

Add these to .gitignore:
*.cof
*.err
*.hex
*.lst
*.map
*.mcs
*.o
version.inc
