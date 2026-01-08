@echo off
rem rp_update.bat — update local Minecraft resource pack from the cloud
rem Run this BEFORE you start editing
rem
rem Optional env vars:
rem   DRY_RUN=1   -> only print commands
rem   MODE=ff     -> fast-forward only (recommended)
rem   MODE=merge  -> allow merge (default)
rem   NO_PAUSE=1  -> skip pause at end

setlocal enabledelayedexpansion
if not defined PATH (set PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem)

title Resource Pack Update

:: ensure git exists
where git >nul 2>&1 || (
  echo Error: git not found in PATH.
  goto :end
)

:: ensure we're in a git repo
git rev-parse --is-inside-work-tree >nul 2>&1 || (
  echo Error: This folder is not a git repository.
  goto :end
)

:: remote + branch
set REMOTE=origin
for /f "usebackq tokens=*" %%b in (`git rev-parse --abbrev-ref HEAD 2^>nul`) do set BRANCH=%%b
if not defined BRANCH (
  echo Error: Unable to determine current branch.
  goto :end
)

:: pull mode
if "%MODE%"=="" set MODE=ff
if /i "%MODE%"=="ff" (
  set PULL_FLAGS=--ff-only
) else if /i "%MODE%"=="merge" (
  set PULL_FLAGS=--no-rebase
) else (
  echo Invalid MODE value "%MODE%". Use ff or merge.
  goto :end
)

echo === Resource Pack Update ===
echo Branch : %BRANCH%
echo Remote : %REMOTE%
echo Mode   : %MODE%
echo.

:: refuse if working tree is dirty
for /f "delims=" %%l in ('git status --porcelain') do (
  echo ERROR: You have uncommitted changes.
  echo Please run rp_publish.bat or stash your changes first.
  echo.
  git status --short
  goto :end
)

echo Working tree clean. Updating...

if "%DRY_RUN%"=="1" (
  echo DRY RUN: git fetch %REMOTE%
  echo DRY RUN: git pull %PULL_FLAGS% %REMOTE% %BRANCH%
  goto :end
)

git fetch %REMOTE% || goto :gitfail
git pull %PULL_FLAGS% %REMOTE% %BRANCH% || goto :gitfail

echo Updating submodules (if any)...
git submodule update --init --recursive 2>nul

echo Update complete. You are safe to edit.

goto :end

:gitfail
echo.
echo ERROR: Update failed (errorlevel %errorlevel%).
echo If a merge started, you can abort with:
echo   git merge --abort
goto :end

:end
if not defined NO_PAUSE (
  echo.
  echo (Press any key to close...)
  pause >nul
)
endlocal