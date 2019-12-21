@echo off
cd /D %~PD0
set CMDLINE=C:\SysGCC\arm-eabi\bin\make -f makefile_cdslave.mak
set PROGNAME=WatchTower
%CMDLINE%
set X=%ERRORLEVEL%
pause
exit %X%
