'Assembly driver for Adafruit 32x16xRGB LED panels
'Rev. 1.0 
'Copyright (C) 2011 Rayslogic.com, LLC
'Driver currently supports up to three panels in parallel
'MIT license, see end of file for terms of use

'Note:  This driver is very simple, it just continously outputs the output array to the panels

VAR  'Variables to pass to assembly drivers
  long balance  'variable to scale input RGB values for color balance  
  long Intensity 'variable to reduce brightness by modulating the enable pin  (0..31)
  long BasePin1   'starting pin of 12 pins required for first panel
  long BasePin2   'starting pin of 6 pins required for second panel (or -1 to disable)
  long BasePin3   'starting pin of 6 pins required for third panel (or -1 to disable)
  long EnablePin456  'reserved (to implement 6-panel support)
  long pOutputArray  'pointer to precalculated array of outputs  

                
PUB Start(pSettings)|i, j, k, section, bit,bits, c0, Pin_A, Pin_EN  'Show a 1bpp bitmap
  'retrieve settings
  longmove(@balance,pSettings,7)

  'Configure assembly driver pins before starting
  pinmask:=%1111_1111_1111<<BasePin1  '12 pins starting at BasePin1
  datamask:=%11_1111<<BasePin1
  clkmask:=(1<<9)<<BasePin1
  LeMask:=(1<<10)<<BasePin1  
  enmask:=(1<<11)<<BasePin1

  if (BasePin2>-1)
     'Enable second panel pins
     pinmask|=%11_1111<<BasePin2  '6 pins starting at BasePin2
     datamask:=%11_1111<<BasePin2
      
  if (BasePin3>-1)
     'Enable second panel pins
     pinmask|=%11_1111<<BasePin3  '6 pins starting at BasePin3
     datamask:=%11_1111<<BasePin3  
  
  'Launch assembly driver cog
  CogNew(@AsmEntry,pOutputArray)

  return




 
DAT  'Matrix Assembly driver
                        org     0 
AsmEntry                'Start of driver
                        mov     dira,pinmask  'enable pin outputs

MainLoop                'Start of the main display loop                '
                        mov     t1,par  'get address to pixel data (passed to assembly via cognew as parameter)
                        mov     t2,#8  'doing 8 sections
SectionLoop             'Start of section loop
                        mov     t5,#8   'there are 8 bits of color info, 3 colors for 24bpp color
BitLoop                 'For the LSB, we only do this loop one time
                        'For the MSB, we do this loop 128 times                        
                        mov     t7,#8
                        sub     t7,t5
                        mov     t8,#1
                        shl     t8,t7
                        'if t5 is 8 (LSB), then t8 will be 1
                        'if t5 is 1 (MSB), then t8 will be 128

LevelLoop               'Start of loop to output to display (doing this t8 times)
                        'This 32 rdlong, or, add loop is unrolled to make it as fast as possible
                        '#0       
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4                                               
                        '#8
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4   
                        '#16
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4  
                        '#24
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4
                        rdlong  outa,t1
                        or      outa,clkmask  'Toggle the clock
                        add     t1,#4  

                        'Latch the data
                        or      outa,lemask

                        'Point back to beginning of bit data in case doing this loop again 
                        sub     t1,#32*4
                        djnz    t8,#LevelLoop

                        'If we're done with this bit, point to next bit's data
                        add     t1,#32*4
                        djnz    t5,#Bitloop  'Do the next bit
                       
                        djnz    t2,#SectionLoop  'Do the next section
                          
                        'Start Over
                        jmp     #MainLoop                        

                                                
{
########################### Defined data ###########################
}
 

zero                    long    0                       'constants
d0                      long    $200
pinmask                 long    0  'This setting must be defined before starting cog
datamask                long    0  'This setting must be defined before starting cog
clkmask                 long    0  'This setting must be defined before starting cog
LeMask                  long    0  'This setting must be defined before starting cog  
enmask                  long    0  'This setting must be defined before starting cog

{
########################### Undefined data ###########################
}
                                                        'temp variables
t1                      res     1                       '     Used for DataPin mask     and     COG shutdown 
t2                      res     1                       '     Used for CLockPin mask    and     COG shutdown
t3                      res     1                       '     Used to hold DataValue SHIFTIN/SHIFTOUT
t4                      res     1                       '     Used to hold # of Bits
t5                      res     1
t6                      res     1
t7                      res     1
t8                      res     1


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