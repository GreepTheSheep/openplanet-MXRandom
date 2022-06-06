:: https://gist.github.com/GreepTheSheep/d95921bc9cb10287c39611bd429d9273

@echo off

:: Set here your path to 7-Zip, including 7z.exe
SET zip="C:\Program Files\7-Zip\7z.exe"

:: This will get the current directory name
for %%I in (.) do SET CurrDirName=%%~nxI

IF EXIST %CurrDirName%.op (
    del %CurrDirName%.op
)
%zip% a -mx1 -tzip %CurrDirName%.op info.toml src
