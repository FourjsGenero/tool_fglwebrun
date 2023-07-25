@echo off
set FGLWEBRUNDIR=%~dp0
set THISDRIVE=%~dd0
FOR %%i IN ("%CD%") DO (
  set MYDRIVE=%%~di
)
pushd %CD%
%THISDRIVE%
cd %FGLWEBRUNDIR%
fglcomp -M fglwebrun.4gl
fglcomp -M fglwebrunwatch.4gl
fglcomp -M getgdcpath.4gl
IF %errorlevel% NEQ 0 GOTO myend
popd
%MYDRIVE%
fglrun %FGLWEBRUNDIR%\fglwebrun.42m %*
:myend
