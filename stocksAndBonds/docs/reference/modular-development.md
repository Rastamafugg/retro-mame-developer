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
- If a procedure is loaded from a module that contains multiple procedures (referred to as a "merged module"), you will need to explicitly remove these procedures from memory afterwards, even if they were not references by the procedure that you called.  This can be done with the Unlink call. For example: `SHELL "ex UnLink myThirdProc"`. *NOTE:* SHELL loads a DOS shell to run the command in quotes. `ex` tells the shell to exit immediately.

### Basic09 Example of Loading and Unloading Modular Procedures

This example demonstrates 3 types of modules:
- A single procedure module
- A single-entry module where the entry procedure calls other procedures within the module
- A multiple-entry module, with several procedures that can all be called independently.

#### Single Procedure Module

```basic09
PROCEDURE singleProc
    PRINT "Single procedure executed."
END
```

#### Multiple Procedure Module

```basic09
PROCEDURE multiProc1
    PRINT "Multi procedure 1 executed."
    RUN multiProc2
END

PROCEDURE multiProc2
    PRINT "Multi procedure 2 executed."
END
```

#### Independently Called Procedure Module

*NOTE:* To be able to call all procedures within a module, you need to begin with the additional step of loading the module into memory. One way to do this is the command `SHELL "ex LOAD moduleFileName"`.

```basic09
PROCEDURE indepProc1
    PRINT "Independent procedure 1 executed."
END

PROCEDURE indepProc2
    PRINT "Independent procedure 2 executed."
END

PROCEDURE indepProc3
    PRINT "Independent procedure 3 executed."
END
```

#### Main Test Module

```basic09
PROCEDURE moduleTest
    DIM procName:STRING

    (* Test single procedure module *)
    procName = "singleProc"
    PRINT "Loading and calling " + procName
    RUN procName
    PRINT "Killing " + procName
    KILL procName
    PRINT ""

    (* Test multiple procedure module *)
    procName = "multiProc1"
    PRINT "Loading and calling " + procName + " (which calls " + "multiProc2)"
    RUN procName
    PRINT "Killing " + procName
    KILL procName
    procName = "multiProc2"
    PRINT "Killing " + procName
    SHELL "ex UnLink " + procName
    PRINT ""

    procName = "indepProc1"
    PRINT "Loading independent procedure module " + procName
    SHELL "ex LOAD " + procName
    (* Test independent procedures module *)
    PRINT "Loading and calling " + procName
    RUN procName
    procName = "indepProc2"
    PRINT "Loading and calling " + procName
    RUN procName
    procName = "indepProc3"
    PRINT "Loading and calling " + procName
    RUN procName
    PRINT ""
    procName = "indepProc1"
    PRINT "Killing " + procName
    KILL procName
    procName = "indepProc2"
    PRINT "Killing " + procName
    KILL procName
    procName = "indepProc3"
    PRINT "Killing " + procName
    KILL procName
    PRINT ""
    PRINT "Test completed."
END
```

#### Preparing the modules to be run in NitrOS9

These are the Basic09 system commands that you need to run for each module before you can run the test. 

##### Single Procedure Module

```
LOAD /path/to/singleProc.b09
PACK
KILL singleProc \ ! Only needed if you are continuing to run Basic09 after packing the module
```

##### Multiple Procedure Module

```
LOAD /path/to/multiProc1.b09
PACK* > multiProc1
KILL multiProc1,multiProc2 \ ! Only needed if you are continuing to run Basic09 after packing the module
```

##### Independently Called Procedure Module

```
LOAD /path/to/indepProc1.b09
PACK* > indepProc1
KILL indepProc1,indepProc2,indepProc3 \ ! Only needed if you are continuing to run Basic09 after packing the module
```

##### Main Test Module

```
LOAD /path/to/moduleTest.b09
PACK
KILL moduleTest \ ! Only needed if you are continuing to run Basic09 after packing the module
```

##### Making the Modules Executable

Basic09 will create the module files in the executable directory, but the executable flag **will not** be set.  You will need to run the following commands to turn this flag on (Change file path if `/d0/cmds/` is not your executable folder).

```
ATTR /d0/cmds/singleProc perm e
ATTR /d0/cmds/multiProc1 perm e
ATTR /d0/cmds/indepProc1 perm e
ATTR /d0/cmds/moduleTest perm e
```

#### Running the Test

Once everything is setup correctly, you will just need to run the following command at the SHELL: `moduleTest`

#### SysCall Alternative to Loading/Unloading Modules

You can also load and unload modules using SysCall to make direct NitrOS-9 System Calls.

