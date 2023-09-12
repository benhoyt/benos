@echo off
tasm bootsect
tlink /x /k bootsect
exe2bin bootsect.exe bootsect.bin
del bootsect.exe
del bootsect.obj
oscopy bootsect.bin 0 a:
