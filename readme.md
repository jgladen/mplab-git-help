# Tool overview

- mplab-git-help is a pair of tools used with Microchip's (tm) MPLAB X toolchain.
    - FreshenVersion pre-build, create/updates a "version" file to embed version label into the hex file
    - StoreHex automates the archival of hex files copies based on the same version details embedded in the firmware.
- Most builds are stored in folder "hex" by their build identifier in a sub folder for commit or expermental
- Builds with dirty working folders are marked as expermental and suffixed with an encoded time of day
 
## FreshenVersion

- How can I embed automatically embed a version in firmware?

A box cannot contain itself. Git does version control very well and provides a rich system for identifying versions. But any changes to the source code that are committed to a git repository change the commit hash.

The commit hash is the key identification for tracking versions. Therefore, the source code that labels the version in the firmware can't be committed/checked-in and must be ignored using ```.gitignore```.

Great care must be taken to avoid side effects of version label changes. A label change must not affect the structure or function of the firmware. The label must be padded so as to take up the same amount of memory. There should be no compression or any branching instructions based on the contents of the label. These simple rules avoid issues where the commit might change the behavior of the firmware.

FreshenVersion gererates a label based on the current status of the Working folder and the repository status. The "Version" is based on the latest git "tag" and the number of commits since the tag. If there is no tag, "No Version" is used instead. The "Revision" is hash of the latest commit. If the working folder is dirty the "Revision" is marked "X" for experimental suffixed with a timecode.

+ FreshenVersion supports templates (see Templates below)

## StoreHex
  StoreHex copies the build hex file from the dist folder.
  StoreHex will copy the hex file into ```hex/commit``` if the working folder is clean and ```hex/experimental``` otherwise.
  The new file will be named based on the same label used by FreshenVersion (see above).

  StoreHex will skip copy action in ```Debug``` builds, as those are highly coupled to the IDE and limit the external use of the hex file. 
  StoreHex relies on the evironmental variable ```TYPE_IMAGE``` that MPLAB X sets during a ```Debug``` build

## Setup