##### Loading Modules

In the loadModule procedure below, we first call F$Link, to see if the module is already in memory, then call F$Load to load the module from the executable folder, if not found.

##### Unloading Modules

In the unloadModule procedure below, we call F$UnLink if the module header address is passed in (returned as the U register value from both F$Link and F$Load calls), otherwise the passed-in module name is used in the system call F$UnLoad.

**NOTE:** For some reason in my testing, I had to both F$UnLoad and F$UnLink the first module in my test program.  After that, it was sufficient to simply call F$UnLoad on each procedure in a target module/merged module to have the module removed from memory.

```
PROCEDURE loadModule
(* ================================================== *)
(* PROCEDURE: loadModule                              *)
(* PURPOSE:   Load a named module into memory.       *)
(*            Tries F$Link first (already in memory),*)
(*            then F$Load to bring in from disk.     *)
(* PARAMS:    modName  - module name to load         *)
(*            isLoaded - TRUE if successfully loaded *)
(* NOTE:      Requires SysCall machine-lang module.  *)
(* ================================================== *)
TYPE Register = cc,a,b,dp:BYTE; x,y,u:INTEGER
PARAM modName:STRING[32]
PARAM hdrAddr:INTEGER
PARAM isLoaded:BOOLEAN
DIM regs:Register
DIM callCode:BYTE
DIM nameAddr:INTEGER
DIM iCC:INTEGER

ON ERROR GOTO 900

isLoaded := FALSE
nameAddr := ADDR(modName)

callCode := $00 \ ! F$Link: try if already in memory
regs.a := 0
regs.x := nameAddr
RUN SysCall(callCode, regs)

iCC := regs.cc
hdrAddr := regs.u \ ! Capture header address for potential unload test
IF LAND(iCC, 1) = 0 THEN
  PRINT modName; " linked (was already loaded)"
  isLoaded := TRUE
ELSE
  callCode := $01 \ ! F$Load: load module from disk
  regs.a := 0
  regs.x := nameAddr
  RUN SysCall(callCode, regs)
  iCC := regs.cc
  hdrAddr := regs.u \ ! Capture header address for potential unload test
  IF LAND(iCC, 1) = 0 THEN
    PRINT modName; " loaded from disk"
    isLoaded := TRUE
  ELSE
    PRINT "Failed to load "; modName; " (err: "; regs.b; ")"
  ENDIF
ENDIF
END

900 \ ! Error handler
PRINT "loadModule error ("; ERR; ")"
ERROR(ERR)
END


PROCEDURE unloadModule
(* ================================================== *)
(* PROCEDURE: unloadModule                            *)
(* PURPOSE:   Unload a named module from memory.     *)
(*            If hdrAddr is nonzero, uses F$UnLink   *)
(*            by header address. Otherwise uses      *)
(*            F$UnLoad by module name.               *)
(* PARAMS:    modName  - module name (for reporting) *)
(*            hdrAddr  - module header addr (0=none) *)
(*            unloaded - TRUE if successfully removed*)
(* NOTE:      Requires SysCall machine-lang module.  *)
(* ================================================== *)
TYPE Register = cc,a,b,dp:BYTE; x,y,u:INTEGER
PARAM modName:STRING[32]
PARAM hdrAddr:INTEGER
PARAM unloaded:BOOLEAN
DIM regs:Register
DIM callCode:BYTE
DIM nameAddr:INTEGER
DIM iCC:INTEGER

ON ERROR GOTO 900

unloaded := FALSE

IF hdrAddr <> 0 THEN
  callCode := $02 \ ! F$UnLink: unlink by header address
  regs.u := hdrAddr
  RUN SysCall(callCode, regs)
  iCC := regs.cc
  IF LAND(iCC, 1) = 0 THEN
    PRINT modName; " unlinked by header"
    unloaded := TRUE
  ELSE
    PRINT "Failed to unlink "; modName; " by hdr (err: "; regs.b; ")"
  ENDIF
ELSE
  nameAddr := ADDR(modName)
  callCode := $1D \ ! F$UnLoad: unload by name
  regs.a := 0
  regs.x := nameAddr
  RUN SysCall(callCode, regs)
  iCC := regs.cc
  IF LAND(iCC, 1) = 0 THEN
    PRINT modName; " unlinked by name"
    unloaded := TRUE
  ELSE
    PRINT "Failed to unlink "; modName; " by name (err: "; regs.b; ")"
  ENDIF
ENDIF
END

900 \ ! Error handler
PRINT "unloadModule error ("; ERR; ")"
ERROR(ERR)
END
```