@echo off
rem push_changes.bat — stage, commit, and push changes to the remote repository
rem Usage:
rem   push_changes.bat "your commit message" [remote]
rem   (If commit message omitted you'll be prompted.)
rem Optional env vars:
rem   DRY_RUN=1   -> only print what would happen.
rem   NO_PAUSE=1  -> do not pause at end (useful when run inside existing terminal).
rem Notes:
rem   If you double-click this file, the window would normally close instantly.
rem   Added an automatic pause so you can read any errors.

setlocal enabledelayedexpansion
if not defined PATH (set PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem)

:: ensure we are in a git repo
git rev-parse --is-inside-work-tree >nul 2>&1 || (
  echo Error: This folder is not a git repository. Open a terminal here after cloning.
  goto :end
)

:: argument parsing (first arg = commit message, may contain spaces if quoted)
set MSG=%~1
if "%MSG%"=="" (
  set /p MSG=Commit message: 
)

:: remote (second arg) default origin
set REMOTE=%~2
if "%REMOTE%"=="" set REMOTE=origin

:: current branch
for /f "usebackq tokens=*" %%b in (`git rev-parse --abbrev-ref HEAD 2^>nul`) do set BRANCH=%%b
if not defined BRANCH (
  echo Error: Unable to determine current branch.
  goto :end
)

echo --- Push Script ---
echo Branch : %BRANCH%
echo Remote : %REMOTE%
echo Message: %MSG%

:: show pending changes summary
git status --short || goto :end

:: detect if there are any changes
for /f "delims=" %%l in ('git status --porcelain') do (
  set HAS_CHANGES=1
  goto :afterScan
)
:afterScan
if not defined HAS_CHANGES (
  echo No changes detected. Nothing to commit.
  goto :end
)

if "%DRY_RUN%"=="1" (
  echo DRY RUN: git add -A
  echo DRY RUN: git commit -m "%MSG%"
  echo DRY RUN: git push %REMOTE% %BRANCH%
  goto :end
)

echo Adding changes...
git add -A || goto :gitfail
echo Committing...
git commit -m "%MSG%" || goto :gitfail
echo Pushing...
git push %REMOTE% %BRANCH% || goto :gitfail
echo Push complete.
goto :end

:gitfail
echo.
echo ERROR: A git command failed (errorlevel %errorlevel%). Scroll up for details.
goto :end

:end
if not defined NO_PAUSE (
  echo.
  echo (Press any key to close...)
  pause >nul
)
endlocal
