PROCEDURE gfx2Demo1
  REM GFX2_Basics_Window_And_Primitives

  REM --- Variable Declarations ---

  REM Path number for the graphics window
  DIM PATH:INTEGER
  REM For user input (single character)
  DIM RESPONSE:STRING[1]
  REM General coordinates
  DIM X, Y, X1, Y1:INTEGER
  REM Color values
  DIM COLOR_VAL, BG_COLOR, BORDER_COLOR:INTEGER
  LET WAIT_TIME = 6000

  REM --- Initial Setup: Create and Select a Graphics Window ---
  REM We'll use a high-resolution window (Format 7: 640x200 pixels, 4 colors)
  REM If /W1 is in use, try /W2, /W3, etc.

  REM Initialize the window device
  SHELL "INIZ /W3"
  REM Open a path to the window
  OPEN #PATH,"/W3":WRITE

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
  PRINT #PATH,"Key Polling Now"
  (* GET #0,RESPONSE
  (* PRINT #PATH,"Response: "; RESPONSE
  FOR I = 1 TO WAIT_TIME
  NEXT I

  REM --- COLOR: Setting foreground, background, and border colors ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating COLOR: (FG=Red, BG=Blue, Border=Yellow)"
  REM FG=Red (1), BG=Blue (4), Border=Yellow (3)
  RUN GFX2(PATH,"COLOR",1,4,3)
  REM Clear with new background color
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Colors changed!"
  (* GET #0,RESPONSE
  (* PRINT #PATH,"Response: "; RESPONSE
  FOR I = 1 TO WAIT_TIME
  NEXT I

  REM --- BORDER: Setting only the border color ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating BORDER: (Border=Green)"
  REM Border=Green (2)
  RUN GFX2(PATH,"BORDER",2)
  (* GET #0,RESPONSE
  (* PRINT #PATH,"Response: "; RESPONSE
  FOR I = 1 TO WAIT_TIME
  NEXT I

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
  (* GET #0,RESPONSE
  (* PRINT #PATH,"Response: "; RESPONSE
  FOR I = 1 TO WAIT_TIME
  NEXT I

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
  (* GET #0,RESPONSE
  (* PRINT #PATH,"Response: "; RESPONSE
  FOR I = 1 TO WAIT_TIME
  NEXT I

  REM --- LINE: Drawing straight lines ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating LINE: (Drawing green lines)"
  REM Green foreground
  RUN GFX2(PATH,"COLOR",2,0,0)
  RUN GFX2(PATH,"LINE",50,50,590,150)
  RUN GFX2(PATH,"LINE",590,50,50,150)
  RUN GFX2(PATH,"LINE",320,20,320,180)
  (* GET #0,RESPONSE
  (* PRINT #PATH,"Response: "; RESPONSE
  FOR I = 1 TO WAIT_TIME
  NEXT I

  REM --- BOX: Drawing rectangular outlines ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating BOX: (Drawing yellow rectangles)"
  REM Yellow foreground
  RUN GFX2(PATH,"COLOR",3,0,0)
  RUN GFX2(PATH,"BOX",100,50,200,100)
  RUN GFX2(PATH,"BOX",250,75,400,125)
  RUN GFX2(PATH,"BOX",450,100,550,150)
  (* GET #0,RESPONSE
  (* PRINT #PATH,"Response: "; RESPONSE
  FOR I = 1 TO WAIT_TIME
  NEXT I

  REM --- BAR: Drawing filled rectangles ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating BAR: (Drawing filled blue rectangles)"
  REM Blue foreground
  RUN GFX2(PATH,"COLOR",3,0,0)
  RUN GFX2(PATH,"BAR",100,50,200,100)
  RUN GFX2(PATH,"BAR",250,75,400,125)
  RUN GFX2(PATH,"BAR",450,100,550,150)
  (* GET #0,RESPONSE
  (* PRINT #PATH,"Response: "; RESPONSE
  FOR I = 1 TO WAIT_TIME
  NEXT I

  REM --- CIRCLE: Drawing circular outlines ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating CIRCLE: (Drawing magenta circles)"
  REM Magenta foreground
  RUN GFX2(PATH,"COLOR",5,0,0)
  RUN GFX2(PATH,"CIRCLE",150,100,50)
  RUN GFX2(PATH,"CIRCLE",320,100,80)
  RUN GFX2(PATH,"CIRCLE",490,100,50)
  (* GET #0,RESPONSE
  (* PRINT #PATH,"Response: "; RESPONSE
  FOR I = 1 TO WAIT_TIME
  NEXT I

  REM --- FCIRCLE: Drawing filled circles ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating FCIRCLE: (Drawing filled cyan circles)"
  REM Cyan foreground
  RUN GFX2(PATH,"COLOR",6,0,0)
  RUN GFX2(PATH,"FCIRCLE",150,100,50)
  RUN GFX2(PATH,"FCIRCLE",320,100,80)
  RUN GFX2(PATH,"FCIRCLE",490,100,50)
  (* GET #0,RESPONSE
  (* PRINT #PATH,"Response: "; RESPONSE
  FOR I = 1 TO WAIT_TIME
  NEXT I

  REM --- ELLIPSE: Drawing elliptical outlines ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating ELLIPSE: (Drawing white ellipses)"
  REM White foreground
  RUN GFX2(PATH,"COLOR",7,0,0)
  RUN GFX2(PATH,"ELLIPSE",320,100,200,80)
  RUN GFX2(PATH,"ELLIPSE",150,100,80,40)
  RUN GFX2(PATH,"ELLIPSE",490,100,40,80)
  (* GET #0,RESPONSE
  (* PRINT #PATH,"Response: "; RESPONSE
  FOR I = 1 TO WAIT_TIME
  NEXT I

  REM --- FELLIPSE: Drawing filled ellipses ---
  RUN GFX2(PATH,"CLEAR")
  RUN GFX2(PATH,"CURXY",1,1)
  PRINT #PATH,"Demonstrating FELLIPSE: (Drawing filled light green ellipses)"
  REM Light Green foreground
  RUN GFX2(PATH,"COLOR",9,0,0)
  RUN GFX2(PATH,"FELLIPSE",320,100,200,80)
  RUN GFX2(PATH,"FELLIPSE",150,100,80,40)
  RUN GFX2(PATH,"FELLIPSE",490,100,40,80)
  (* GET #0,RESPONSE
  (* PRINT #PATH,"Response: "; RESPONSE
  FOR I = 1 TO WAIT_TIME
  NEXT I

  REM --- Cleanup ---
  REM Turn text cursor back on
  RUN GFX2(PATH,"CURON")
  REM Deallocate the graphics window
  RUN GFX2(PATH,"DWEND")
  REM Close the path to the window
  CLOSE #PATH
  PRINT "GFX2 Demo 1: Window Setup and Basic Primitives Complete!"

  RUN GFX2("SELECT")

END
