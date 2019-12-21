@echo off
cd /D %~pd0
make -f Makefile_windows
if %ERRORLEVEL%==1 goto end
cd ..
copy bin\cd32launch ..\CD32GAMES\CDTEST\c

:end
pause
