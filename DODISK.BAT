@echo off

REM oscopy command line: filename sector# drive

oscopy bootsect.bin 0 a:
oscopy benos.bin    1 a:
oscopy blocks.bin 512 a:
oscopy help.bin  1020 a:
