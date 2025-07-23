PROCEDURE GFX2_Basics_Window_And_Primitives

  REM --- Variable Declarations ---

  REM Path number for the graphics window
  DIM PATH:INTEGER
  REM For user input (single character)
  DIM RESPONSE:STRING[1]
  REM General coordinates
  DIM X, Y, X1, Y1:INTEGER
  REM Color values
  DIM COLOR_VAL, BG_COLOR, BORDER_COLOR:INTEGER

  REM --- Initial Setup: Create and Select a Graphics Window ---
  REM We'll use a high-resolution window (Format 7: 640x200 pixels, 4 colors)
  REM If /W1 is in use, try /W2, /W3, etc.

  REM Initialize the window device
  SHELL "INIZ /W1"
  REM Open a path to the window
  OPEN #PATH,"/W1":WRITE

  REM DWSET: Define Window Settings (format, xcor, ycor, width, height, fg, bg, border)
  REM Format 7: 640x200 pixels, 4 colors (0=Black, 1=Red, 2=Green, 3=Yellow)
  REM xcor,ycor: 0,0 (top-left corner of screen)
  REM width,height: 80 columns, 25 rows (text character dimensions for the window)
  REM foreground: 3 (Yellow), background: 0 (Black), border: 2 (Green)
  RUN GFX2(PATH,"DWSET",7,0,0,80,25,3,0,2)

  REM Make this window the active display
  RUN GFX2(PATH,"SELECT")
  REM Turn off the text cursor for cleaner graphics
  RUN GFX2(PATH,"CUROFF")
  REM Clear the window to its background color
  RUN GFX2(PATH,"CLEAR")
  REM Ensure default palette for consistent colors
  RUN GFX2(PATH,"DEFCOL")

  REM --- Demo Specific Logic ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"--- GFX2 Demo 1: Window Setup and Basic Primitives ---"
  PRINT #PATH,"(Press any key to continue after each step)"
  RUN GFX2(PATH,"CRRTN")
  RUN GFX2(PATH,"CRRTN")
  GET #1,RESPONSE

  REM --- COLOR: Setting foreground, background, and border colors ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating COLOR: (FG=Red, BG=Blue, Border=Yellow)"
  REM FG=Red (1), BG=Blue (4), Border=Yellow (3)
  RUN GFX2(PATH,"COLOR",1,4,3)
  RUN GFX2(PATH,"CLEAR") REM Clear with new background color
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Colors changed!"
  GET #1,RESPONSE

  REM --- BORDER: Setting only the border color ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating BORDER: (Border=Green)"
  RUN GFX2(PATH,"BORDER",2) REM Border=Green (2)
  GET #1,RESPONSE

  REM --- DEFCOL: Restoring default colors ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating DEFCOL: (Restoring default palette)"
  RUN GFX2(PATH,"DEFCOL")
  REM Reset to initial setup colors (Yellow FG, Black BG, Green Border)
  RUN GFX2(PATH,"COLOR",3,0,2)
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Default colors restored!"
  GET #1,RESPONSE

  REM --- POINT: Drawing individual pixels ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating POINT: (Drawing multiple red points)"
  REM Red foreground
  RUN GFX2(PATH,"COLOR",1,0,0)
  FOR X = 100 TO 500 STEP 10
    RUN GFX2(PATH,"POINT",X,100)
  NEXT X
  FOR Y = 50 TO 150 STEP 10
    RUN GFX2(PATH,"POINT",300,Y)
  NEXT Y
  GET #1,RESPONSE

  REM --- LINE: Drawing straight lines ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating LINE: (Drawing green lines)"
  REM Green foreground
  RUN GFX2(PATH,"COLOR",2,0,0)
  RUN GFX2(PATH,"LINE",50,50,590,150)
  RUN GFX2(PATH,"LINE",590,50,50,150)
  RUN GFX2(PATH,"LINE",320,20,320,180)
  GET #1,RESPONSE

  REM --- BOX: Drawing rectangular outlines ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating BOX: (Drawing yellow rectangles)"
  REM Yellow foreground
  RUN GFX2(PATH,"COLOR",3,0,0)
  RUN GFX2(PATH,"BOX",100,50,200,100)
  RUN GFX2(PATH,"BOX",250,75,400,125)
  RUN GFX2(PATH,"BOX",450,100,550,150)
  GET #1,RESPONSE

  REM --- BAR: Drawing filled rectangles ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating BAR: (Drawing filled blue rectangles)"
  REM Blue foreground
  RUN GFX2(PATH,"COLOR",4,0,0)
  RUN GFX2(PATH,"BAR",100,50,200,100)
  RUN GFX2(PATH,"BAR",250,75,400,125)
  RUN GFX2(PATH,"BAR",450,100,550,150)
  GET #1,RESPONSE

  REM --- CIRCLE: Drawing circular outlines ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating CIRCLE: (Drawing magenta circles)"
  REM Magenta foreground
  RUN GFX2(PATH,"COLOR",5,0,0)
  RUN GFX2(PATH,"CIRCLE",150,100,50)
  RUN GFX2(PATH,"CIRCLE",320,100,80)
  RUN GFX2(PATH,"CIRCLE",490,100,50)
  GET #1,RESPONSE

  REM --- FCIRCLE: Drawing filled circles ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating FCIRCLE: (Drawing filled cyan circles)"
  REM Cyan foreground
  RUN GFX2(PATH,"COLOR",6,0,0)
  RUN GFX2(PATH,"FCIRCLE",150,100,50)
  RUN GFX2(PATH,"FCIRCLE",320,100,80)
  RUN GFX2(PATH,"FCIRCLE",490,100,50)
  GET #1,RESPONSE

  REM --- ELLIPSE: Drawing elliptical outlines ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating ELLIPSE: (Drawing white ellipses)"
  REM White foreground
  RUN GFX2(PATH,"COLOR",7,0,0)
  RUN GFX2(PATH,"ELLIPSE",320,100,200,80)
  RUN GFX2(PATH,"ELLIPSE",150,100,80,40)
  RUN GFX2(PATH,"ELLIPSE",490,100,40,80)
  GET #1,RESPONSE

  REM --- FELLIPSE: Drawing filled ellipses ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating FELLIPSE: (Drawing filled light green ellipses)"
  REM Light Green foreground
  RUN GFX2(PATH,"COLOR",9,0,0)
  RUN GFX2(PATH,"FELLIPSE",320,100,200,80)
  RUN GFX2(PATH,"FELLIPSE",150,100,80,40)
  RUN GFX2(PATH,"FELLIPSE",490,100,40,80)
  GET #1,RESPONSE

  REM --- Cleanup ---
  REM Turn text cursor back on
  RUN GFX2(PATH,"CURON")
  REM Deallocate the graphics window
  RUN GFX2(PATH,"DWEND")
  REM Close the path to the window
  CLOSE #PATH
  PRINT "GFX2 Demo 1: Window Setup and Basic Primitives Complete!"

