@IF NOT DEFINED DEBUG_HELPER @ECHO OFF
echo Looking for Python 2.x
SETLOCAL
:: If python.exe is in %Path%, just validate
FOR /F "delims=" %%a IN ('where python.exe 2^> NUL') DO (
  SET need_path=0
  SET p=%%~dpa
  IF NOT ERRORLEVEL 1 CALL :validate
  IF NOT ERRORLEVEL 1 GOTO :finish
)

:: Query the 3 locations mentioned in PEP 514 for a python2 InstallPath
FOR %%K IN ( "HKCU\Software", "HKLM\SOFTWARE", "HKLM\Software\Wow6432Node") DO (
  SET need_path=1
  CALL :find-versions %%K
  :: If validate returns 0 just jump to the end
  IF NOT ERRORLEVEL 1 CALL :validate
  IF NOT ERRORLEVEL 1 GOTO :finish
)

:: Find from the common path
for /F "tokens=5" %%K in ('dir C:\Python2* ^| find /n "Python"') DO ( 
  SET need_path=1
  set p=C:\%%K\
  CALL :validate
  IF NOT ERRORLEVEL 1 GOTO :finish
)

goto :no-python

:: Find Python installations in a registry location
:find-versions
for /f "delims=" %%a in ('reg query "%~1\Python\PythonCore" /f * /k 2^> nul ^| findstr /r ^^HK ^| findstr \2.') do (
  call :read-installpath %%a
  if not errorlevel 1 exit /b 0
)
exit /b 1

:: Read the InstallPath of a given Environment Key to %p%
:: https://www.python.org/dev/peps/pep-0514/#installpath
:read-installpath
:: %%a will receive everything before ), might have spaces depending on language
:: %%b will receive *, corresponding to everything after )
:: %%c will receive REG_SZ
:: %%d will receive the path, including spaces
for /f "skip=2 tokens=1* delims=)" %%a in ('reg query "%1\InstallPath" /ve /t REG_SZ 2^> nul') do (
  for /f "tokens=1*" %%c in ("%%b") do (
    if not "%%c"=="REG_SZ" exit /b 1
    set "p=%%d"
    exit /b 0
  )
)
exit /b 1

:: Check if %p% holds a path to a real python2 executable
:validate
IF NOT EXIST "%p%python.exe" exit /B 1
:: Check if %p% is python2
"%p%python.exe" -V 2>&1 | findstr /R "^Python.2.*" > NUL
IF ERRORLEVEL 1 goto :no-python2
:: We can wrap it up
echo Python2 found in %p%
EXIT /B %ERRORLEVEL%

:no-python2
echo Python found in %p%, but it is not v2.x.
exit /B 1
:no-python
echo Could not find Python.
exit /B 1
:finish
ENDLOCAL & SET pt=%p% & SET need_path_ext=%need_path%
SET VCBUILD_PYTHON_LOCATION=%pt%python.exe
IF %need_path_ext%==1 SET Path=%pt:~0,-1%;%Path%
set need_path_ext=
EXIT /B %ERRORLEVEL%
