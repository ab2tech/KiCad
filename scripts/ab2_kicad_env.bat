:: ab2_kicad_env.bat
:: Austin Beam | Alan Bullick
:: Set KiCad environment variables in Windows to use AB2Tech content
:: NOTE: This will only set these variables for the active user

@echo off
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

:: Default AB2 content location inside KiCad install directory
set default_kicad_install_path="%ProgramFiles%\KiCad\share"
:: Remove those damn quotes
set default_kicad_install_path=%default_kicad_install_path:"=%

:: Ask the user for a custom path if the default one isn't correct
:get_install_path
set user_kicad_install_path=
set /p user_kicad_install_path="Path to KiCad (!default_kicad_install_path!): " 
if "!user_kicad_install_path!"=="" (
  set user_kicad_install_path=!default_kicad_install_path!
)

:: Set the environment variables
:set_env_variables
color B
echo Configuring the following variables globally:
echo   KICAD_PTEMPLATES="%user_kicad_install_path%\template"
echo   KISYS3DMOD="%user_kicad_install_path%\3d_models"
echo   KISYSMOD="%user_kicad_install_path%\modules"

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

:gogogo
setx KICAD_PTEMPLATES "%user_kicad_install_path%\template"
if ERRORLEVEL 1 (goto exit_error)
setx KISYS3DMOD "%user_kicad_install_path%\3d_models"
if ERRORLEVEL 1 (goto exit_error)
setx KISYSMOD "%user_kicad_install_path%\modules"
if ERRORLEVEL 1 (goto exit_error)

goto exit_quit

:exit_error
color C
echo Something went wrong, try rerunning the script or setting environment variables manually.
pause
color 7
exit

:exit_quit
color A
echo We're done^^!
pause
color 7
exit