END



PROCEDURE GFX2_Advanced_Drawing_And_Configurations

  REM --- Variable Declarations ---
  DIM PATH:INTEGER        REM Path number for the graphics window
  DIM RESPONSE:STRING[1]  REM For user input (single character)
  DIM X, Y, X1, Y1:INTEGER REM General coordinates
  DIM ID_NUM:INTEGER      REM For buffer ID

  REM --- Initial Setup ---
  SHELL "INIZ /W1"
  OPEN #PATH,"/W1":WRITE
  RUN GFX2(PATH,"DWSET",7,0,0,80,25,3,0,2) REM Format 7: 640x200, 4 colors
  RUN GFX2(PATH,"SELECT")
  RUN GFX2(PATH,"CUROFF")
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"DEFCOL")

  REM --- Demo Specific Logic ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"--- GFX2 Demo 2: Advanced Drawing and Configurations ---"
  PRINT #PATH,"(Press any key to continue after each step)"
  RUN GFX2(PATH,"CRRTN")
  RUN GFX2(PATH,"CRRTN")
  GET #1,RESPONSE

  REM --- ARC: Drawing an arc ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating ARC: (Drawing a green arc)"
  RUN GFX2(PATH,"COLOR",2,0,0) REM Green foreground
  REM ARC(path, xcenter, ycenter, xradius, yradius, xstart, ystart, xend, yend)
  REM Note: xstart, ystart, xend, yend are relative to center for arc segment.
  RUN GFX2(PATH,"ARC",320,100,100,50, -100,0, 100,0) REM Half ellipse arc
  GET #1,RESPONSE

  REM --- DRAW: Drawing a polyline figure ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating DRAW: (Drawing a yellow 'N,E,S,W' shape)"
  RUN GFX2(PATH,"COLOR",3,0,0) REM Yellow foreground
  REM DRAW(path, xstart, ystart, "option_list")
  REM Options: N=North, S=South, E=East, W=West, U=Up, D=Down, F=Forward, B=Backward
  REM Followed by distance.
  RUN GFX2(PATH,"DRAW",100,100,"N50,E50,S50,W50,N50") REM Draws a square starting North
  GET #1,RESPONSE

  REM --- FILL: Flood-filling areas ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating FILL: (Filling a red box with blue)"
  RUN GFX2(PATH,"COLOR",1,0,0) REM Red foreground for box
  RUN GFX2(PATH,"BOX",200,50,440,150)
  RUN GFX2(PATH,"COLOR",4,0,0) REM Blue foreground for fill
  RUN GFX2(PATH,"FILL",201,51) REM Fill inside the box (start point must be inside)
  GET #1,RESPONSE

  REM --- LOGIC: Applying drawing logic (XOR) for "rubber-banding" ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating LOGIC 'XOR': (Draw two overlapping bars)"
  RUN GFX2(PATH,"COLOR",1,0,0) REM Red
  RUN GFX2(PATH,"BAR",100,50,300,150) REM Draw a red bar
  RUN GFX2(PATH,"LOGIC","XOR") REM Set drawing logic to XOR
  RUN GFX2(PATH,"COLOR",3,0,0) REM Yellow (will XOR with red)
  RUN GFX2(PATH,"BAR",200,75,400,175) REM Draw overlapping yellow bar
  PRINT #PATH,"Notice the overlapping area is different color due to XOR."
  GET #1,RESPONSE

  RUN GFX2(PATH,"LOGIC","OFF") REM Turn off logic
  RUN GFX2(PATH,"CLEAR")

  REM --- PALETTE: Modifying specific palette registers ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating PALETTE: (Changing color register 1 to Cyan)"
  REM Default palette for Format 7 (4 colors):
  REM 0=Black, 1=Red, 2=Green, 3=Yellow
  REM PALETTE(path, register_number, new_color_value)
  REM New color value (0-15 for 4-color mode, 0-255 for 16-color mode)
  RUN GFX2(PATH,"PALETTE",1,6) REM Change palette register 1 (Red) to Cyan (6)
  RUN GFX2(PATH,"COLOR",1,0,0) REM Draw using palette color 1 (now Cyan)
  RUN GFX2(PATH,"BAR",100,50,200,100)
  PRINT #PATH,"Red objects will now appear Cyan."
  GET #1,RESPONSE

  RUN GFX2(PATH,"DEFCOL") REM Restore default palette
  RUN GFX2(PATH,"CLEAR")

  REM --- SCALESW: Toggling scaling on/off ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating SCALESW: (Scaling ON/OFF)"
  PRINT #PATH,"Drawing a circle with scaling ON (default)."
  RUN GFX2(PATH,"COLOR",3,0,0) REM Yellow
  RUN GFX2(PATH,"CIRCLE",320,100,50)
  GET #1,RESPONSE

  RUN GFX2(PATH,"CURXY",1,3)
  PRINT #PATH,"Turning SCALESW OFF. Drawing another circle."
  RUN GFX2(PATH,"SCALESW","OFF")
  RUN GFX2(PATH,"COLOR",1,0,0) REM Red
  RUN GFX2(PATH,"CIRCLE",320,100,50)
  PRINT #PATH,"If you resize the window, the red circle will not scale."
  GET #1,RESPONSE

  RUN GFX2(PATH,"SCALESW","ON") REM Restore scaling
  RUN GFX2(PATH,"CLEAR")

  REM --- SETDPTR: Setting the draw pointer ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating SETDPTR: (Setting draw pointer and drawing relative)"
  RUN GFX2(PATH,"COLOR",2,0,0) REM Green
  RUN GFX2(PATH,"SETDPTR",320,100) REM Set draw pointer to center
  RUN GFX2(PATH,"CIRCLE",50) REM Draw a circle with radius 50 at draw pointer
  PRINT #PATH,"A circle drawn at the draw pointer."
  GET #1,RESPONSE

  REM --- GCSET / PUTGC: Setting and positioning a graphical cursor ---
  REM Requires 'Stdptrs' module to be merged into the window.
  REM e.g., in NitrOS-9 shell: 'merge /d0/sys/stdptrs > /w1'
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating GCSET/PUTGC: (Displaying a graphics cursor)"
  PRINT #PATH,"NOTE: Requires 'Stdptrs' module merged into window."
  REM GCSET(path, group, buffer) - Group 202, Buffer 1 is often a standard pointer
  RUN GFX2(PATH,"GCSET",202,1)
  RUN GFX2(PATH,"PUTGC",320,100) REM Place cursor at center (pixel coords)
  PRINT #PATH,"A graphical cursor should be visible."
  GET #1,RESPONSE

  RUN GFX2(PATH,"GCSET",0,0) REM Turn off graphics cursor
  RUN GFX2(PATH,"CLEAR")

  REM --- PATTERN: Using a simple pattern for drawing ---
  REM First, define a buffer and get a small image to use as a pattern.
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating PATTERN: (Drawing with a simple captured pattern)"
  RUN GFX2(PATH,"COLOR",1,0,0) REM Draw a small red square
  RUN GFX2(PATH,"BAR",10,10,20,20)
  RUN GFX2(PATH,"ID",ID_NUM) REM Get process ID for unique buffer group
  RUN GFX2(PATH,"DEFBUFF",ID_NUM,1,200) REM Define a buffer for the pattern
  RUN GFX2(PATH,"GET",ID_NUM,1,10,10,10,10) REM Capture the small red square
  RUN GFX2(PATH,"PATTERN",ID_NUM,1) REM Select this buffer as a pattern
  RUN GFX2(PATH,"COLOR",3,0,0) REM Yellow foreground (will be ignored by pattern)
  RUN GFX2(PATH,"BAR",100,50,400,150) REM Draw a bar filled with the pattern
  PRINT #PATH,"A bar filled with the captured pattern."
  GET #1,RESPONSE

  RUN GFX2(PATH,"PATTERN",0,0) REM Turn off pattern
  RUN GFX2(PATH,"KILLBUFF",ID_NUM,1) REM Deallocate buffer
  RUN GFX2(PATH,"CLEAR")

  REM --- Cleanup ---
  RUN GFX2(PATH,"CURON")
  RUN GFX2(PATH,"DWEND")
  CLOSE #PATH
  PRINT "GFX2 Demo 2: Advanced Drawing and Configurations Complete!"

