@echo off
setlocal enabledelayedexpansion

:: Datum im Format YYYY-MM-DD holen
for /f %%a in ('wmic os get localdatetime ^| find "."') do set datetime=%%a
set date=!datetime:~0,4!-!datetime:~4,2!-!datetime:~6,2!

:: Commit-Nachricht abfragen
set /p commitMessage=Gib die Commit-Nachricht ein: 

echo PUSH
git add .
git commit -m "%commitMessage% - %date%"
git push origin main
