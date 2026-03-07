# Modular Programming with Basic09

## Introduction

The Basic09 development environment in NitrOS9 EOU has limitations on how much code can be loaded into memory.  This limit is around 40K of memory.  Once your program exceeds this limit, you will need to shift towards modular coding, using the `PACK` command.

## The PACK Command 

*PACK [\<procname> {,\<procname>}] [> \<pathlist>]*

*PACK\* [\<pathlist>]*

PACK causes an extra compiler pass on the procedure(s) specified which removes names, line numbers, non-executable statements, etc. The result is a smaller, faster procedure(s) that CANNOT be edited or debugged but can be executed by Basic09 or by the Basic09 run-time-only program called "RunB". If a pathlist is not given, the name of the first procedure in the list will be used as a default pathname. The procedure is written to the file/device specified in OS-9 memory module format suitable for loading in ROM or RAM OUTSIDE the workspace. THE RESULTING FILE CANNOT BE LOADED INTO THE WORKSPACE LATER ON, so you should always perform a regular SAVE before PACKing a procedure!

Basic09 will automatically load the packed procedure when you try to run it later on. Here is an example sequence that demonstrates packing a procedure:

| Example   | Description                                 |
|-----------|---------------------------------------------|
| PACK sort | packs procedure "sort" and creates a file   |
| KILL sort | kills procedure inside the workspace        |
| RUN sort  | run (sort will be loaded outside workspace) |
| KILL sort | done; we delete "sort" from outside memory  |

The last step (kill) dées not have to be done immediately if you will be using the procedure again later, but you should kill it whenever you are done so its memory can be used for other purposes. Examples follow.

Examples:

```
  PACK procl,proc2 >packed.programs
  PACK* packedfile
```

## Developing and Working with Modules

There are some things to note, once you decide to start developing with modules.
- Once you pack your code, you can no longer run it from the Basic09 developing environment. From now on, you will be running your code directly from the NitrOS9 command line.
- Running `PACK` creates modules in the current executable directory, unlike saving your Basic09 code, which writes to the current data directory.  See the NitrOS9 documentation for more details about these two types of directory references.
- While you can change the executable directory, it is recommended that you don't.  This folder, by default, holds all NitrOS9 executables, so this is where you want these files to be located.
- `PACK` will create these module files, but they will not be executable by default. You will need to run the `attr` command on your new module files and turn on the executable flag for the user. For example: `attr /dd/cmds/mymodule perm e`
- Running your new modularized procedure is as simple as calling it from the command line. Parameters passed to your procedure MUST be strings, with spaces between the procedure name and the first parameter, as well as between each parameter accepted by the procedure. For example: `mymodule param1 param2`
- Modules can be called from other modules, allowing you to add and remove library calls as you need them.  The Basic09 syntax for calling a procedure in this manner is that same as procedure-to-procedure calls in the Basic09 environment. For example: `RUN myOtherProc(param1, "stringLiteral", 2)`
- Ensure that you `KILL` any modular procedure loaded in this way after you no longer need it, in order to free up memory.  For example: `KILL myOtherProc`
- TO TEST: If a procedure is loaded from a module that contains multiple procedures, you will need to explicitly remove these procedures from memory afterwards, even if they were not references by the procedure that you called.  This can be done with the Unlink call. For example: `SHELL "ex UnLink myThirdProc"`. *NOTE:* SHELL loads a DOS shell to run the command in quotes. `ex` tells the shell to exit immediately.

### Basic09 Example of Loading and Unloading Modular Procedures

```basic09
       (* Load part 1 *)
       part:="udecode"
       RUN part(filePath,er,tpVars,verbose,execOff,descOff,symTabOff,dataOff,dataDir,modName)
       KILL part
       SHELL "ex UnLink ulSort"
       IF er>0 THEN 100
 
       (* Load part 2 *)
       part:="udefVars"
       RUN part(filePath,er,tpVars,verbose,modSize,execOff,descOff,symTabOff,dataDir)
       KILL part
       SHELL "ex UnLink ufSort"
       SHELL "ex UnLink uvSort"
       IF er>0 THEN 100
 
       (* Load part 3 *)
       part:="usymTabVal"
       RUN part(filePath,er,verbose,modSize,symTabOff,dataDir)
       KILL part
       IF er>0 THEN 100
 
       (* Load part 4 *)
       part:="ubuildSrc"
       RUN part(filePath,outPath,er,maxData,outExists,verbose,descOff,symTabOff,dataDir,outFile)
       KILL part
       SHELL "ex UnLink udsSort"
       IF er>0 THEN 100
 
       (* Load part 5 *)
       part:="uinstruction"
       RUN part(filePath,outPath,er,outExists,verbose,execOff,descOff,dataOff,dataDir)
       KILL part
       SHELL "ex UnLink uDRPN"
       SHELL "ex UnLink uhex$"
       IF er>0 THEN 100
```