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
 
   _XINFREQ = 5_000_000                                  {Crystal frequency 5.000Mhz}       
  '(16*5Mhz) = 80.000Mhz clock

  _STACK = 1024                                         {reserve 1K of longs for stack... overkill!!}
    scale = 16_777_216                         ' 2³²÷ 256
  
CON ''Date string return format type constants..

  UkFormat = 0                                          'False (zero)
  UsaFormat = 1                                         'True (non-zero)
CON  'Pin settings
  'Driver currently supports connecting up to three panels to a single Propeller chip
  'The first panel requires 12 consecutive pins starting at "BasePin_Panel1"
  'The order of the 12 pins is:  R1, G1, B1, R2, G2, B2, A, B, C, CLK, LE, EN
  Panel1_BasePin = 4 'Driver needs 12 consecutive pins for the first panel starting with this pin (6 for color, 6 for control)
  'Use Panel1_BasePin = 4 for position "1" on the Rayslogic.com 32x16xRGB shield
   
  'A second panel requires only six additional pins for color (shares the same control pins)
  'Set Panel2_BasePin to -1 if not present
  'The order of the 6 pins is:  R1, G1, B1, R2, G2, B2  
  Panel2_BasePin = -1  'Set to -1 if not used                                                       
   
  'A third panel requires six additional pins for color (also shares the same control pins)                                            
  'Use Panel2_BasePin = 16 for position "2" on the Rayslogic.com 32x16xRGB shield  
  'Set Panel3_BasePin to -1 if not present
  'The order of the 6 pins is:  R1, G1, B1, R2, G2, B2
  Panel3_BasePin = -1'16
  'Use Panel3_BasePin = 22 for position "2" on the Rayslogic.com 32x16xRGB shield


CON  'Initial intensity and color balance settings
  Init_Intensity = 1  'Initial intensity (range is 0 to 31)
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
  byte temp
  byte XValue
  byte YValue
  byte Counter
  byte Secs                                             'Seconds passed
  byte mode
  byte page
  byte PreviousMode
  byte PreviousPage
  long color1
  long color2
  long color3
  long color4
  long alarm1
  long alarm2
  long alarm3
  long alarm4
  byte colorpalette
  byte brightness  
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
VAR
  long fulltime
  byte hour
  byte minute
  byte second
  byte tempsecond
  byte hourone
  byte hourtwo
  byte minone
  byte mintwo
  byte meridiem
  byte duty
OBJ
   matrix : "32x16_Driver1"
   led : "32x16_Graphics1"
   RTC: "RealTimeClock"
   pst : "Parallax Serial Terminal"           
   SqrWave : "SquareWave"
