@echo off

set PDC="%PLAYDATE_SDK_PATH%\bin\pdc"
set SIM="%PLAYDATE_SDK_PATH%\bin\PlaydateSimulator"
set PDCFLAGS=-k

set IN=.\src
set OUT=.\BlockDate.pdx

%PDC% %PDCFLAGS% %IN% %OUT%
if /i %1=="run" ( %SIM% %OUT% )
