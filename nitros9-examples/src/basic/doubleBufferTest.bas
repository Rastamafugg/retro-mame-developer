PROCEDURE doubleBufferTest

  DIM gpath:INTEGER
  DIM esc:STRING[2]
  DIM page:INTEGER

  gpath := OPEN("/G6",WRITE)
  IF gpath<0 THEN
    PRINT "Cannot open graphics mode"
    RETURN
  ENDIF

  page := 0

  REPEAT
    (* Set drawing page *)
    WRIT #gpath, CHR$(27)+"E"+CHR$(page)

    (* Clear screen on offscreen page *)
    WRITLN #gpath, CHR$(12)

    (* Draw something: e.g. bouncing box *)
    (* You'd insert a call here to your frame renderer *)

    (* Flip to visible page *)
    WRIT #gpath, CHR$(27)+"F"+CHR$(page)

    (* Swap page index *)
    page := 1 - page

    (* Add a delay *)
    FOR i:=1 TO 1000 DO NEXT

  UNTIL 0

END
