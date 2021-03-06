{{


USAGE:
  • Call Start, or StartRxTx, first.
  • Be sure to set the Parallax Serial Terminal software to the baudrate specified in Start, and the proper COM port.
  • At 80 MHz, this object properly receives/transmits at up to 250 Kbaud, or performs transmit-only at up to 1 Mbaud.
  
}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  RX_PIN = 26
  TX_PIN = 27
  LIGHT_PIN = 24
OBJ
  serial : "FullDuplexSerial"
  pst : "Parallax Serial Terminal"
VAR
  BYTE picture_string[7]
  BYTE temp_current[7]
  BYTE temp_current_num
  BYTE temp_high[7]
  BYTE temp_high_num
  BYTE temp_low[7]
  BYTE temp_low_num
PUB Main   | i
  serial.Start(RX_PIN, TX_PIN, 0, 115200)
  
  dira[LIGHT_PIN] := 1               ' Set pin to output-high
  pst.Start(115200)
  serial.RxFlush  
  serial.Str(string("weathe"))  
  pst.Str(string("Transmitted: weathe"))
  pst.NewLine
  repeat i from 0 to 5
    picture_string[i] := serial.Rx
  repeat i from 0 to 5
    temp_current[i] := serial.Rx
  temp_current_num := @temp_current[4]
  repeat i from 0 to 5
    temp_high[i] := serial.Rx
  temp_high_num := @temp_high[4]  
  repeat i from 0 to 5
    temp_low[i] := serial.Rx
  temp_low_num := @temp_low[4]
  pst.Str(string("Current Temperature: "))
  pst.Str(@temp_current[4])
  pst.NewLine
  pst.Str(string("Today's High: "))
  pst.Str(@temp_high[4])
  pst.NewLine
  pst.Str(string("Today's Low: "))
  pst.Str(@temp_low[4])
  pst.NewLine   
