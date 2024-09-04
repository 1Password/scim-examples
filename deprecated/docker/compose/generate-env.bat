@echo off
rem This script generates a file called `scim.env` using the contents of a scimsession file in the current working folder.
rem This env file is used to populate the scimsession env var in the container to prevent copying the sensitive file into a container layer.

rem delete old scim.env if exists
if exist "scim.env" del /f /q "scim.env"

rem prepare beginning of the scim.env file
echo OPSCIM_SESSION=> tmp.b64

rem encode with base64 and extract the key itself
certutil -encode scimsession tmp.raw.b64 && findstr /v /c:- tmp.raw.b64 >> tmp.b64

rem concatenate all lines stripping newline characters and discarding trailing empty lines
for /F "Tokens=*" %%@ in (tmp.b64) do (
	<nul set /P "=%%@" 
) >> scim.env

rem cleanup temp files
del tmp.raw.b64
del tmp.b64
