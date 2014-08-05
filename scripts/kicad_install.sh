#!/bin/bash
# kicad_install.sh
# Austin Beam | Alan Bullick
# Install AB2 KiCad components on a Linux system (tested with Ubuntu)

INVALID_PATH=127
ABORT=3
ERROR=1
SUCCESS=0

# Directory in which the script is executed
SCRIPTDIR=$(cd $(dirname $0); pwd)
# Name of the script
SCRIPTNAME=$(basename $0)

PROFILE_INSTALL_PATH="/etc/profile.d/kicad-env.sh"

printUsage()
{
  echo "
Usage: $SCRIPTNAME [options] AB2_KICAD_PATH KICAD_INSTALL_PATH

This script installs the AB2 KiCad components into the install path specified.
It does this by creating a symbolic link from the install path to the AB2 KiCad
location. Subsequently, the script moves all the original KiCad components back
into the AB2 KiCad directory. These files will be ignored by the gitignore
configuration of the AB2 KiCad git repository, but will still function properly
with KiCad. Finally, the script will install the proper KiCad environment
variables in the profile directory ($PROFILE_INSTALL_PATH) or a
user-specified file.

NOTE: Use 'q' to quit script execution from any prompt.

Options:
-e, --env PATH    | Use PATH instead of the default path for installing KiCad
                  | environment variables. Please note that this path will be
                  | overwritten.
-f, --force       | Force overwrite when making KiCad install path backup.
-h, --help        | Print this usage information
-n, --no-action   | Don't do anything, just show what would be done
-s, --no-sync     | Don't sync the KiCad install path to the AB2 KiCad path
-y, --yes         | Yes through all prompts
"
}

scriptecho() { builtin echo "==> $@"; }

exit() {
  es=$1;
  shift;
  [ $# -gt 0 ] && scriptecho "$@";
  builtin exit "$es";
}

for arg; do
  if [ -n "$ENVPATH" ]; then
    # If we can't 'touch' the file in question, it's an invalid parameter
    # We use touch over [ -e ] because the file might not exist to begin with.
    # This will at least tell us if it's a totally invalid path or if parent
    # directories don't exist. Please note we're doing this as root so root will
    # own the file if it doesn't already exist.
    sudo touch "$arg" && PROFILE_INSTALL_PATH="$arg" || INVALID_PARAM=true
    unset ENVPATH
    continue
  fi
  case "$arg" in
    --env) ENVPATH=true ;;
    --help|-[hH]*) printUsage && exit 0 ;;
    --force) FORCE=true ;;
    --no-action) NOACT=true ;;
    --no-sync) NOSYNC=true ;;
    --yes) YES=true ;;
    -*)
      PARAMS=$(echo " $arg" | sed 's:^ -::')
      NUMPARAMS=$((${#PARAMS}-1))
      for((varnum=0;varnum<=$NUMPARAMS;varnum++)); do
        case "${PARAMS:$varnum:1}" in
          [eE])
            ENVPATH=true ;;
          [fF])
            FORCE=true ;;
          [nN])
            NOACT=true ;;
          [sS])
            NOSYNC=true ;;
          [yY])
            YES=true ;;
          *)
            INVALID_PARAM=true ;;
        esac
      done
      ;;
    *)
      # No parameter validation here to allow more specific error messages
      if [ -z "$AB2_KICAD_PATH" ]; then
        AB2_KICAD_PATH="$arg"
      elif [ -z "$KICAD_INSTALL_PATH" ]; then
        KICAD_INSTALL_PATH="$arg"
      else
        INVALID_PARAM=true
      fi
  esac
done

if [ ! -z "$INVALID_PARAM" ]; then
  printUsage
  exit $ERROR "Invalid parameter specified"
fi

resolveDir()
{
  if [ -d "$1" ]; then
    echo $(cd "$1" &> /dev/null || exit 1; pwd)
  else
    echo "$1"
  fi
}

prompt()
{
  if [ ! -z "$YES" ]; then
    return
  elif [ -z "$NOACT" ]; then
    read -n1 -p "$SCRIPTNAME: $1 " RESPONSE
    if [ "$RESPONSE" == "q" -o "$RESPONSE" == "Q" ]; then
      echo
      exit $ABORT
    elif [ ! "$RESPONSE" == "y" -a ! "$RESPONSE" == "Y" ]; then
      echo
      return $ABORT
    fi
    echo
  fi
}