'  ALM : "AlarmSound"
'  temperature: "DS1620"     
PUB Main
  Init 
  repeat      
    CheckMode
    GetTime
    'CheckAlarms 
    if (mode==1 AND page==1)       
      DisplayTime
      'DisplayTemp
    elseif (mode == 1 AND page==2)
      SetTime        
    elseif (mode == 2 AND page==1)      
      led.DrawText5x8(0,0,string("Alarms"),led#green,led#black)
    elseif (mode==2 AND page==2)
      led.DrawText5x8(0,0,string("Alarm1"),led#green,led#black)
    elseif (mode == 3)
      led.DrawText5x8(0,0,string("Date"),led#red,led#black)
   ' elseif (mode==4)      
  '    led.DrawText5x8(0,0,string("Temp"),led#red,led#black)
    
    
PUB Init'|'i, j, k, section, bit,bits, c0, Pin_A, Pin_EN  'Show a 1bpp bitmap
  'set initial balance and intensity
  'set initial balance and intensity
  pst.Start(115_200)     
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
  'Launch assembly driver cog to output precalculated data
  matrix.Start(@balance)
  hour := 0
  minute := 0
  second := 0
  meridiem := 0
  mode := 1
  page := 1
  color1:=led#dimorange
  color2:=led#dimblue
  color3:=led#dimred
  PreviousMode := 1
  PreviousPage := 1 
  colorpalette := 1 
  led.SetAllPixels(led#black)
  ctra[30..26] := %01000                     ' Set mode to "POS detector"
  ctra[5..0] := 0                          ' Set APIN to 17 (P17)
  frqa := 1                                  ' Increment phsa by 1 for each clock tick
  'temperature.start(27,2,1)
  RTC.Start
  RTC.SetTime(12,00,50)                                 '10 seconds to midnight
  RTC.SetDate(6,03,15)                                 'New years eve, 2007
  dira[24] := 1
PUB TestDisplay  'Shows basic about functions and then scrolls text and bitmap at same time
  'draw some text like with TV_Text
  led.SetAllPixels(led#black) 
  DrawNumber(0,0,led#orange,GetNumArray(0))
  DrawNumber(7,0,led#orange,GetNumArray(0))
  DrawColon(15,0,led#dimwhite)
  DrawNumber(19,0,led#blue,GetNumArray(0))
  DrawNumber(26,0,led#blue,GetNumArray(0))  
  DrawMeridiem(25,11,led#red,@am)    
  waitcnt(cnt+clkfreq) 'wait a second
  led.SetAllPixels(led#black)
PUB GetBrightness | time
    dira[0] := outa[0] := 1               ' Set pin to output-high
    waitcnt(clkfreq/100_000 + cnt)          ' Wait for circuit to charge
    phsa~                                   ' Clear the phsa register
    dira[0]~                               ' Pin to input stops charging circuit
    repeat 22
      waitcnt(clkfreq/60 + cnt)        
    time := (phsa - 624) #> 0
    if (time >= 2500000)
        brightness := 1
    else
        brightness := 0            
PUB CheckMode      
  if (ina[17]==1) 'left
    mode--
    page:=1   
  if (ina[23]==1) 'right
    mode++
    page:=1
  if (ina[16]==1) 'center  
    page++
 ' if (mode:=1)
 '   SetColors
  waitcnt(cnt+clkfreq/5) 'wait a second        
  if (mode<1)
    mode:=3
  if (mode>3)
    mode:=1
  if (page<1)
    page:=2
  if (page>2)
    page:=1
  if NOT(PreviousMode == mode AND PreviousPage == page)
    led.SetAllPixels(led#black) 
  PreviousMode := mode
  PreviousPage := page
PUB ConvertTime
  return second + (minute*100) + (hour*10000)
PUB CheckAlarms
  alarm1 := 120100
  if alarm1== ConvertTime
    SoundAlarm
PUB SoundAlarm | index, pin, duration, x   
  spr[8+0] := (%00100 << 26) + 1
  dira[1]~~
  x:=0
  repeat while (x==0)
    repeat index from 0 to 2
      if (ina[16]==1)
        x:=1
      led.DrawOutline(0,0,31,15,led#white)        
      frqa := SqrWave.NcoFrqReg(1047)    
      duration := clkfreq/4        
      waitcnt(duration + cnt)
      if (ina[16]==1)
        x:=1
      led.DrawOutline (0,0,31,15,led#dimwhite)  
      frqa := SqrWave.NcoFrqReg(0)
      if (ina[16]==1)
        x:=1
      duration := clkfreq/2
      waitcnt(duration + cnt)
    duration := clkfreq/1
      waitcnt(duration + cnt)
  led.DrawOutline (0,0,31,15,led#black)       
PUB SetColors       
'  if (ina[20]==1) 'up    
'    colorpalette++
'  elseif (ina[18]==1) 'down
'    colorpalette-- 
'  if (colorpalette<1)
'    colorpalette:=4
'  if (colorpalette>4)
'    colorpalette:=1
  if (colorpalette==1 and brightness==0)
    color1:=led#orange
    color2:=led#blue
    color3:=led#red
    color4:=led#white
    outa[24] := 1
  if (colorpalette==1 and brightness==1)
    color1:=led#dimorange
    color2:=led#dimblue
    color3:=led#dimred
    color4:=led#dimwhite
    outa[24] := 0
    
'  if (colorpalette==2)
'    color1:=led#red
'    color2:=led#purple
'    color3:=led#blue
'  if (colorpalette==3)
'    color1:=led#green
'    color2:=led#blue
'    color3:=led#yellow
'  if (colorpalette==4)
'    color1:=led#green
'    color2:=led#red
'    color3:=led#green     
PUB SetTime  | select
   select:=1 
  repeat while ina[16]==0   
    if (ina[17]==1) 'left
      select--
      led.DrawRect (0,5,6,5,led#black)
      led.DrawRect (10,5,16,5,led#black)
      led.DrawRect (0,13,6,13,led#black)
      led.DrawRect (10,13,16,13,led#black)
      led.DrawRect (20,13,26,13,led#black)       
    elseif (ina[23]==1) 'right
      select++
      led.DrawRect (0,5,6,5,led#black)
      led.DrawRect (10,5,16,5,led#black)
      led.DrawRect (0,13,6,13,led#black)
      led.DrawRect (10,13,16,13,led#black)
      led.DrawRect (20,13,26,13,led#black)  
    if (select>2)
      select:=1
    elseif (select<1)
      select:=2
    if (select==1)
      led.DrawRect (0,5,6,5,color4)
      if (ina[18]==1) 'up    
        hour++
      elseif (ina[20]==1) 'down
        hour--
    elseif (select==2)
      led.DrawRect (10,5,16,5,color4)
      if (ina[18]==1) 'up    
        minute++
      elseif (ina[20]==1) 'down
        minute--
    {{elseif (select==3)
      led.DrawRect (0,13,6,13,led#white)
      if (ina[20]==1) 'up    
        month++
      elseif (ina[18]==1) 'down
        month--
    elseif (select==4)
      led.DrawRect (10,13,16,13,led#white)
      if (ina[20]==1) 'up    
        day++
      elseif (ina[18]==1) 'down
        day--
    elseif (select==5)
      led.DrawRect (20,13,26,13,led#white)
      if (ina[20]==1) 'up    
        year++
      elseif (ina[18]==1) 'down
        year--  }}
           
    ProcessTime    
    if (hourone == 0)
      led.DrawChar3x5(0,0,hourone,led#black,led#black)
      led.DrawChar3x5(4,0,hourtwo,color1,led#black)
    else
      led.DrawChar3x5(0,0,hourone,color1,led#black)
      led.DrawChar3x5(4,0,hourtwo,color1,led#black)      
    led.DrawChar3x5(7,0,":",color4,led#black)
    led.DrawChar3x5(10,0,minone,color2,led#black)
    led.DrawChar3x5(14,0,mintwo,color2,led#black)       
    if (meridiem == 0)
      led.DrawText3x5(18,0,STRING("AM"),color3,led#black)
    else
      led.DrawText3x5(18,0,STRING("PM"),color3,led#black)
    
    {{led.DrawText3x5(0,8,monthone,color1,led#black)
    led.SetPixel(8,10,led#white)
    led.DrawText3x5(10,8,dayone,color2,led#black)
    led.SetPixel(18,10,led#white)
    led.DrawText3x5(20,8,yearone,color3,led#black) }} 
    waitcnt(cnt+clkfreq/5) 'wait a second 
  RTC.SetTime(hour,minute,0)
  'RTC.SetDate(day,month,year+2000)                               
  page:=1
  mode:=1
  led.SetAllPixels(led#black) 
       
PUB GetTime
  tempsecond := RTC.ReadTimeReg(0)                          'Read current second
  minute := RTC.ReadTimeReg(1)
  hour := RTC.ReadTimeReg(2)
  ProcessTime
PUB ProcessTime|hourtemp
  if (hour > 24)
    hour:=1
  elseif(hour<1)
    hour:=24
  if (minute > 59)
    minute:=0
  elseif(minute<0)
    minute:=59    
  if (hour > 12)
      hourtemp:=hour-12
      meridiem:=1
  else
    hourtemp:=hour
    meridiem:=0
  if (hour == 24)
    meridiem:=0
  if (hour == 12)
    meridiem:=1    
  hourone := hourtemp/10
  hourtwo := hourtemp//10
  minone := minute/10
  mintwo := minute//10
   
PUB DisplayTime
  if NOT(tempsecond == second)
      second := tempsecond
      if ((second//2) == 0)
        GetBrightness
        SetColors
      if (hourone == 0)
        DrawNumber(0,0,led#black,GetNumArray(1))
        DrawNumber(7,0,color1,GetNumArray(hourtwo))
      else
        DrawNumber(0,0,color1,GetNumArray(hourone))
        DrawNumber(7,0,color1,GetNumArray(hourtwo))
      DrawColon(15,0,color4)    
      DrawNumber(19,0,color2,GetNumArray(minone))
      DrawNumber(26,0,color2,GetNumArray(mintwo))   
      if (meridiem == 0)
        DrawMeridiem(25,11,color3,@am)
      else
        DrawMeridiem(25,11,color3,@pm)  
{{PUB DisplayTemp | tempnum1, tempnum2
  tempnum1 :=  temperature.gettempf/100
  tempnum2 :=  (temperature.gettempf/10)//10
  led.DrawChar3x5(0,11,tempnum1,color2,led#black)
  led.DrawChar3x5(4,11,tempnum2,color2,led#black)
  led.SetPixel(8,11,color2)
  led.DrawText3x5(10,11,String("F"),color2,led#black)   }}    
PUB DrawNumber(XStart, YStart, Color, Num)
   repeat YValue from YStart to YStart+9
    repeat XValue from XStart to XStart+5
         temp := BYTE[Num+((YValue-YStart)*6)][XValue-XStart]
         if temp == 1
            led.SetPixel(XValue,YValue,Color)
         else
            led.SetPixel(XValue,YValue,led#black)
PUB DrawMeridiem(XStart, YStart, Color, Num)
  repeat YValue from YStart to YStart+4
    repeat XValue from XStart to XStart+6
         temp := BYTE[Num+((YValue-YStart)*7)][XValue-XStart]
         if temp == 1
            led.SetPixel(XValue,YValue,Color)
         else
            led.SetPixel(XValue,YValue,led#black)
PUB DrawColon(XStart, YStart, Color)
   repeat YValue from YStart to YStart+9
    repeat XValue from XStart to XStart+1
         temp := BYTE[@colon+((YValue-YStart)*2)][XValue-XStart]
         if temp == 1
            led.SetPixel(XValue,YValue,Color)
         else
            led.SetPixel(XValue,YValue,led#black)
PUB GetNumArray (Num)
  if Num == 1
    return @numberone
  elseif Num == 2
    return @numbertwo
  elseif Num == 3
    return @numberthree
  elseif Num == 4
    return @numberfour
  elseif Num == 5
    return @numberfive
  elseif Num == 6
    return @numbersix
  elseif Num == 7
    return @numberseven
  elseif Num == 8
    return @numbereight
  elseif Num == 9
    return @numbernine
  else
    return @numberzero

DAT
Text byte "1", 0
input byte 0
numberone     byte 0,1,1,1,0,0
              byte 1,1,1,1,0,0
              byte 0,0,1,1,0,0
              byte 0,0,1,1,0,0
              byte 0,0,1,1,0,0
              byte 0,0,1,1,0,0
              byte 0,0,1,1,0,0
              byte 0,0,1,1,0,0
              byte 1,1,1,1,1,1
              byte 1,1,1,1,1,1

numbertwo     byte 0,1,1,1,1,0
              byte 1,1,1,1,1,1
              byte 1,1,0,0,1,1
              byte 0,0,0,0,1,1
              byte 0,0,0,1,1,0
              byte 0,0,1,1,0,0
              byte 0,1,1,0,0,0
              byte 1,1,0,0,0,0
              byte 1,1,1,1,1,1
              byte 1,1,1,1,1,1
              
numberthree   byte 0,1,1,1,1,0
              byte 1,1,1,1,1,1
              byte 1,1,0,0,1,1
              byte 0,0,0,0,1,1
              byte 0,0,1,1,1,0
              byte 0,0,1,1,1,0
              byte 0,0,0,0,1,1
              byte 1,1,0,0,1,1
              byte 1,1,1,1,1,1
              byte 0,1,1,1,1,0

numberfour    byte 1,1,0,0,1,1
              byte 1,1,0,0,1,1
              byte 1,1,0,0,1,1
              byte 1,1,0,0,1,1
              byte 1,1,1,1,1,1
              byte 1,1,1,1,1,1
              byte 0,0,0,0,1,1
              byte 0,0,0,0,1,1
              byte 0,0,0,0,1,1
              byte 0,0,0,0,1,1
              
numberfive    byte 1,1,1,1,1,1
              byte 1,1,1,1,1,1
              byte 1,1,0,0,0,0
              byte 1,1,0,0,0,0
              byte 1,1,1,1,1,0
              byte 1,1,1,1,1,1
              byte 0,0,0,0,1,1
              byte 0,0,0,0,1,1
              byte 1,1,1,1,1,1
              byte 1,1,1,1,1,0
              
numbersix     byte 0,0,0,1,1,0
              byte 0,0,1,1,0,0
              byte 0,1,1,0,0,0
              byte 1,1,0,0,0,0
              byte 1,1,1,1,1,0
              byte 1,1,1,1,1,1
              byte 1,1,0,0,1,1
              byte 1,1,0,0,1,1
              byte 1,1,1,1,1,1
              byte 0,1,1,1,1,0
              
numberseven   byte 1,1,1,1,1,1
              byte 1,1,1,1,1,1
              byte 0,0,0,0,1,1
              byte 0,0,0,1,1,0
              byte 0,0,0,1,1,0
              byte 0,0,1,1,0,0
              byte 0,0,1,1,0,0
              byte 0,1,1,0,0,0
              byte 0,1,1,0,0,0
              byte 1,1,0,0,0,0
              
numbereight   byte 0,1,1,1,1,0
              byte 1,1,1,1,1,1
              byte 1,1,0,0,1,1
              byte 1,1,0,0,1,1
              byte 0,1,1,1,1,0
              byte 0,1,1,1,1,0
              byte 1,1,0,0,1,1
              byte 1,1,0,0,1,1
              byte 1,1,1,1,1,1
              byte 0,1,1,1,1,0
              
numbernine    byte 0,1,1,1,1,0
              byte 1,1,1,1,1,1
              byte 1,1,0,0,1,1
              byte 1,1,0,0,1,1
              byte 1,1,1,1,1,1
              byte 0,1,1,1,1,1
              byte 0,0,0,0,1,1
              byte 0,0,0,0,1,1
              byte 0,0,0,0,1,1
              byte 0,0,0,0,1,1
              
numberzero    byte 0,1,1,1,1,0
              byte 1,1,1,1,1,1
              byte 1,1,0,0,1,1
              byte 1,1,0,0,1,1
              byte 1,1,0,0,1,1
              byte 1,1,0,0,1,1
              byte 1,1,0,0,1,1
              byte 1,1,0,0,1,1
              byte 1,1,1,1,1,1
              byte 0,1,1,1,1,0
              
colon         byte 0,0
              byte 0,0
              byte 1,1
              byte 1,1
              byte 0,0
              byte 0,0
              byte 1,1
              byte 1,1
              byte 0,0
              byte 0,0

pm            byte 1,1,0,0,1,0,1
              byte 1,0,1,0,1,1,1
              byte 1,1,0,0,1,1,1
              byte 1,0,0,0,1,0,1
              byte 1,0,0,0,1,0,1

am            byte 0,1,0,0,1,0,1
              byte 1,0,1,0,1,1,1
              byte 1,1,1,0,1,1,1
              byte 1,0,1,0,1,0,1
              byte 1,0,1,0,1,0,1              
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

  