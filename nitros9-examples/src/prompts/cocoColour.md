For the Composite Colour panel, update the redBar, greenBar, and blueBar backgrounds to match the red, green, and blue component arts of the selected HSL colour value.

Also, bit number notation is 5 4 3 2 1 0 for the 6 bits in the colour code.

Composite bit value calculation should be according to the following tables of rules.  brightness and saturation are combined and set as a pair on bits 4 & 5.  Hue values should match the colour descriptions, but selected at regular intervals along the colour wheel.  Please review example table (table no. 4) with correct 6-bit binary examples and matching colour.

Update the composite panel to only select the 4 brightness/saturation pairs from a drop down and reflect the selected brightness and saturation text values.  

| bit number | label |
|-|-|
| 5-4 | brightness, saturation |
| 3-0 | hue |

| bit 5 | bit 4 | brightness | saturation |
|-|-|-|-|
| 0 | 0 | low | high |
| 0 | 1 | medium | medium |
| 1 | 0 | high | low |
| 1 | 1 | very-high | very-low |

| hue number | colour |
|-|-|
| 0 | grey |
| 1 | green |
| 2 | greenish yellow |
| 3 | yellow |
| 4 | yellowish orange |
| 5 | orange |
| 6 | reddish orange |
| 7 | red |
| 8 | reddish magenta |
| 9 | magenta |
| 10 | indigo |
| 11 | blue |
| 12 | bluish cyan |
| 13 | cyan |
| 14 | greenish cyan |
| 15 | bluish green |

| binary code | colour |
|-|-|
| 000000 | Black |
| 000111 | Dark Red |
| 011011 | Medium Blue |

For RGB Colours, the tables to use for 6-bit values are below. The first table lists the order of all three 2-bit colours values (ex: R1 for red high bit). The second table describes the colour intensity for all combination of a colour's 2-bit value, applicable to red, green, and blue.  The last table shows examples for a few RGB 6-bit values.  Please update the RGB panel to correct the 6-bit value label and any other adjustments you think necessary.

| Bit Number | Label |
|-|-|
| 5 | R1 |
| 4 | G1 |
| 3 | B1 |
| 2 | R0 |
| 1 | G0 |
| 0 | B0 |

| X1 | X0 | Intensity |
|-|-|-|
| 0 | 0 | none |
| 0 | 1 | low |
| 1 | 0 | medium |
| 1 | 1 | high |

| Colour Code | Colour | Components |
|-|-|-|
| 000000 | Black | None |
| 000111 | Dark Grey | A little of all |
| 100110 | Orange | Mostly red + little green |
| 111100 | Pink | Light grey + little red |
| 110110 | Bright Yellow | Red + green |
| 111111 | White | All |