backup()
{
  # Don't backup or sync if the KiCad install path is already a link. This
  # allows a user to safely rerun the KiCad install script. A manual backup will
  # be required if it's still needed in such a case, but no data should be lost
  # since the only thing being removed here is the link.
  if [ -h "$KICAD_INSTALL_PATH" ]; then
    scriptecho "Not backing up '$KICAD_INSTALL_PATH' since it is a link"
    scriptecho "Removing existing link '$KICAD_INSTALL_PATH' -> '$(readlink "$KICAD_INSTALL_PATH")'"
    prompt "Continue removing link? [y/n]" || return $?
    if [ -z "$NOACT" ]; then
      sudo rm -f "$KICAD_INSTALL_PATH" || exit $?
    fi
    NOSYNC=true
    return 0
  fi

  scriptecho "mv \"$KICAD_INSTALL_PATH\" \"${KICAD_INSTALL_PATH_ORIG}\""
  prompt "Continue backing up? [y/n]" || return $?
  if [ -z "$NOACT" ]; then
    sudo mv "$KICAD_INSTALL_PATH" "${KICAD_INSTALL_PATH_ORIG}" || exit $?
  fi
}

link()
{
  scriptecho "ln -s \"$AB2_KICAD_PATH\" \"$KICAD_INSTALL_PATH\""
  prompt "Continue linking? [y/n]" || return $?
  if [ -z "$NOACT" ]; then
    sudo ln -s "$AB2_KICAD_PATH" "$KICAD_INSTALL_PATH" || exit $?
  fi
}

sync()
{
  scriptecho "rsync -aP \"${KICAD_INSTALL_PATH_ORIG}/\" \"${AB2_KICAD_PATH}/.\""
  prompt "Continue syncing? [y/n]" || return $?
  if [ -z "$NOACT" ]; then
    rsync -aP --exclude='template/kicad.pro' \
      "${KICAD_INSTALL_PATH_ORIG}/" \
      "${AB2_KICAD_PATH}/." &> /dev/null \
      || exit $?
  fi
}

KICAD_ENVSETUP="\
# KiCad Environment Variables
# Configured by kicad_install.sh of AB2 KiCad package
export KIGITHUB=\"https://github.com/KiCad\"
export KISYSMOD=\"${KICAD_INSTALL_PATH}/modules\"
export KISYS3DMOD=\"${KICAD_INSTALL_PATH}/3d_models\""

envsetup()
{
  scriptecho "Overwrite '$PROFILE_INSTALL_PATH' with:"
  echo "$KICAD_ENVSETUP"
  prompt "Continue '$PROFILE_INSTALL_PATH' overwrite? [y/n]" || return $?
  if [ -z "$NOACT" ]; then
    echo "$KICAD_ENVSETUP" | sudo tee "$PROFILE_INSTALL_PATH"
  fi
}

# Main Execution

# Additional parameter validation
if [ -z "$AB2_KICAD_PATH" ]; then
  printUsage
  exit $ERROR "AB2 KiCad path missing"
elif [ ! -d "$AB2_KICAD_PATH" ]; then
  printUsage
  exit $INVALID_PATH "AB2 KiCad path invalid"
else
  AB2_KICAD_PATH="$(resolveDir "$AB2_KICAD_PATH")"
  scriptecho "AB2_KICAD_PATH -> \"$AB2_KICAD_PATH\""
fi

if [ -z "$KICAD_INSTALL_PATH" ]; then
  printUsage
  exit $ERROR "KiCad install path missing"
else
  KICAD_INSTALL_PATH="$(resolveDir "$KICAD_INSTALL_PATH")"
  scriptecho "KICAD_INSTALL_PATH -> \"$KICAD_INSTALL_PATH\""
fi

scriptecho "PROFILE_INSTALL_PATH -> \"$PROFILE_INSTALL_PATH\""

if [ ! -z "$NOACT" ]; then
  scriptecho "NO ACTION -- would have executed:"
else
  prompt "Check the paths above for accuracy. Continue? [y/n]" || exit $?
fi


if [ -e "$KICAD_INSTALL_PATH" ]; then
  KICAD_INSTALL_PATH_ORIG="${KICAD_INSTALL_PATH}_orig"
  if [ -e "$KICAD_INSTALL_PATH_ORIG" -a -z "$FORCE" ]; then
    exit 1 "$KICAD_INSTALL_PATH_ORIG exists -- use -f to overwrite"
  elif [ -e "$KICAD_INSTALL_PATH_ORIG" ]; then
    scriptecho "$KICAD_INSTALL_PATH_ORIG exists -- forcing overwrite"
  fi
  backup || scriptecho "'$KICAD_INSTALL_PATH' not backed up"
else
  NOSYNC=true
fi

link || scriptecho "'$KICAD_INSTALL_PATH' not linked to AB2 KiCad path"

if [ -z "$NOSYNC" ]; then
  if [ -z "$NOACT" -a -d "$KICAD_INSTALL_PATH_ORIG" ]; then
    sync || scriptecho "'$KICAD_INSTALL_PATH_ORIG' not synced into AB2 KiCad path"
  elif [ -d "$KICAD_INSTALL_PATH" ]; then
    sync || scriptecho "'$KICAD_INSTALL_PATH_ORIG' not synced into AB2 KiCad path"
  fi
fi

envsetup || scriptecho "KiCad environment not modified"

echo "
AB2 KiCad should now be in place. Double-check that results above match desired
configuration. A reboot may be required for the environment variables to take
effect."