- FreshenVersion choreographs the version label in the source code and the version control system durring the build process
- StoreHex preforms the copy after the build completes
- Both tools report actions, status, and errors in the ``Build Project`` window on MPLAB X.
- Prerequisite: Mplab X project must use git version control (see: https://git-scm.com)
- At least one commit. Commiting ```.gitignore``` is a good idea on the first commit.

1. The file mplab-git-help.jar must be copied into the project folder. This file is a self-contained java archive and includes JGit for parsing and reviewing the Status of the Git Repository and Working folder

2. Update the Makefile:
  - FreshenVersion uses the pre-build target
  - StoreHex uses the post-build target

The makefile file can be found on the project tree under “Important Files”. Near line 56 the target rules look like this:

```makefile
.build-pre:
# Add your pre 'build' code here...

.build-post: .build-impl
# Add your post 'build' code here...

```

Modify the rules to look like this:

```makefile
.build-pre:
	${MP_JAVA_PATH}java -cp mplab-git-help.jar FreshenVersion
# Add your pre 'build' code here...

.build-post: .build-impl
	${MP_JAVA_PATH}java -cp mplab-git-help.jar StoreHex "${CND_ARTIFACT_PATH_${CONF}}"
# Add your post 'build' code here...

```

* Hey! If you typed it, and have auto-correct eyes like I do sometimes? Double check CND_ARTIFACT... (Charlie November Delta UNDERSCORE)  

Makefiles have some idiosyncrasies. The ```Tab``` indent is super important. I recommend using MPLAB's  
auto-indent feature by inserting a new-line at the end of the target lines ```.build-pre:``` and ```.build-post: .build-impl```

3. In Mplab X, **Build Project** or press (F11)
     + this verifies build process is working
     + and generates `version.c` (if you don't want that see Templates below)

  You should see something like this in the **Output (Build,Load)** window:

```
...
java -cp mplab-git-help.jar FreshenVersion
describe: 7060fe9
version: "No version"
rev: "X:7060fe9_4613"
writing new: version.c
...


...
java -cp mplab-git-help.jar StoreHex "dist/default/production/PROJECT_NAME.production.hex"
mplab-git-help StoreHex: TYPE_IMAGE: "null"
describe: 7060fe9
source:dist/default/production/PROJECT_NAME.production.hex
dest:hex/experimental/No version, 7060fe9_4613.hex
...
```

4. Add Existing ```version.c```
Right-click the ```Source Files``` group on the project tab and ```Add Existing Item...``` add the ```version.c``` as a relative path

5. Create ```version.h```
Right-click the ```Header Files``` select ```New``` and ```C Header File...```
    
    * If you don't see ```C Header File...``` select ```Other...``` and filter ```C Header``` to find it and click ```Next >```

Enter ```version``` for the ```File Name:``` 

```c
/* 
 * File:   version.h
 * Author: Your Name Here
 *
 * Created on August 29, 2022, 2:48 PM
 */

#ifndef VERSION_H
#define	VERSION_H

extern const char __attribute__((section("version"))) GIT_VERSION[32];
extern const char __attribute__((section("version"))) GIT_REVISION[32];

#endif	/* VERSION_H */
```

please note: 

* extern is used in include files to "declare" the global variable
* the "size" of the const char array must match the version.c (default: 32, can be changed in the Makefile/Template)

6.  Update `.gitignore` to ignore `/version.c` file and the ```hex/``` folder

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

# excluded mplab-git-help
hex/
/version.c
```

7. Commit and build the project again and the ```rev``` should match the commit hash and not be marked as expermental "X:..."

8. Review the contents of ```version.c``` and the ```hex``` folder



## Template
  The default output file is ```version.h```

  The built-in template is:
```c
// %{warning}
// File: %{file}
// template: %{source}
// see: https://github.com/jgladen/mplab-git-help
                   
#include "version.h"
                   
const char __attribute__((section("version"))) GIT_VERSION[32] = "%{version}";
const char __attribute__((section("version"))) GIT_REVISION[32] = "%{revision}";
// %{warning}                  
```

### Template Intepolations
The template file is copied verbatium to the out location with two exceptions:

1. The first line if it starts with a ```#!``` (shebang)
2. interpolations of the form %{REPLACEMENT_VARIABLE...}

Interpolations begin with ```%{```  and end with ```}``` 
interpolations may be any of these:

* warning

  ```*** DO NOT EDIT *** Generated by mplab-git-help.jar FreshenVersion```

* version or V 
  
  ```No version``` or the git tag followed by an option commit count since tag

* revision or R

  The first 7 letters of the git hash or for expermental X:GITHASH_YYYY where YYYY is the encoded time of day

* source

  If FreshenVersion used a file of the form ```FILENAME.c.git-help-template``` the source template file would be ```FILENAME.c.git-help-template```

* file

  If FreshenVersion used a file of the form ```FILENAME.c.git-help-template``` the file would be ```FILENAME.c``` and the output would be directed to ```FILENAME.c``` if the content of the file does not match. (see build windows on MPLAB X)

* line

  The source line number in the template. Used if you want the click-thru error link in the build window to drop you on the line of template. (offset for shebang line if present).

  Example template line for c ```#line``` directive using ```%{line}``` and ```%{source}``` interpolations:

  ```c
  #line %{line} "%{source}"
  ```

### Template Intepolations Slices

String Intepolations support Slices of the form:

```%{REPLACEMENT_VARIABLE[index]}```

or

```%{REPLACEMENT_VARIABLE[start:stop]}```

Index, start, and stop are optional and may extend beyond the end of the string. Negative values are counted from the end of the string. Padding is used to fill space beyond the string (padding defaults to space)



## Command Line


Freshen Version supports command-line switches. For example if you rewrite the ```.build-pre:``` target in the makfile from:


```makefile
.build-pre:
	${MP_JAVA_PATH}java -cp mplab-git-help.jar FreshenVersion
```

to:

```makefile
.build-pre:
	${MP_JAVA_PATH}java -cp mplab-git-help.jar FreshenVersion -help
```

the build will "fail" with the message of:

```
usage: CLITester
 -?,--help             print this message
 -c,--center           center version/revision with padding
 -f,--force            force output file without checking if needed.
 -o,--out <arg>        output file: defaults to version.c
 -p,--pad <arg>        pad character or chacter escape: " " or "\0"
 -R,--revision <arg>   padded width of revision
 -r,--right            right justify version/revision with padding
 -V,--version <arg>    padded width of version
 -z,--shebang          stitch together the shebang exploded file name
```

Or using the example from above with ```FILENAME.c.git-help-template```

```makefile
.build-pre:
	${MP_JAVA_PATH}java -cp mplab-git-help.jar -center -R 16 -V 20 FILENAME.c.git-help-template
```

Would generate a ```FILENAME.c``` based on a template ```FILENAME.c.git-help-template``` and 
the version and revision would be centered.
Version centered and padded to 20 bytes and Revision centered and padded to 16 bytes 

## Examples Templates

version.asm.git-help-template
```asm
; %{warning}
; file: %{file}
; template: %{source}
    
    #include <xc.inc>
    PSECT version,abs,class=data,pure,noexec

; major: %{V[-4:3]}
; minor: %{V[4:6]}
; sub: %{V[7:9]}

#line %{line} "%{source}"
org 0x7f00

; "%{version}"
 db '%{V[0]}'
 db '%{V[1]}'
 db '%{V[2]}'
 db '%{V[3]}'
 db '%{V[4]}'
 db '%{V[5]}'
 db '%{V[6]}'
 db '%{V[7]}'
 db '%{V[8]}'
 db '%{V[9]}'
 db '%{V[10]}'
 db '%{V[11]}'
 db '%{V[12]}'
 db '%{V[13]}'
 db '%{V[14]}'
 db '%{V[15]}'
 
 org 0x7f20

; "%{revision}"
 db '%{R[0]}'
 db '%{R[1]}'
 db '%{R[2]}'
 db '%{R[3]}'
 db '%{R[4]}'
 db '%{R[5]}'
 db '%{R[6]}'
 db '%{R[7]}'
 db '%{R[8]}'
 db '%{R[9]}'
 db '%{R[10]}'
 db '%{R[11]}'
 db '%{R[12]}'
 db '%{R[13]}'
 db '%{R[14]}'
 db '%{R[15]}'

; %{warning}

```


### crazy-shebang-example.c

Makefile
```makefile
.build-pre:
	./crazy-shebang-example.c.git-help-template
```

crazy-shebang-example.c.git-help-template
```c
#!java -cp mplab-git-help.jar FreshenVersion -V 32 -R 32 -center -z 
// %{warning}

const char v1[33] = "%{version}"; 
const char v2[33] = "%{V}"; 

const char v3[32] = {
  '%{V[0]}','%{V[1]}','%{V[2]}','%{V[3]}','%{V[4]}','%{V[5]}','%{V[6]}','%{V[7]}',
  '%{V[8]}','%{V[9]}','%{V[10]}','%{V[11]}','%{V[12]}','%{V[13]}','%{V[14]}','%{V[15]}',
  '%{V[16]}','%{V[17]}','%{V[18]}','%{V[19]}','%{V[20]}','%{V[21]}','%{V[22]}','%{V[23]}',
  '%{V[24]}','%{V[25]}','%{V[26]}','%{V[27]}','%{V[28]}','%{V[29]}','%{V[30]}','\0'
};

const char r1[17] = "%{R}";
const char r2[9]  = "%{R[0:8]}";
const char r3[9]  =         "%{R[8:16]}";

const char r4[16] = {
  '%{R[0]}','%{R[1]}','%{R[2]}','%{R[3]}','%{R[4]}','%{R[5]}','%{R[6]}','%{R[7]}',
  '%{R[8]}','%{R[9]}','%{R[10]}','%{R[11]}','%{R[12]}','%{R[13]}','%{R[14]}','%{R[15]}',
  
};

// %{warning}
```

