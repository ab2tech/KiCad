:: kicad_install.bat
:: Austin Beam | Alan Bullick
:: Install AB2 KiCad components on a Windows system (tested with Windows 7)

@echo off
:: Label for starting over
:start
cls
:: Turn on default coloring
color 7
:: EnableDelayedExpansion allows for variables to expand using surrounding !
:: characters in conditionals, etc.
setlocal EnableDelayedExpansion
:: Clear these variables
set choice=
set default_kicad_install_path=

:: Determine if this is a 64-bit machine or not and base the Program Files
:: path on this for determining a default install directory
if %PROCESSOR_ARCHITECTURE%==x86 (
  set default_kicad_install_path="%ProgramFiles%\KiCad"
) else (
  set default_kicad_install_path="%ProgramFiles(x86)%\KiCad"
)
:: Remove those damn quotes
set default_kicad_install_path=%default_kicad_install_path:"=%
:: Set the default share path
set default_kicad_share_path=T:\AB2\KiCad

:: Ask the user for a custom path if the default one isn't correct
:get_install_path
set user_kicad_install_path=
set /p user_kicad_install_path="Path to KiCad (!default_kicad_install_path!): " 
if "!user_kicad_install_path!"=="" (
  set user_kicad_install_path=!default_kicad_install_path!
)

if exist !user_kicad_install_path!\* (
  :: Label for getting the share path
  :get_share_path
  :: Set up the variables for the share directory backup path and current path
  set user_kicad_bak_path="!user_kicad_install_path!\share_orig"
  set user_kicad_install_path="!user_kicad_install_path!\share"
  set user_kicad_share_path=
  echo Sweet^^! Now that we know the KiCad install path, we need to know where
  echo you keep your real KiCad 'share' directory...
  set /p user_kicad_share_path="Path to KiCad share (!default_kicad_share_path!): "
  if "!user_kicad_share_path!"=="" (
    set user_kicad_share_path=!default_kicad_share_path!
  )

  if exist !user_kicad_share_path!\* (
    cls
    color C
    echo About to move the default share directory and replace with a symlink!
    echo move !user_kicad_install_path! !user_kicad_bak_path!
    echo mklink /D !user_kicad_install_path! !user_kicad_share_path!
	:: Label for getting the user's confirmation of the action
    :get_go_confirmation
    set /p choice="Are you cool with this (y/n)? "
    if '!choice!'=='no'  goto :exit_quit
    if '!choice!'=='n'   goto :exit_quit
    if '!choice!'=='No'  goto :exit_quit
    if '!choice!'=='NO'  goto :exit_quit
    if '!choice!'=='N'   goto :exit_quit
    if '!choice!'=='y'   goto :gogogo
    if '!choice!'=='Y'   goto :gogogo
    if '!choice!'=='yes' goto :gogogo
    if '!choice!'=='Yes' goto :gogogo
    if '!choice!'=='YES' goto :gogogo
    echo Invalid choice, try again...
    goto :get_go_confirmation
  ) else (
    echo That path doesn't appear to be valid...
    goto :get_share_path
  )
) else (
  echo That path doesn't appear to be valid...
  goto :get_install_path
)

:: Do what we set out to do
:gogogo
if exist !user_kicad_bak_path!\* goto :exit_fail
color 7
echo Result:
move !user_kicad_install_path! !user_kicad_bak_path!
if !errorlevel! GEQ 1 goto :move_error
mklink /D !user_kicad_install_path! !user_kicad_share_path!
if !errorlevel! GEQ 1 goto :link_error
pause
goto :exit_done

:: There was an error moving the original share directory
:move_error
cls
color C
echo ERROR^^!
echo There was an error moving your original share directory...
echo This was likely due to a mis-typed or mis-quoted KiCAD directory location.

echo Let's try this again...
pause
goto :start

:: There was an error linking to the actual share directory
:link_error
cls
color C
echo ERROR^^!
echo There was an error creating the link...
echo This was likely due to a mis-typed or mis-quoted KiCAD directory location.

echo Let's try this again...
goto :start
pause

:: We're exiting because the backup directory exists, don't want to overwrite it
:exit_fail
cls
color 6
echo Warning^^! share_orig exists, which means you might have run this before.
echo Exiting for your own safety...
pause
exit

:: We're exiting because we didn't do anything
:exit_quit
cls
color 6
set choice=
set /p choice="Didn't do anything since you said no...try again, perhaps (y/n)? "
if '!choice!'=='y'   goto :start
if '!choice!'=='Y'   goto :start
if '!choice!'=='yes' goto :start
if '!choice!'=='Yes' goto :start
if '!choice!'=='YES' goto :start
exit

:: We're done with no errors. Yay!
:exit_done
cls
color A
echo You're good to go^^! KiCad it up^^!
pause
exit

endlocal
