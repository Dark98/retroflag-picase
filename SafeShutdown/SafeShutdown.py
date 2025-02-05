#!/usr/bin/env python3
from gpiozero import Button, LED
import os 
from signal import pause

powerPin = 26 
powerenPin = 27 
hold = 1
power = LED(powerenPin)
power.on()

#functions that handle button events
def when_pressed():
  os.system("bash /opt/RetroFlag/SafeShutdown.sh")
  
btn = Button(powerPin, hold_time=hold)
btn.when_pressed = when_pressed
pause()