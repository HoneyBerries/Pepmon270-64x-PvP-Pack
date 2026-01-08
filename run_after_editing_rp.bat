@echo off
rem run_after_editing_rp.bat — AUTO-SAFE commit + push for Minecraft resource packs
rem Run this AFTER you finish editing
rem
rem Behavior (VERY ROBUST):
rem   - ALWAYS stages everything (git add -A)
rem   - Auto-generates a timestamped commit message
rem   - Asks for an optional note
rem   - Commits and pushes

setlocal EnableExtensions EnableDelayedExpansion
if not defined PATH (set PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem)

title Resource Pack Publish

:: sanity check: git repo
git rev-parse --is-inside-work-tree >nul 2>&1 || (
  echo ERROR: This folder is not a git repository.
  goto :end
)

:: branch + remote
set REMOTE=origin
for /f "usebackq tokens=*" %%b in (`git rev-parse --abbrev-ref HEAD`) do set BRANCH=%%b

:: check if there are ANY changes at all
git status --porcelain >nul
if errorlevel 1 (
  echo ERROR: git status failed.
  goto :end
)

for /f "delims=" %%l in ('git status --porcelain') do (
  set HAS_CHANGES=1
  goto :hasChanges
)

echo No changes detected. Nothing to publish.
goto :end

:hasChanges

:: timestamp (locale-independent)
for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set TS=%%i
set BASE_MSG=Update resource pack (%TS%)

:: optional note
echo Default commit message:
echo   %BASE_MSG%
echo.
set /p NOTE=Add a note (optional, press Enter to skip): 

if not "%NOTE%"=="" (
  set FINAL_MSG=%BASE_MSG% - %NOTE%
) else (
  set FINAL_MSG=%BASE_MSG%
)

echo.
echo === Publishing Resource Pack ===
echo Branch : %BRANCH%
echo Remote : %REMOTE%
echo Commit : %FINAL_MSG%
echo.

git status --short

echo.

:: DRY RUN SUPPORT
if "%DRY_RUN%"=="1" (
  echo DRY RUN: git add -A
  echo DRY RUN: git commit -m "%FINAL_MSG%"
  echo DRY RUN: git push %REMOTE% %BRANCH%
  goto :end
)

:: HARD GUARANTEE: stage everything
echo Staging all changes...
git add -A || goto :gitfail

:: verify staging
git diff --cached --quiet && (
  echo ERROR: Nothing staged after git add -A.
  echo This usually means files are ignored by .gitignore.
  goto :end
)

:: commit
echo Committing...
git commit -m "%FINAL_MSG%" || goto :gitfail

:: push
echo Pushing to cloud...
git push %REMOTE% %BRANCH% || goto :gitfail

echo Publish complete!

goto :end

:gitfail
echo.
echo ERROR: Git command failed (errorlevel %errorlevel%).
echo Scroll up to see the exact error message.
goto :end

:end
if not defined NO_PAUSE (
  echo.
  echo (Press any key to close...)
  pause >nul
)
endlocal
