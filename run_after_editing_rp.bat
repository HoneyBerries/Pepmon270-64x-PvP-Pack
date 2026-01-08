@echo off
rem run_after_editing_rp.bat — auto-commit and push Minecraft resource pack changes
rem Run this AFTER you finish editing
rem
rem Behavior:
rem   - Automatically commits all tracked changes (git commit -am)
rem   - Then asks for an optional note to append to the message
rem
rem Optional env vars:
rem   DRY_RUN=1   -> only print commands
rem   NO_PAUSE=1  -> skip pause at end

setlocal enabledelayedexpansion
if not defined PATH (set PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem)

title Resource Pack Publish

:: ensure git repo
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

:: check for tracked changes only
git diff --quiet && git diff --cached --quiet && (
  echo No changes detected. Nothing to publish.
  goto :end
)

:: build auto commit message (locale-safe)
for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm"') do set TS=%%i
set AUTO_MSG=Update resource pack (%TS%)

:: optional note
echo Default commit message:
echo   %AUTO_MSG%
echo.
set /p NOTE=Add a note? (optional, press Enter to skip): 
if not "%NOTE%"=="" (
  set FINAL_MSG=%AUTO_MSG% - %NOTE%
) else (
  set FINAL_MSG=%AUTO_MSG%
)

echo.
echo === Publishing Resource Pack ===
echo Branch : %BRANCH%
echo Remote : %REMOTE%
echo Commit : %FINAL_MSG%
echo.

git status --short

echo.
if "%DRY_RUN%"=="1" (
  echo DRY RUN: git commit -am "%FINAL_MSG%"
  echo DRY RUN: git push %REMOTE% %BRANCH%
  goto :end
)

echo Committing tracked changes...
git commit -am "%FINAL_MSG%" || goto :gitfail

echo Pushing to cloud...
git push %REMOTE% %BRANCH% || goto :gitfail

echo Publish complete!

goto :end

:gitfail
echo.
echo ERROR: Publish failed (errorlevel %errorlevel%).
echo If files are new, add them once with:
 echo   git add -A
 echo   git commit -m "Initial add"
 goto :end

:end
if not defined NO_PAUSE (
  echo.
  echo (Press any key to close...)
  pause >nul
)
endlocal