END



PROCEDURE GFX2_Image_And_Text_Manipulation

  REM --- Variable Declarations ---
  DIM PATH:INTEGER        REM Path number for the graphics window
  DIM RESPONSE:STRING[1]  REM For user input (single character)
  DIM ID_NUM:INTEGER      REM For buffer ID

  REM --- Initial Setup ---
  SHELL "INIZ /W1"
  OPEN #PATH,"/W1":WRITE
  RUN GFX2(PATH,"DWSET",7,0,0,80,25,3,0,2) REM Format 7: 640x200, 4 colors
  RUN GFX2(PATH,"SELECT")
  RUN GFX2(PATH,"CUROFF")
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"DEFCOL")

  REM --- Demo Specific Logic ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"--- GFX2 Demo 3: Image and Text Manipulation ---"
  PRINT #PATH,"(Press any key to continue after each step)"
  RUN GFX2(PATH,"CRRTN")
  RUN GFX2(PATH,"CRRTN")
  GET #1,RESPONSE

  REM --- DEFBUFF, GET, PUT, KILLBUFF: Image capture and display ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating GET/PUT: (Capturing and re-displaying a circle)"

  RUN GFX2(PATH,"COLOR",1,0,0) REM Red foreground
  RUN GFX2(PATH,"FCIRCLE",320,100,50) REM Draw a red filled circle
  PRINT #PATH,"Original circle drawn."
  GET #1,RESPONSE

  RUN GFX2(PATH,"ID",ID_NUM) REM Get process ID for unique buffer group
  RUN GFX2(PATH,"DEFBUFF",ID_NUM,1,5000) REM Define a buffer (adjust size as needed)
  RUN GFX2(PATH,"GET",ID_NUM,1,270,50,100,100) REM Capture the circle (x,y,width,height)
  PRINT #PATH,"Circle captured to buffer. Clearing screen..."
  GET #1,RESPONSE

  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Putting the captured circle at (100,50)."
  RUN GFX2(PATH,"PUT",ID_NUM,1,100,50)
  GET #1,RESPONSE

  RUN GFX2(PATH,"CURXY",1,3)
  PRINT #PATH,"Putting the captured circle at (450,50)."
  RUN GFX2(PATH,"PUT",ID_NUM,1,450,50)
  GET #1,RESPONSE

  RUN GFX2(PATH,"KILLBUFF",ID_NUM,1) REM Deallocate the buffer
  PRINT #PATH,"Buffer deallocated."
  GET #1,RESPONSE
  RUN GFX2(PATH,"CLEAR")

  REM --- Text/Cursor Handling Functions ---
  RUN GFX2(PATH,"CURON") REM Turn on cursor for text demos

  REM --- CURXY: Set cursor position ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating CURXY: (Moving cursor and printing)"
  PRINT #PATH,"This is line 1."
  RUN GFX2(PATH,"CURXY",10,5)
  PRINT #PATH,"This is at column 10, row 5."
  GET #1,RESPONSE

  REM --- EREOLINE: Erase to end of line ---
  RUN GFX2(PATH,"CURXY",1,7)
  PRINT #PATH,"This line will be partially erased: [ERASE ME]"
  RUN GFX2(PATH,"CURXY",30,7)
  PRINT #PATH,"EREOLINE: Erasing from here."
  RUN GFX2(PATH,"EREOLINE")
  GET #1,RESPONSE

  REM --- DELLIN: Delete current line of text ---
  RUN GFX2(PATH,"CURXY",1,9)
  PRINT #PATH,"Line 9: This line will be deleted."
  RUN GFX2(PATH,"CURXY",1,10)
  PRINT #PATH,"Line 10: This line will move up."
  RUN GFX2(PATH,"CURXY",1,9)
  PRINT #PATH,"DELLIN: Deleting line 9."
  RUN GFX2(PATH,"DELLIN")
  GET #1,RESPONSE

  REM --- INSLIN: Insert line ---
  RUN GFX2(PATH,"CURXY",1,9)
  PRINT #PATH,"Line 9: This line will be pushed down."
  RUN GFX2(PATH,"CURXY",1,9)
  PRINT #PATH,"INSLIN: Inserting a new line above line 9."
  RUN GFX2(PATH,"INSLIN")
  RUN GFX2(PATH,"CURXY",1,9)
  PRINT #PATH,"Line 9: New line inserted here!"
  GET #1,RESPONSE

  REM --- CRRTN: Carriage return ---
  RUN GFX2(PATH,"CURXY",1,15)
  PRINT #PATH,"Line 15, then CRRTN."
  RUN GFX2(PATH,"CRRTN")
  PRINT #PATH,"This is on the next line (line 16)."
  GET #1,RESPONSE
  RUN GFX2(PATH,"CLEAR")

  REM --- Font Handling Functions ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"--- Font Handling Functions ---"
  PRINT #PATH,"NOTE: Requires 'Stdfonts' module merged into window."
  PRINT #PATH,"(e.g., 'merge /d0/sys/stdfonts > /w1')"
  RUN GFX2(PATH,"CRRTN")
  RUN GFX2(PATH,"CRRTN")
  GET #1,RESPONSE

  REM --- FONT: Switching between different font buffers ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating FONT: (Changing to Font 2, then Font 3)"
  RUN GFX2(PATH,"FONT",200,1) REM Standard Font (Group 200, Buffer 1)
  PRINT #PATH,"This is the default font."
  GET #1,RESPONSE

  RUN GFX2(PATH,"CURXY",1,3)
  RUN GFX2(PATH,"FONT",200,2) REM Try Font 2 (if available)
  PRINT #PATH,"This text uses Font 2."
  GET #1,RESPONSE

  RUN GFX2(PATH,"CURXY",1,5)
  RUN GFX2(PATH,"FONT",200,3) REM Try Font 3 (if available)
  PRINT #PATH,"This text uses Font 3."
  GET #1,RESPONSE
  RUN GFX2(PATH,"FONT",200,1) REM Restore default font
  RUN GFX2(PATH,"CLEAR")

  REM --- BOLDSW: Toggling bold text ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating BOLDSW: (Bold ON/OFF)"
  RUN GFX2(PATH,"BOLDSW","ON")
  PRINT #PATH,"THIS TEXT IS BOLD!"
  GET #1,RESPONSE

  RUN GFX2(PATH,"BOLDSW","OFF")
  PRINT #PATH,"This text is not bold."
  GET #1,RESPONSE
  RUN GFX2(PATH,"CLEAR")

  REM --- PROPSW: Toggling proportional spacing ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating PROPSW: (Proportional spacing ON/OFF)"
  RUN GFX2(PATH,"PROPSW","ON")
  PRINT #PATH,"This text is proportionally spaced."
  GET #1,RESPONSE

  RUN GFX2(PATH,"PROPSW","OFF")
  PRINT #PATH,"This text is fixed width spaced."
  GET #1,RESPONSE
  RUN GFX2(PATH,"CLEAR")

  REM --- REVON / REVOFF: Toggling reverse video ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating REVON/REVOFF: (Reverse video ON/OFF)"
  RUN GFX2(PATH,"REVON")
  PRINT #PATH,"THIS TEXT IS IN REVERSE VIDEO!"
  GET #1,RESPONSE

  RUN GFX2(PATH,"REVOFF")
  PRINT #PATH,"This text is normal video."
  GET #1,RESPONSE
  RUN GFX2(PATH,"CLEAR")

  REM --- TCHARSW: Toggling transparent characters ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating TCHARSW: (Transparent characters ON/OFF)"
  RUN GFX2(PATH,"COLOR",1,0,0) REM Red foreground
  RUN GFX2(PATH,"BAR",100,50,500,100) REM Draw a red bar
  RUN GFX2(PATH,"CURXY",15,8)
  PRINT #PATH,"Transparent OFF (default): Text clears background."
  GET #1,RESPONSE

  RUN GFX2(PATH,"CURXY",15,10)
  RUN GFX2(PATH,"TCHARSW","ON")
  PRINT #PATH,"Transparent ON: Text shows background."
  GET #1,RESPONSE

  RUN GFX2(PATH,"TCHARSW","OFF")
  RUN GFX2(PATH,"CLEAR")

  REM --- UNDLNON / UNDLNOFF: Toggling underlining ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating UNDLNON/UNDLNOFF: (Underlining ON/OFF)"
  RUN GFX2(PATH,"UNDLNON")
  PRINT #PATH,"This text is UNDERLINED!"
  GET #1,RESPONSE

  RUN GFX2(PATH,"UNDLNOFF")
  PRINT #PATH,"This text is not underlined."
  GET #1,RESPONSE
  RUN GFX2(PATH,"CLEAR")

  REM --- Cleanup ---
  RUN GFX2(PATH,"CURON")
  RUN GFX2(PATH,"DWEND")
  CLOSE #PATH
  PRINT "GFX2 Demo 3: Image and Text Manipulation Complete!"

