@echo off
"%PLAYDATE_SDK_PATH%\pdc" .\src\ .\Playtris.pdx
if /i %1=="run" (
	"%PLAYDATE_SDK_PATH%\PlaydateSimulator" .\Playtris.pdx
)
