@echo off
rem sync_remote.bat — pull/sync remote changes into the current folder
rem Usage:
rem   sync_remote.bat [remote] [branch]
rem     remote default: origin
rem     branch default: current HEAD branch
rem Optional env vars:
rem   DRY_RUN=1   -> only print commands
rem   MODE=ff     -> use fast-forward only (git pull --ff-only)
rem   MODE=rebase -> (default) use git pull --rebase
rem   NO_PAUSE=1  -> skip pause

setlocal enabledelayedexpansion
if not defined PATH (set PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem)

:: ensure git
where git >nul 2>&1 || (
  echo Error: git not found in PATH.
  goto :end
)

git rev-parse --is-inside-work-tree >nul 2>&1 || (
  echo Error: This folder is not a git repository.
  goto :end
)

set REMOTE=%~1
if "%REMOTE%"=="" set REMOTE=origin

:: branch argument (second) overrides current
set ARG_BRANCH=%~2
for /f "usebackq tokens=*" %%b in (`git rev-parse --abbrev-ref HEAD 2^>nul`) do set CUR_BRANCH=%%b
if not defined CUR_BRANCH (
  echo Error: Unable to determine current branch.
  goto :end
)
if not "%ARG_BRANCH%"=="" (
  set BRANCH=%ARG_BRANCH%
) else (
  set BRANCH=%CUR_BRANCH%
)

if "%MODE%"=="" set MODE=rebase
if /i "%MODE%"=="rebase" (
  set PULL_FLAGS=--rebase
) else if /i "%MODE%"=="ff" (
  set PULL_FLAGS=--ff-only
) else (
  echo Invalid MODE value "%MODE%". Use rebase or ff.
  goto :end
)

echo --- Sync Script ---
echo Remote : %REMOTE%
echo Branch : %BRANCH%
echo Mode   : %MODE% (%PULL_FLAGS%)

if "%DRY_RUN%"=="1" (
  echo DRY RUN: git fetch %REMOTE% %BRANCH%
  echo DRY RUN: git checkout %BRANCH%
  echo DRY RUN: git pull %PULL_FLAGS% %REMOTE% %BRANCH%
  goto :end
)

echo Fetching...
git fetch %REMOTE% %BRANCH% || goto :gitfail

echo Checking out branch %BRANCH% ...
git checkout %BRANCH% || goto :gitfail

echo Pulling latest changes (mode=%MODE%)...
git pull %PULL_FLAGS% %REMOTE% %BRANCH% || goto :gitfail

echo Updating submodules (if any)...
git submodule update --init --recursive 2>nul

echo Sync complete.
goto :end

:gitfail
echo.
echo ERROR: A git command failed (errorlevel %errorlevel%).

goto :end

:end
if not defined NO_PAUSE (
  echo.
  echo (Press any key to close...)
  pause >nul
)
endlocal