END



PROCEDURE GFX2_Interactive_Input_And_System_Utilities

  REM --- Variable Declarations ---
  DIM PATH:INTEGER        REM Path number for the graphics window
  DIM RESPONSE:STRING[1]  REM For user input (single character)
  DIM M_VALID, M_FIRE, M_X, M_Y, M_AREA, M_SX, M_SY:INTEGER REM Mouse variables
  DIM OLD_M_X, OLD_M_Y:INTEGER REM For tracking mouse movement
  DIM ID_NUM:INTEGER      REM For process ID
  DIM W_FORMAT, W_XSIZE, W_YSIZE, W_FG, W_BG, W_BORDER:INTEGER REM Window info

  REM --- Initial Setup ---
  SHELL "INIZ /W1"
  OPEN #PATH,"/W1":WRITE
  RUN GFX2(PATH,"DWSET",7,0,0,80,25,3,0,2) REM Format 7: 640x200, 4 colors
  RUN GFX2(PATH,"SELECT")
  RUN GFX2(PATH,"CUROFF")
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"DEFCOL")

  REM --- Demo Specific Logic ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"--- GFX2 Demo 4: Interactive Input and System Utilities ---"
  PRINT #PATH,"(Press any key to continue after each step)"
  RUN GFX2(PATH,"CRRTN")
  RUN GFX2(PATH,"CRRTN")
  GET #1,RESPONSE

  REM --- ID: Return process ID ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating ID: (Retrieving current process ID)"
  RUN GFX2(PATH,"ID",ID_NUM)
  PRINT #PATH,"Current Process ID is: ";ID_NUM
  GET #1,RESPONSE

  REM --- WINFO: Get detailed information about the current window ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating WINFO: (Retrieving window properties)"
  RUN GFX2(PATH,"WINFO",W_FORMAT,W_XSIZE,W_YSIZE,W_FG,W_BG,W_BORDER)
  PRINT #PATH,"Window Format: ";W_FORMAT
  PRINT #PATH,"Window Pixel Size: ";W_XSIZE;"x";W_YSIZE
  PRINT #PATH,"Window FG/BG/Border Colors: ";W_FG;"/";W_BG;"/";W_BORDER
  GET #1,RESPONSE

  REM --- CWAREA: Demonstrating a restricted drawing area ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating CWAREA: (Changing working area)"
  PRINT #PATH,"Drawing a red box in the full window."
  RUN GFX2(PATH,"COLOR",1,0,0) REM Red
  RUN GFX2(PATH,"BOX",10,10,630,190)
  GET #1,RESPONSE

  RUN GFX2(PATH,"CURXY",1,3)
  PRINT #PATH,"Setting working area to 300x100 at (170,50)."
  RUN GFX2(PATH,"CWAREA",170,50,300,100) REM xcor,ycor,sizex,sizey (pixel units for graphics)
  RUN GFX2(PATH,"COLOR",4,0,0) REM Blue
  RUN GFX2(PATH,"CLEAR") REM Clears only the new working area
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"This text is in the restricted area."
  RUN GFX2(PATH,"BAR",10,10,290,90) REM Bar drawn relative to new area (170+10, 50+10 to 170+290, 50+90)
  GET #1,RESPONSE

  RUN GFX2(PATH,"CWAREA",0,0,640,200) REM Restore full working area (pixel units)
  RUN GFX2(PATH,"CLEAR")

  REM --- TONE: Generating specific audio tones ---
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating TONE: (Playing a short tone)"
  RUN GFX2(PATH,"TONE",1000,60,30) REM Frequency (Hz), Duration (1/60s), Volume (0-31)
  PRINT #PATH,"Did you hear a tone?"
  GET #1,RESPONSE

  REM --- BELL: Sounding the terminal bell ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating BELL: (Ringing the terminal bell)"
  RUN GFX2(PATH,"BELL")
  PRINT #PATH,"Did you hear the bell?"
  GET #1,RESPONSE

  REM --- MOUSE: Reading mouse state in a loop ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"--- Demonstrating MOUSE (Move mouse, click buttons, press 'Q' to quit) ---"
  PRINT #PATH,"NOTE: Requires 'Stdptrs' module merged for cursor."
  RUN GFX2(PATH,"CRRTN")
  RUN GFX2(PATH,"CRRTN")

  OLD_M_X = -1 : OLD_M_Y = -1 REM Initialize old positions

  REM SETMOUSE: Set mouse parameters (scanrate, timeout, autofollowflag)
  REM scanrate=3 (1/20th sec), timeout=120 (2 sec), autofollow=1 (OS handles cursor)
  RUN GFX2(PATH,"SETMOUSE",3,120,1)
  RUN GFX2(PATH,"GCSET",202,1) REM Enable standard graphics cursor

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
      RUN GFX2(PATH,"CURXY",1,6)
      RUN GFX2(PATH,"EREOLINE")
      IF M_FIRE = 2 THEN
        PRINT #PATH,"Button A Pressed!"
      ELSEIF M_FIRE = 3 THEN
        PRINT #PATH,"Button B Pressed!"
      ELSEIF M_FIRE = 4 THEN
        PRINT #PATH,"Both Buttons Pressed!"
      ELSE
        PRINT #PATH,"No buttons pressed."
      ENDIF
    ENDIF

    RUN INKEY(RESPONSE)
    IF RESPONSE = "Q" OR RESPONSE = "q" THEN
      EXITIF TRUE THEN ENDEXIT
    ENDIF
  ENDLOOP

  RUN GFX2(PATH,"SETMOUSE",255,255,0) REM Turn off mouse auto-follow
  RUN GFX2(PATH,"GCSET",0,0) REM Turn off graphics cursor
  RUN GFX2(PATH,"CLEAR")

  REM --- Cleanup ---
  RUN GFX2(PATH,"CURON")
  RUN GFX2(PATH,"DWEND")
  CLOSE #PATH
  PRINT "GFX2 Demo 4: Interactive Input and System Utilities Complete!"

