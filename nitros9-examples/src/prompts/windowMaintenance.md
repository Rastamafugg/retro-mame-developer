Using the following markdown for Basic09 development for NitrOS9 EOU application development, help me draft the code for a window maintenance procedure that stores the current window information.  Then another procedure that restores the window to the original defaults, for use in setting change rollback or epplication exiting tasks. Pass information in and out of the procedures using this WININFO type:

TYPE WININFO=FORMAT:INTEGER; XSIZE:INTEGER; YSIZE:INTEGER; FOREGROUND:INTEGER; BACKGROUND:INTEGER; BORDER:INTEGER

# Establishing a Hardware Window

For your convenience, NitrOS-9 has a number of predefined or hardware window formats. Hardware windows are text windows, and you cannot use them for graphic applications. Because hardware windows are predefined, you can easily establish them with the INIZ command. For instance, to establish Window 7, type:

`iniz /w7[ENTER]`

However, you cannot see the window until you send a message to it. Type:

`echo Hello Window 7 > /w7[ENTER]`

Now, to see the window and your message press `[CLEAR]`. To return to the original screen, press `[CLEAR]` again.

To NitrOS-9, a window is a device and you can send data to it. To view the Errmsg file in the SYS directory of your system diskette, list it to Window 7 by typing: `list sys/errmsg > /w7[ENTER]` to move to Window 7 and see the listing. Press `[SHIFT][CLEAR]` to return to the previous screen.

You can also fork a shell (an execution environment) to a window. To cause a shell to operate in window 7, type:

`shell i=/w7&[ENTER]`

The `i=` function of SHELL tells NitrOS-9 that the window is immortal. It does not die after completing a task. To operate NitrOS-9 from the window, press `[CLEAR]`. Besides window 7, you have six other predefined windows. The following chart shows all the hardware windows and their parameters:

| Window Number | Screen Size (Chars/line) | Starting Coordinates (X,Y) | Window Cols | Window Rows |
|---------------|--------------------------|----------------------------|-------------|-------------|
| 1 | 80 | 0,0 | 80 | 25 |
| 2 | 80 | 0,0 | 80 | 25 |
| 3 | 80 | 0,0 | 80 | 25 |
| 4 | 80 | 0,0 | 80 | 25 |
| 5 | 80 | 0,0 | 80 | 25 |
| 6 | 80 | 0,0 | 80 | 25 |
| 7 | 80 | 0,0 | 80 | 25 |

The /TERM window can be set in /dd/sys/env.file, by changing the settings for CONDVTYP, CONXSIZ, CONYSIZ, CONFCLR, CONBCLR, and CONBDCLR, and this will change /TERM's setting as NitrOS-9 boots.

# Defining Windows

As well as hardware windows, NitrOS-9 also lets you establish windows to your own specifications. You can set definable windows for either text or graphics, or both. You can locate them anywhere on a screen, and you can make them any size.

You initialize definable windows in the same manner you initialize hardware windows, using INIZ. If you want to have text on the window, you must merge SYS/Stdfonts (found on your system diskette) with the window (NitrOS-9/EOU pre-loads these fonts for you on boot). You can also establish a shell in a definable window, from which you can use NitrOS-9 or BASIC09.

To establish definable windows you must supply NitrOS-9 with information about the type of window you want (its graphic format), its size, and its location on the screen. The easiest way to do this is with the NitrOS-9 WCREATE command.

WCREATE requires a window format code in the form -s=format code to tell NitrOS-9 what type of a window you want. The following chart shows the possible window formats you can choose:

### Table 9.5

| Format Code | Screen Size (Cols x Rows) | Resolution (Width/Height) | No. of Colours | Memory Required | Screen Type |
|-------------|---------------------------|---------------------------|----------------|-----------------|-------------|
| 01 | 40 x 25 | ——— | 16† | 2000 | Text |
| 02 | 80 x 25 | ——— | 16† | 4000 | Text |
| 05 | 80 x 25 | 640 x 200 | 2 | 16000 | Graphics |
| 06 | 40 x 25 | 320 x 200 | 4 | 16000 | Graphics |
| 07 | 80 x 25 | 640 x 200 | 4 | 32000 | Graphics |
| 08 | 40 x 25 | 320 x 200 | 16 | 32000 | Graphics |
| 00* | Specifies the Processes' current screen. |
| FF | Currently displayed screen. Use when putting several windows on the same physical screen when setting them up from a procedure file. Applications should use $00 instead. |

