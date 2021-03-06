'Adafruit 32x16 LED Panel Demo #1
'Rev. 1.0
'Show bitmaps and/or text on up to 3 displays
'Driver is 24bpp and supports Gamma correction with white balance
'The driver uses one cog to continously refresh the panels
'Graphics also uses a cog to draw quickly to the panels.

'If you have less than 3 panels connected, this demo will still work
' But, you might want to set the "BasePin" parameters to -1 for unused panels
' otherwise the driver will output on the specified pins as if the panel were present

' Copyright (c) 2011 Rayslogic.com, LLC
' See end of file for terms of use.

CON  'Crystal settings
  _clkmode = xtal1+pll16x
  _clkfreq = 80_000_000

CON  'Pin settings
  'Driver currently supports connecting up to three panels to a single Propeller chip
  'The first panel requires 12 consecutive pins starting at "BasePin_Panel1"
  'The order of the 12 pins is:  R1, G1, B1, R2, G2, B2, A, B, C, CLK, LE, EN
  Panel1_BasePin = 4 'Driver needs 12 consecutive pins for the first panel starting with this pin (6 for color, 6 for control)
  'Use Panel1_BasePin = 4 for position "1" on the Rayslogic.com 32x16xRGB shield
   
  'A second panel requires only six additional pins for color (shares the same control pins)
  'Set Panel2_BasePin to -1 if not present
  'The order of the 6 pins is:  R1, G1, B1, R2, G2, B2  
  Panel2_BasePin = 16  'Set to -1 if not used
  'Use Panel2_BasePin = 16 for position "2" on the Rayslogic.com 32x16xRGB shield  
   
  'A third panel requires six additional pins for color (also shares the same control pins)
  'Set Panel3_BasePin to -1 if not present
  'The order of the 6 pins is:  R1, G1, B1, R2, G2, B2
  Panel3_BasePin = 22'16
  'Use Panel3_BasePin = 22 for position "2" on the Rayslogic.com 32x16xRGB shield


CON  'Initial intensity and color balance settings
  Init_Intensity = 10  'Initial intensity (range is 0 to 31)
  'A single panel draws 3 Amps on full white and with Intesity=31.
  'Current draw is linear with intensity.

  'The Adafruit panels are balanced nicely, but you can fine tune the balance with these settings.
  'The range is 0 to 255
  'The input color levels are limited to these values
  Bal_Red=255
  Bal_Green=255
  Bal_Blue=255

CON  'There are a few supported ways the panels can be arranged
  'Side-By-Side Arrangement:  Panels are in landscape orientation and side-by-side
  'with panel#1 on the left and the last panel on the right
  Arrangement_SideBySide=0
  
VAR  'Space for pre-calculated outputs (the driver cog continously outputs this to the LED panels)
  long OutputArray[32*8*8]  '32 pixels wide, 8 bits of color, 8 segments

VAR  'Variables to pass to assembly drivers
  long balance  'variable to scale input RGB values for color balance  
  long Intensity 'variable to reduce brightness by modulating the enable pin  (0..31)
  long BasePin1   'starting pin of 12 pins required for first panel
  long BasePin2   'starting pin of 6 pins required for second panel (or -1 to disable)
  long BasePin3   'starting pin of 6 pins required for third panel (or -1 to disable)
  long EnablePin456  'reserved
  long pOutputArray  'pointer to precalculated array of outputs
'  long nPanels 'Number of panels connected
  long Arrangement 'organization of panels


OBJ
   matrix : "32x16_Driver1"
   led : "32x16_Graphics1"
    'This second instance is required unless you need to scroll two things at once like we are here
   led2: "32x16_Graphics1"    'make second instance so we can scroll while showing video...

VAR
  long stack[100]  'stack space for cognew (only required when want to scroll two things at once)

DAT 'Test 24bpp Windows bitmaps to show
    'needs to be 24 bits per pixel and have a width that is an even multiple of 4
WindowsBitmap byte
        file "Lenna_big.bmp"  '72x67 pixels     'this is a very big image and uses up a great deal of the Prop's RAM\
    'Another idea might be to load this image from SD card or flash chip.
    
                
PUB Main'|'i, j, k, section, bit,bits, c0, Pin_A, Pin_EN  'Show a 1bpp bitmap
  'set initial balance and intensity
  balance:=led.RGB(Bal_Red,Bal_Green,Bal_Blue)  'set maximum brightness by dividing input, range 0 to 256
  Intensity:=Init_Intensity   'max brightness via enable too, range 0 to 31

  'set up pin configuration
  pOutputArray:=@OutputArray[0]
  BasePin1:=Panel1_BasePin
  BasePin2:=Panel2_BasePin
  BasePin3:=Panel3_BasePin

  'Set up panel arrangement
  Arrangement:=Arrangement_SideBySide

  'Start graphics support
  led.Start(@balance)
  led2.Start(@balance)  'Using a second graphics cog in this example to scroll while bouncing bitmap
  
  'Launch assembly driver cog to output precalculated data
  matrix.Start(@balance)

  Demo

PUB Demo|i  'Shows basic about functions and then scrolls text and bitmap at same time
  'draw some text like with TV_Text
  led.str(string("Hello "))
  led.dec(13)
  led.out(" ")
  led.out("$")
  led.hex(139,2)
  waitcnt(cnt+clkfreq) 'wait a second


  'clear the screen
  led.SetAllPixels(led#dk_blue)

  'Start a new cog to scroll text while we scroll a bitmap here
  cognew(ScrollText2,@stack)

  'Note: we are scrolling the bitmap the dumb way by just drawing the whole thing
  '(the driver will ignore pixels not on panels)
  
  repeat       'forever
    repeat i from 0 to 67-17 'scroll down
      led.ShowBitmap(24,-i,@WindowsBitmap)
    repeat i from 67-17 to 0  'scroll up
      led.ShowBitmap(24,-i,@WindowsBitmap)
  


PUB ScrollText2  'Scroll text

  repeat 'forever
    led2.ScrollText5x8(23,0,0,String("This is a test of the Emergency alert system, this is only a test."),led#yellow, led#dk_blue,10)
      



CON
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}

  