END



PROCEDURE GFX2_Window_Management_Transitions

  REM --- Variable Declarations ---
  DIM PATH1, PATH2:INTEGER REM Path numbers for graphics windows
  DIM RESPONSE:STRING[1]  REM For user input (single character)

  REM --- Initial Setup ---
  SHELL "INIZ /W1"
  SHELL "INIZ /W2"        REM Initialize a second window device
  OPEN #PATH1,"/W1":WRITE
  OPEN #PATH2,"/W2":WRITE

  REM DWSET for Window 1
  RUN GFX2(PATH1,"DWSET",7,0,0,80,25,3,0,2) REM Format 7: 640x200, Yellow FG, Black BG, Green Border
  RUN GFX2(PATH1,"SELECT")
  RUN GFX2(PATH1,"CUROFF")
  RUN GFX2(PATH1,"CLEAR")
  RUN GFX2(PATH1,"DEFCOL")
  RUN GFX2(PATH1,"CURXY",1,1)
  PRINT #PATH1,"--- GFX2 Demo 5: Window Management and Transitions ---"
  PRINT #PATH1,"This is Window 1."
  PRINT #PATH1,"(Press any key to continue)"
  GET #1,RESPONSE

  REM DWSET for Window 2 (smaller, different colors)
  RUN GFX2(PATH2,"DWSET",7,100,50,60,15,1,4,5) REM Red FG, Blue BG, Magenta Border
  RUN GFX2(PATH2,"CUROFF")
  RUN GFX2(PATH2,"CLEAR")
  RUN GFX2(PATH2,"DEFCOL")
  RUN GFX2(PATH2,"CURXY",1,1)
  PRINT #PATH2,"This is Window 2."

  REM --- Demo Specific Logic ---

  REM --- SELECT: Switching between active windows ---
  RUN GFX2(PATH1,"CLEAR")
  RUN GFX2(PATH1,"CURXY",1,1)
  PRINT #PATH1,"Demonstrating SELECT: (Switching to Window 2)"
  PRINT #PATH1,"Window 1 is active."
  GET #1,RESPONSE

  RUN GFX2(PATH2,"SELECT")
  RUN GFX2(PATH2,"CURXY",1,3)
  PRINT #PATH2,"Now Window 2 is active."
  GET #1,RESPONSE

  RUN GFX2(PATH1,"SELECT")
  RUN GFX2(PATH1,"CURXY",1,3)
  PRINT #PATH1,"Back to Window 1."
  GET #1,RESPONSE

  REM --- DWPROTSW: Protecting a device window from accidental closure ---
  RUN GFX2(PATH1,"CLEAR")
  RUN GFX2(PATH1,"CURXY",1,1)
  PRINT #PATH1,"Demonstrating DWPROTSW: (Protecting Window 1)"
  RUN GFX2(PATH1,"DWPROTSW","ON")
  PRINT #PATH1,"Window 1 is now protected. Try closing it (e.g., 'kill /w1' from shell)."
  PRINT #PATH1,"It should fail. Press any key to unprotect."
  GET #1,RESPONSE

  RUN GFX2(PATH1,"DWPROTSW","OFF")
  PRINT #PATH1,"Window 1 is now unprotected."
  GET #1,RESPONSE
  RUN GFX2(PATH1,"CLEAR")

  REM --- OWSET / OWEND: Creating and closing overlay windows ---
  RUN GFX2(PATH1,"CURXY",1,1)
  PRINT #PATH1,"Demonstrating OWSET/OWEND: (Creating an overlay window)"
  RUN GFX2(PATH1,"COLOR",1,0,0) REM Red
  RUN GFX2(PATH1,"BAR",100,50,540,150) REM Draw a red bar on main window
  PRINT #PATH1,"Red bar on main window."
  GET #1,RESPONSE

  RUN GFX2(PATH1,"CURXY",1,3)
  PRINT #PATH1,"Creating an overlay window (saves content under it)."
  REM OWSET(path, save_switch, xpos, ypos, xsize, ysize, fg, bg)
  REM save_switch=1 means save content, 0 means don't save
  RUN GFX2(PATH1,"OWSET",1,150,75,340,50,3,2) REM Yellow FG, Green BG
  RUN GFX2(PATH1,"CLEAR") REM Clears the overlay area
  RUN GFX2(PATH1,"CURXY",1,1)
  PRINT #PATH1,"This is the overlay window!"
  GET #1,RESPONSE

  RUN GFX2(PATH1,"OWEND") REM Close the overlay, restoring original content
  RUN GFX2(PATH1,"CURXY",1,5)
  PRINT #PATH1,"Overlay closed. Original content restored."
  GET #1,RESPONSE
  RUN GFX2(PATH1,"CLEAR")

  REM --- TITLE: Setting the window title (visible in some environments) ---
  RUN GFX2(PATH1,"CURXY",1,1)
  PRINT #PATH1,"Demonstrating TITLE: (Setting window title)"
  RUN GFX2(PATH1,"TITLE","My GFX2 Window Demo")
  PRINT #PATH1,"Window title set to 'My GFX2 Window Demo'."
  PRINT #PATH1,"(May be visible in your NitrOS-9 environment's window manager)."
  GET #1,RESPONSE

  REM --- WNSET: Setting window properties (e.g., position, size) ---
  RUN GFX2(PATH1,"CLEAR")
  RUN GFX2(PATH1,"CURXY",1,1)
  PRINT #PATH1,"Demonstrating WNSET: (Moving Window 1)"
  PRINT #PATH1,"Window 1 will move to (200, 100) and resize to 400x150."
  GET #1,RESPONSE

  REM WNSET(path, xpos, ypos, xsize, ysize)
  RUN GFX2(PATH1,"WNSET",200,100,400,150)
  RUN GFX2(PATH1,"CURXY",1,1)
  PRINT #PATH1,"Window 1 moved and resized."
  GET #1,RESPONSE

  REM --- Cleanup ---
  RUN GFX2(PATH1,"CURON")
  RUN GFX2(PATH2,"CURON")

  RUN GFX2(PATH1,"DWEND")
  CLOSE #PATH1

  RUN GFX2(PATH2,"DWEND")
  CLOSE #PATH2

  PRINT "GFX2 Demo 5: Window Management and Transitions Complete!"

END