† You have to reconfigure the palette to get 16 colors rather than the default of eight colors. The following section provides information on the palette.

Format Codes 01 and 02 select text screens, and Format Codes 5-8 select graphics screens. The Screen Size column shows the maximum number of text columns and rows available for each screen. The Resolution column shows the maximum pixels (graphic units) available for each of the graphic screens. The Memory column shows how much memory NitrOS-9 must set aside for each screen format. Memory requirements depend on the resolution and number of colors selected for a window.

## The Palette

BASIC09 has 64 colors you can select for screen displays. The colors are available through a palette. The Color Computer’s palette can hold 16 colors at once. The following chart shows the default colors for the palette in Screen Format 7:

### Table 9.6

| Register | Color | Register | Color |
|----------|-------|----------|-------|
| 00 | Black | 08 | Black |
| 01 | Red | 09 | Green |
| 02 | Green | 10 | Black |
| 03 | Yellow | 11 | Buff |
| 04 | Blue | 12 | Black |
| 05 | Magenta | 13 | Green |
| 06 | Cyan | 14 | Black |
| 07 | White | 15 | Orange |

Instead of the default colors, you can select any of the 64 colors (0-63) for any of the palette registers. You do this using the PALETTE command described later in this chapter. The BORDER and COLOR commands also affect the colors available in the palette by changing the color in the background and foreground registers, Registers 02 and 03, respectively.

# GFX2 API

## **WINFO** Returns window information about the current window

### *Syntax*: 

`RUN GFX2([path,]"WINFO",format,xsize,ysize,foreground,background,border)`

### *Function*: 

Returns the screen type, window size and current foreground, background and border colors for the process's window (or window on the optional path). Very useful for writing programs that adapt to the size of the window that they are run on.

### *Parameters*:

- *format* - Screen type. See Table 9.5 at the beginning of this section.
- *xsize* - Current working area window width.
- *ysize* - Current working area window height.
- *foreground* - Foreground color.
- *background* - Background color.
- *border* - Border color.

### *Examples*:

`RUN GFX2("WINFO",sctype,curwidth,curheight,fgcolor,bkcolor,brdcolor)`

## **DWEND** Device window end

### *Syntax*: 

`RUN GFX2([path,]"DWEND")`

### *Function*: Deallocates the device window you initialized with DWSET and INIZ.

If the window deallocated is the last device window on the screen, BASIC09 returns the screen memory to the system. DWEND automatically positions you in the next device window, a result similar to pressing [CLEAR]. You can use this function with DWSET to redefine a device window to a different type.

### *Parameters*:

- *path* - The path number of the window you wish to end. Path can be a constant or variable.

### *Examples*:

`RUN GFX2("DWEND")`

`RUN GFX2(PATH,"DWEND")`

`RUN GFX2(3,"DWEND")`

## **DWSET** Device window set

### *Syntax*: 

`RUN GFX2([path,)“DWSET”,format,xcor,ycor,width,height,foreground, background, border)`

### *Function*: 

Defines a device window. Normally, you first open a path to a window, then use DWSET to set the window format, location, size, and colors.

### *Parameters*:

- *path* - The route to the window you are defining.
- *format* - The code for the type of screen you want to establish. See Table 9.5 at the beginning of this section for the formats available.
- *xcor,ycor* - The coordinates (character column and row) of the upper left corner of the screen you want to create.
- *width* - The width (in characters) of the new window.
- *height* - The height (in lines) of the new window.
- *foreground* - The code for the window's foreground color.
- *background* - The code for the window’s background color.
- *border* - The code for the window’s border color.

### *Examples*:

`RUN GFX2("DWSET",06,50,100,50,10,20,12,9)`