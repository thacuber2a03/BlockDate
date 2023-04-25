@echo off

set PDC="%PLAYDATE_SDK_PATH%\bin\pdc"
set SIM="%PLAYDATE_SDK_PATH%\bin\PlaydateSimulator"
set PDCFLAGS=-k

%PDC% %PDCFLAGS% .\src\ .\Playtris.pdx
if /i %1=="run" ( %SIM% .\Playtris.pdx )
