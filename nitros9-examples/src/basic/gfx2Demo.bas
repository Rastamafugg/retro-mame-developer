PROCEDURE gfx2Demo

    REM *** BASIC09 GFX2() Function Demonstration ***
    REM This script demonstrates various graphics and system functions
    REM available through the GFX2 module in BASIC09.
    REM
    REM Prerequisites:
    REM 1. A NitrOS-9 environment (e.g., NitrOS-9/EOU).
    REM 2. The GFX2 module should be accessible (usually pre-loaded or in CMDS).
    REM 3. Standard fonts (Stdfonts) should be merged with the window if you
    REM    intend to use custom fonts (e.g., 'merge sys/stdfonts > /w1').
    REM    For this demo, we assume they are available.

    REM --- Global Variables ---
    DIM PATH:INTEGER        REM Path number for the graphics window
    DIM RESPONSE:STRING[1]  REM For user input (single character)
    DIM X, Y, X1, Y1:INTEGER REM General coordinates
    DIM COLOR_VAL, BG_COLOR, BORDER_COLOR:INTEGER REM Color values
    DIM I, J, K:INTEGER     REM Loop counters
    DIM TEMP_STR:STRING[32] REM Temporary string for text display
    DIM ID_NUM:INTEGER      REM For process ID

    REM --- Initial Setup: Create and Select a Graphics Window ---
    REM We'll use a high-resolution window (Format 7: 640x200 pixels, 4 colors)
    REM This assumes /W1 is available and can be initialized.
    REM If you get an error, ensure /W1 is not in use or try /W2, /W3 etc.
    REM The 'SHELL "INIZ /W1"' command makes the window persistent.
    SHELL "INIZ /W1"
    OPEN #PATH,"/W1":WRITE REM Open a path to the window

    REM Define the window: RUN GFX2(path,"DWSET",format,xcor,ycor,width,height,fg,bg,border)
    REM Format 7: 640x200 pixels, 4 colors (0,1,2,3)
    REM xcor,ycor: 0,0 (top-left corner of screen)
    REM width,height: 80 columns, 25 rows (text character dimensions for the window)
    REM foreground: 3 (Yellow), background: 0 (Black), border: 2 (Green)
    RUN GFX2(PATH,"DWSET",7,0,0,80,25,3,0,2)

    RUN GFX2(PATH,"SELECT") REM Make this window the active display
    RUN GFX2(PATH,"CUROFF") REM Turn off the text cursor for cleaner graphics
    RUN GFX2(PATH,"CLEAR")  REM Clear the window to its background color

    REM --- Section 1: Window Functions ---
    REM Display a title for the section
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"--- Section 1: Window Functions ---"
    PRINT #PATH,"(Press any key to continue after each step)"
    RUN GFX2(PATH,"CRRTN")
    RUN GFX2(PATH,"CRRTN")

    REM 1.1. WINFO: Returns window information
    DIM W_FORMAT, W_XSIZE, W_YSIZE, W_FG, W_BG, W_BORDER:INTEGER
    RUN GFX2(PATH,"WINFO",W_FORMAT,W_XSIZE,W_YSIZE,W_FG,W_BG,W_BORDER)
    PRINT #PATH,"WINFO: Format=";W_FORMAT;", XSize=";W_XSIZE;", YSize=";W_YSIZE;
    PRINT #PATH,", FG=";W_FG;", BG=";W_BG;", Border=";W_BORDER
    RUN GFX2(PATH,"CRRTN")
    GET #1,RESPONSE REM Pause

    REM 1.2. CWAREA: Change working area (restricts output)
    RUN GFX2(PATH,"CURXY",1,7)
    PRINT #PATH,"CWAREA: Changing working area to 20x10 at (10,10)"
    RUN GFX2(PATH,"CWAREA",10,10,20,10) REM xcor,ycor,sizex,sizey (character units)
    RUN GFX2(PATH,"COLOR",1,0,0) REM Change foreground to Red
    RUN GFX2(PATH,"CLEAR") REM Clear the new working area
    RUN GFX2(PATH,"CURXY",11,11) REM Cursor position relative to original window
    PRINT #PATH,"New working area here!"
    GET #1,RESPONSE REM Pause

    REM Restore full working area for next demos
    RUN GFX2(PATH,"CWAREA",0,0,80,25)
    RUN GFX2(PATH,"COLOR",3,0,2) REM Restore default colors
    RUN GFX2(PATH,"CLEAR")

    REM 1.3. OWSET / OWEND: Establish and close an overlay window
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"OWSET: Creating an overlay window (saves content)"
    RUN GFX2(PATH,"OWSET",1,10,5,60,15,1,3) REM save_switch,xpos,ypos,xsize,ysize,fg,bg
    REM save_switch=1 means save underlying content.
    RUN GFX2(PATH,"CLEAR") REM Clear the overlay
    RUN GFX2(PATH,"CURXY",11,6)
    PRINT #PATH,"This is an overlay window!"
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"OWEND") REM Close the overlay, restoring original content
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"OWEND: Overlay closed, original content restored."
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"CLEAR")

    REM --- Section 2: Configuring Functions ---
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"--- Section 2: Configuring Functions ---"
    PRINT #PATH,"(Press any key to continue after each step)"
    RUN GFX2(PATH,"CRRTN")
    RUN GFX2(PATH,"CRRTN")

    REM 2.1. COLOR: Set screen colors (foreground, background, border)
    PRINT #PATH,"COLOR: Changing foreground to Green, background to Blue."
    RUN GFX2(PATH,"COLOR",2,4,2) REM FG=Green, BG=Blue, Border=Green (same as before)
    RUN GFX2(PATH,"CLEAR")
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"Colors changed!"
    GET #1,RESPONSE REM Pause

    REM 2.2. BORDER: Set border color
    PRINT #PATH,"BORDER: Changing border to Red."
    RUN GFX2(PATH,"BORDER",1) REM Red border
    GET #1,RESPONSE REM Pause

    REM 2.3. DEFCOL: Set default colors
    PRINT #PATH,"DEFCOL: Restoring default palette colors."
    RUN GFX2(PATH,"DEFCOL")
    RUN GFX2(PATH,"CLEAR")
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"Default colors restored!"
    GET #1,RESPONSE REM Pause

    REM 2.4. PALETTE: Set color for palette registers
    PRINT #PATH,"PALETTE: Changing palette register 1 to Magenta."
    RUN GFX2(PATH,"PALETTE",1,5) REM Register 1 (Red) to Magenta
    RUN GFX2(PATH,"COLOR",1,0,0) REM Use new color (FG=Magenta)
    RUN GFX2(PATH,"CLEAR")
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"Palette color changed!"
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"DEFCOL") REM Restore defaults
    RUN GFX2(PATH,"CLEAR")

    REM 2.5. LOGIC: Perform logic function (AND, OR, XOR, OFF)
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"LOGIC: Drawing with XOR logic."
    RUN GFX2(PATH,"COLOR",3,0,0) REM Yellow foreground
    RUN GFX2(PATH,"BAR",10,10,100,100) REM Draw a yellow square
    RUN GFX2(PATH,"LOGIC","XOR")
    RUN GFX2(PATH,"COLOR",1,0,0) REM Red foreground
    RUN GFX2(PATH,"BAR",50,50,150,150) REM Draw an overlapping red square with XOR
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"LOGIC","OFF") REM Turn off logic
    RUN GFX2(PATH,"CLEAR")

    REM 2.6. SETDPTR: Positions the draw pointer
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"SETDPTR: Setting draw pointer to (320,100)."
    RUN GFX2(PATH,"SETDPTR",320,100) REM X,Y pixel coordinates
    RUN GFX2(PATH,"COLOR",2,0,0) REM Green foreground
    RUN GFX2(PATH,"CIRCLE",50) REM Draw a circle with radius 50 at draw pointer
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"CLEAR")

    REM 2.7. SCALESW: Enable/disable scaling (for window resizing)
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"SCALESW: Scaling is ON by default. Drawing a circle."
    RUN GFX2(PATH,"COLOR",3,0,0) REM Yellow
    RUN GFX2(PATH,"CIRCLE",320,100,50)
    GET #1,RESPONSE REM Pause

    PRINT #PATH,"SCALESW: Turning scaling OFF. Drawing another circle."
    RUN GFX2(PATH,"SCALESW","OFF")
    RUN GFX2(PATH,"COLOR",1,0,0) REM Red
    RUN GFX2(PATH,"CIRCLE",320,100,50) REM This circle might look different if window was resized.
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"SCALESW","ON") REM Restore scaling
    RUN GFX2(PATH,"CLEAR")

    REM 2.8. GCSET / PUTGC: Set and position graphics cursor
    REM This requires Stdptrs merged (e.g., merge /d0/sys/stdptrs > /w1)
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"GCSET/PUTGC: Displaying a graphics cursor (pointer)."
    RUN GFX2(PATH,"GCSET",202,1) REM Group 202, Buffer 1 (standard pointer)
    RUN GFX2(PATH,"PUTGC",320,100) REM Place cursor at center (pixel coords)
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"GCSET",0,0) REM Turn off graphics cursor
    RUN GFX2(PATH,"CLEAR")

    REM 2.9. PATTERN: Select pattern buffer (complex, requires buffer setup)
    REM For simplicity, we'll draw a simple pattern and use it.
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"PATTERN: Creating a pattern and using it for drawing."
    RUN GFX2(PATH,"DEFBUFF",ID_NUM,1,128) REM Define a 128-byte buffer (for 16-color mode)
    RUN GFX2(PATH,"GET",ID_NUM,1,0,0,16,8) REM Get a small area (16x8 pixels) from top-left
    RUN GFX2(PATH,"PATTERN",ID_NUM,1) REM Select this buffer as a pattern
    RUN GFX2(PATH,"COLOR",3,0,0) REM Yellow foreground
    RUN GFX2(PATH,"BAR",100,100,400,150) REM Draw a bar filled with the pattern
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"PATTERN",0,0) REM Turn off pattern
    RUN GFX2(PATH,"KILLBUFF",ID_NUM,1) REM Deallocate buffer
    RUN GFX2(PATH,"CLEAR")

    REM --- Section 3: Drawing Functions ---
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"--- Section 3: Drawing Functions ---"
    PRINT #PATH,"(Press any key to clear screen and continue)"
    RUN GFX2(PATH,"CRRTN")
    RUN GFX2(PATH,"CRRTN")

    REM 3.1. POINT: Mark a point
    RUN GFX2(PATH,"COLOR",1,0,0) REM Red
    RUN GFX2(PATH,"POINT",10,10)
    RUN GFX2(PATH,"POINT",20,20)
    RUN GFX2(PATH,"POINT",30,30)
    GET #1,RESPONSE REM Pause and clear
    RUN GFX2(PATH,"CLEAR")

    REM 3.2. LINE: Draw a line
    RUN GFX2(PATH,"COLOR",2,0,0) REM Green
    RUN GFX2(PATH,"LINE",50,50,200,150) REM xcor1,ycor1,xcor2,ycor2
    GET #1,RESPONSE REM Pause and clear
    RUN GFX2(PATH,"CLEAR")

    REM 3.3. BOX: Draw a rectangle outline
    RUN GFX2(PATH,"COLOR",3,0,0) REM Yellow
    RUN GFX2(PATH,"BOX",100,50,300,150) REM xcor1,ycor1,xcor2,ycor2
    GET #1,RESPONSE REM Pause and clear
    RUN GFX2(PATH,"CLEAR")

    REM 3.4. BAR: Fill a rectangle
    RUN GFX2(PATH,"COLOR",4,0,0) REM Blue
    RUN GFX2(PATH,"BAR",100,50,300,150) REM xcor1,ycor1,xcor2,ycor2
    GET #1,RESPONSE REM Pause and clear
    RUN GFX2(PATH,"CLEAR")

    REM 3.5. CIRCLE: Draw a circle outline
    RUN GFX2(PATH,"COLOR",5,0,0) REM Magenta
    RUN GFX2(PATH,"CIRCLE",320,100,80) REM xcor,ycor,radius
    GET #1,RESPONSE REM Pause and clear
    RUN GFX2(PATH,"CLEAR")

    REM 3.6. FCIRCLE: Draw a filled circle
    RUN GFX2(PATH,"COLOR",6,0,0) REM Cyan
    RUN GFX2(PATH,"FCIRCLE",320,100,80) REM xcor,ycor,radius
    GET #1,RESPONSE REM Pause and clear
    RUN GFX2(PATH,"CLEAR")

    REM 3.7. ELLIPSE: Draw an ellipse outline
    RUN GFX2(PATH,"COLOR",7,0,0) REM White
    RUN GFX2(PATH,"ELLIPSE",320,100,150,80) REM xcor,ycor,xrad,yrad
    GET #1,RESPONSE REM Pause and clear
    RUN GFX2(PATH,"CLEAR")

    REM 3.8. FELLIPSE: Draw a filled ellipse
    RUN GFX2(PATH,"COLOR",8,0,0) REM Black (on black, so will be invisible unless color changed)
    RUN GFX2(PATH,"COLOR",9,0,0) REM Light Green
    RUN GFX2(PATH,"FELLIPSE",320,100,150,80) REM xcor,ycor,xrad,yrad
    GET #1,RESPONSE REM Pause and clear
    RUN GFX2(PATH,"CLEAR")

    REM 3.9. ARC: Draw an arc
    RUN GFX2(PATH,"COLOR",10,0,0) REM Dark Green
    RUN GFX2(PATH,"ARC",320,100,100,50, -100,-50, 100,50) REM mx,my,xrad,yrad,xcor1,ycor1,xcor2,ycor2
    GET #1,RESPONSE REM Pause and clear
    RUN GFX2(PATH,"CLEAR")

    REM 3.10. DRAW: Draw a polyline figure
    RUN GFX2(PATH,"COLOR",11,0,0) REM Light Blue
    RUN GFX2(PATH,"DRAW",100,100,"N50,E50,S50,W50") REM xcor,ycor,option_list
    GET #1,RESPONSE REM Pause and clear
    RUN GFX2(PATH,"CLEAR")

    REM 3.11. FILL: Fill (paint) window (from current draw pointer or specified point)
    RUN GFX2(PATH,"COLOR",12,0,0) REM Dark Blue
    RUN GFX2(PATH,"BOX",100,50,300,150)
    RUN GFX2(PATH,"COLOR",13,0,0) REM Light Red
    RUN GFX2(PATH,"FILL",101,51) REM Fill inside the box
    GET #1,RESPONSE REM Pause and clear
    RUN GFX2(PATH,"CLEAR")

    REM --- Section 4: Get/Put Functions ---
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"--- Section 4: Get/Put Functions ---"
    PRINT #PATH,"(Press any key to continue after each step)"
    RUN GFX2(PATH,"CRRTN")
    RUN GFX2(PATH,"CRRTN")

    REM 4.1. DEFBUFF: Define a GET/PUT buffer
    RUN GFX2(PATH,"ID",ID_NUM) REM Get process ID for unique buffer group
    PRINT #PATH,"DEFBUFF: Defining a buffer for image storage (Group ";ID_NUM;", Buffer 1)."
    RUN GFX2(PATH,"DEFBUFF",ID_NUM,1,2000) REM Group, Buffer, Size (bytes)
    GET #1,RESPONSE REM Pause

    REM 4.2. GET: Save a specified portion of a window to a buffer
    RUN GFX2(PATH,"COLOR",1,0,0) REM Red
    RUN GFX2(PATH,"FCIRCLE",320,100,50) REM Draw something to capture
    PRINT #PATH,"GET: Capturing the circle into the buffer."
    RUN GFX2(PATH,"GET",ID_NUM,1,270,50,100,100) REM Group, Buffer, xcor, ycor, xsize, ysize
    GET #1,RESPONSE REM Pause
    RUN GFX2(PATH,"CLEAR")

    REM 4.3. PUT: Place the image stored in a buffer onto a window
    PRINT #PATH,"PUT: Placing the saved circle at a new location."
    RUN GFX2(PATH,"PUT",ID_NUM,1,100,50) REM Group, Buffer, xcor, ycor
    GET #1,RESPONSE REM Pause

    PRINT #PATH,"PUT: Placing the saved circle at another location."
    RUN GFX2(PATH,"PUT",ID_NUM,1,500,50)
    GET #1,RESPONSE REM Pause

    REM 4.4. KILLBUFF: Deallocate Get/Put buffer
    PRINT #PATH,"KILLBUFF: Deallocating the buffer."
    RUN GFX2(PATH,"KILLBUFF",ID_NUM,1) REM Group, Buffer
    GET #1,RESPONSE REM Pause
    RUN GFX2(PATH,"CLEAR")

    REM --- Section 5: Text/Cursor Handling Functions ---
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"--- Section 5: Text/Cursor Handling Functions ---"
    PRINT #PATH,"(Press any key to continue after each step)"
    RUN GFX2(PATH,"CRRTN")
    RUN GFX2(PATH,"CRRTN")

    RUN GFX2(PATH,"CURON") REM Turn on cursor for text demos

    REM 5.1. CURXY: Set cursor position
    PRINT #PATH,"CURXY: Moving cursor to (20,10)."
    RUN GFX2(PATH,"CURXY",20,10) REM Column, Row (character units)
    PRINT #PATH,"Cursor is here!"
    GET #1,RESPONSE REM Pause

    REM 5.2. EREOLINE: Erase to end of line
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"This line will be partially erased."
    RUN GFX2(PATH,"CURXY",10,1)
    PRINT #PATH,"EREOLINE: Erasing from here to end of line."
    RUN GFX2(PATH,"EREOLINE")
    GET #1,RESPONSE REM Pause

    REM 5.3. DELLIN: Delete current line of text
    RUN GFX2(PATH,"CURXY",1,5)
    PRINT #PATH,"This line will be deleted."
    RUN GFX2(PATH,"CURXY",1,6)
    PRINT #PATH,"This line will move up."
    RUN GFX2(PATH,"CURXY",1,5)
    PRINT #PATH,"DELLIN: Deleting this line."
    RUN GFX2(PATH,"DELLIN")
    GET #1,RESPONSE REM Pause

    REM 5.4. INSLIN: Insert line
    RUN GFX2(PATH,"CURXY",1,5)
    PRINT #PATH,"INSLIN: Inserting a new line above this one."
    RUN GFX2(PATH,"INSLIN")
    RUN GFX2(PATH,"CURXY",1,5)
    PRINT #PATH,"New line inserted!"
    GET #1,RESPONSE REM Pause

    REM 5.5. CRRTN: Carriage return
    RUN GFX2(PATH,"CURXY",1,15)
    PRINT #PATH,"Line 15, then carriage return."
    RUN GFX2(PATH,"CRRTN")
    PRINT #PATH,"This is on the next line."
    GET #1,RESPONSE REM Pause

    REM 5.6. BELL: Ring the terminal bell
    PRINT #PATH,"BELL: Ringing the terminal bell."
    RUN GFX2(PATH,"BELL")
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"CLEAR")

    REM --- Section 6: Font Handling Functions ---
    REM Assumes standard fonts (Group 200, Buffers 1,2,3) are available
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"--- Section 6: Font Handling Functions ---"
    PRINT #PATH,"(Press any key to continue after each step)"
    RUN GFX2(PATH,"CRRTN")
    RUN GFX2(PATH,"CRRTN")

    REM 6.1. FONT: Define font buffer (Group 200, Buffer 2 for a different font)
    PRINT #PATH,"FONT: Changing to Font 2 (if available)."
    RUN GFX2(PATH,"FONT",200,2)
    PRINT #PATH,"This text uses Font 2."
    GET #1,RESPONSE REM Pause

    REM 6.2. BOLDSW: Switch bold characters on or off
    PRINT #PATH,"BOLDSW: Turning bold ON."
    RUN GFX2(PATH,"BOLDSW","ON")
    PRINT #PATH,"This text is BOLD!"
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"BOLDSW","OFF")
    PRINT #PATH,"BOLDSW: Turning bold OFF. This is normal text."
    GET #1,RESPONSE REM Pause

    REM 6.3. PROPSW: Proportional space switch
    PRINT #PATH,"PROPSW: Turning proportional spacing ON."
    RUN GFX2(PATH,"PROPSW","ON")
    PRINT #PATH,"This text is proportionally spaced."
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"PROPSW","OFF")
    PRINT #PATH,"PROPSW: Turning proportional spacing OFF. Back to fixed."
    GET #1,RESPONSE REM Pause

    REM 6.4. REVON / REVOFF: Reverse video on/off
    PRINT #PATH,"REVON: Turning reverse video ON."
    RUN GFX2(PATH,"REVON")
    PRINT #PATH,"THIS TEXT IS IN REVERSE VIDEO!"
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"REVOFF")
    PRINT #PATH,"REVOFF: Turning reverse video OFF. Normal text again."
    GET #1,RESPONSE REM Pause

    REM 6.5. TCHARSW: Transparent characters switch
    RUN GFX2(PATH,"COLOR",1,0,0) REM Red foreground
    RUN GFX2(PATH,"BAR",10,10,60,12) REM Draw a red bar
    RUN GFX2(PATH,"CURXY",2,11)
    PRINT #PATH,"TCHARSW: Transparent characters OFF (default)."
    PRINT #PATH,"Text will clear background."
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"CURXY",2,13)
    RUN GFX2(PATH,"TCHARSW","ON")
    PRINT #PATH,"TCHARSW: Transparent characters ON."
    PRINT #PATH,"Text will show background."
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"TCHARSW","OFF")
    RUN GFX2(PATH,"CLEAR")

    REM 6.6. UNDLNON / UNDLNOFF: Underline characters on/off
    PRINT #PATH,"UNDLNON: Turning underline ON."
    RUN GFX2(PATH,"UNDLNON")
    PRINT #PATH,"This text is UNDERLINED!"
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"UNDLNOFF")
    PRINT #PATH,"UNDLNOFF: Turning underline OFF. Normal text again."
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"FONT",200,1) REM Restore default font
    RUN GFX2(PATH,"CLEAR")

    REM --- Section 7: Mouse Handling Functions ---
    REM Mouse functions are interactive and require user input.
    REM This section provides a basic loop to demonstrate MOUSE.
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"--- Section 7: Mouse Handling Functions ---"
    PRINT #PATH,"Move the mouse and click buttons. Press 'Q' to quit this section."
    RUN GFX2(PATH,"CRRTN")
    RUN GFX2(PATH,"CRRTN")

    DIM M_VALID, M_FIRE, M_X, M_Y, M_AREA, M_SX, M_SY:INTEGER
    DIM OLD_M_X, OLD_M_Y:INTEGER
    OLD_M_X = -1
    OLD_M_Y = -1

    REM SETMOUSE: Set mouse parameters (scanrate, timeout, autofollowflag)
    REM scanrate=3 (1/20th sec), timeout=120 (2 sec), autofollow=1 (OS handles cursor)
    RUN GFX2(PATH,"SETMOUSE",3,120,1)
    RUN GFX2(PATH,"GCSET",202,1) REM Ensure graphics cursor is on

    LOOP
    RUN GFX2(PATH,"MOUSE",M_VALID,M_FIRE,M_X,M_Y,M_AREA,M_SX,M_SY)
    IF M_VALID <> 0 THEN
        IF OLD_M_X <> M_X OR OLD_M_Y <> M_Y THEN
        RUN GFX2(PATH,"CURXY",1,5)
        RUN GFX2(PATH,"EREOLINE")
        PRINT #PATH,"Mouse X: ";M_X;", Y: ";M_Y
        OLD_M_X = M_X
        OLD_M_Y = M_Y
        ENDIF
        IF M_FIRE = 2 THEN
        RUN GFX2(PATH,"CURXY",1,6)
        RUN GFX2(PATH,"EREOLINE")
        PRINT #PATH,"Button A Pressed!"
        ELSEIF M_FIRE = 3 THEN
        RUN GFX2(PATH,"CURXY",1,6)
        RUN GFX2(PATH,"EREOLINE")
        PRINT #PATH,"Button B Pressed!"
        ELSEIF M_FIRE = 4 THEN
        RUN GFX2(PATH,"CURXY",1,6)
        RUN GFX2(PATH,"EREOLINE")
        PRINT #PATH,"Both Buttons Pressed!"
        ELSE
        RUN GFX2(PATH,"CURXY",1,6)
        RUN GFX2(PATH,"EREOLINE")
        PRINT #PATH,"No buttons pressed."
        ENDIF
    ENDIF

    RUN INKEY(RESPONSE)
    IF RESPONSE = "Q" OR RESPONSE = "q" THEN
        EXITIF TRUE THEN ENDEXIT
    ENDIF
    ENDLOOP

    RUN GFX2(PATH,"SETMOUSE",255,255,0) REM Turn off auto-follow
    RUN GFX2(PATH,"GCSET",0,0) REM Turn off graphics cursor
    RUN GFX2(PATH,"CLEAR")

    REM --- Section 8: Music/Miscellaneous Functions ---
    RUN GFX2(PATH,"CURXY",1,1)
    PRINT #PATH,"--- Section 8: Music/Miscellaneous Functions ---"
    PRINT #PATH,"(Press any key to continue after each step)"
    RUN GFX2(PATH,"CRRTN")
    RUN GFX2(PATH,"CRRTN")

    REM 8.1. ID: Return process ID
    RUN GFX2(PATH,"ID",ID_NUM)
    PRINT #PATH,"ID: Current Process ID is: ";ID_NUM
    GET #1,RESPONSE REM Pause

    REM 8.2. TONE: Play a tone through the speaker
    PRINT #PATH,"TONE: Playing a tone (Freq 1000, Dur 60, Vol 30)."
    RUN GFX2(PATH,"TONE",1000,60,30) REM Frequency, Duration (1/60s), Volume
    GET #1,RESPONSE REM Pause

    RUN GFX2(PATH,"CLEAR")

    REM --- Final Cleanup ---
    RUN GFX2(PATH,"CURON")  REM Turn text cursor back on
    RUN GFX2(PATH,"DWEND")  REM Deallocate the graphics window
    CLOSE #PATH             REM Close the path to the window

    PRINT "GFX2 Demonstration Complete!"
    PRINT "You are now back in the BASIC09 Command Mode."
END
