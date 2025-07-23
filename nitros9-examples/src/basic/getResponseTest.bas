PROCEDURE getResponseTest

  REM *** BASIC09 GET #1,RESPONSE Test Procedure ***
  REM This procedure demonstrates the behavior of GET #1,RESPONSE
  REM by indicating when it starts polling for keyboard input and
  REM then displaying the character that was pressed.

  REM Variable to store the pressed key
  DIM RESPONSE:STRING[1]

  REM --- Initial Setup (for console output) ---
  REM No GFX2 window needed for this simple console test.
  REM Ensure the console path (usually #1) is open for PRINT.

  PRINT "--- GET #0,RESPONSE Test ---"
  PRINT "Press any single key on your keyboard to continue..."

  REM Indicate that polling has started
  PRINT "Polling for keyboard input now..."

  REM Wait for a single character input from the keyboard
  GET #0,RESPONSE

  REM Indicate that a key was pressed and display it
  PRINT "Key pressed: ";RESPONSE
  PRINT "Test Complete."

END
