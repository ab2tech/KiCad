#!/bin/bash

INVALID_PATH=127
ABORT=3
ERROR=1
SUCCESS=0

# Directory in which the script is executed
SCRIPTDIR=$(cd $(dirname $0); pwd)
# Name of the script
SCRIPTNAME=$(basename $0)

printUsage()
{
  echo "
Usage: $SCRIPTNAME [options] AB2_KICAD_PATH KICAD_INSTALL_PATH

This script installs the AB2 KiCad components into the install path specified.
It does this by creating a symbolic link from the install path to the AB2 KiCad
location. Subsequently, the script moves all the original KiCad components back
into the AB2 KiCad directory. These files will be ignored by the gitignore
configuration of the AB2 KiCad git repository, but will still function properly
with KiCad.

Options:
-f, --force       | Force overwrite when making KiCad install path backup
-n, --no-action   | Don't do anything, just show what would be done
-s, --no-sync     | Don't sync the KiCad install path to the AB2 KiCad path
-y, --yes         | Yes through all prompts
"
}

scriptecho() { builtin echo "$SCRIPTNAME: $@"; }

exit() {
  es=$1;
  shift;
  [ $# -gt 0 ] && scriptecho "$@";
  builtin exit "$es";
}

for arg; do
  case "$arg" in
    --force) FORCE=true ;;
    --no-action) NOACT=true ;;
    --no-sync) NOSYNC=true ;;
    --yes) YES=true ;;
    -*)
      PARAMS=$(echo " $arg" | sed 's:^ -::')
      NUMPARAMS=$((${#PARAMS}-1))
      for((varnum=0;varnum<=$NUMPARAMS;varnum++)); do
        case "${PARAMS:$varnum:1}" in
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
      if [ "$arg" == "$1" ]; then
        AB2_KICAD_PATH="$arg"
      elif [ "$arg" == "$2" ]; then
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

prompt()
{
  if [ ! -z "$YES" ]; then
    return
  elif [ -z "$NOACT" ]; then
    read -n1 -p "$SCRIPTNAME: $1 " RESPONSE
    if [ ! "$RESPONSE" == "y" -a ! "$RESPONSE" == "Y" ]; then
      echo
      exit $ABORT "Aborting operation..."
    fi
    echo
  fi
}

if [ ! -z "$NOACT" ]; then
  scriptecho "NO ACTION -- would have executed:"
fi

backup()
{
  scriptecho "mv \"$KICAD_INSTALL_PATH\" \"${KICAD_INSTALL_PATH_ORIG}\""
  prompt "Continue [y/n]?"
  if [ -z "$NOACT" ]; then
    mv "$KICAD_INSTALL_PATH" "${KICAD_INSTALL_PATH_ORIG}" || exit $?
  fi
}

if [ -e "$KICAD_INSTALL_PATH" ]; then
  KICAD_INSTALL_PATH_ORIG="${KICAD_INSTALL_PATH}_orig"
  if [ -e "$KICAD_INSTALL_PATH_ORIG" -a -z "$FORCE" ]; then
    exit 1 "$KICAD_INSTALL_PATH_ORIG exists -- use -f to overwrite"
  elif [ -e "$KICAD_INSTALL_PATH_ORIG" ]; then
    scriptecho "$KICAD_INSTALL_PATH_ORIG exists -- forcing overwrite"
  fi
  backup
else
  NOSYNC=true
fi

link()
{
  scriptecho "ln -s \"$AB2_KICAD_PATH\" \"$KICAD_INSTALL_PATH\""
  prompt "Continue [y/n]?"
  if [ -z "$NOACT" ]; then
    ln -s "$AB2_KICAD_PATH" "$KICAD_INSTALL_PATH" || exit $?
  fi
}

link

sync()
{
  scriptecho "rsync -aP \"${KICAD_INSTALL_PATH_ORIG}/\" \"${AB2_KICAD_PATH}/.\""
  prompt "Continue [y/n]?"
  if [ -z "$NOACT" ]; then
    rsync -aP --exclude='template/kicad.pro' \
      "${KICAD_INSTALL_PATH_ORIG}/" \
      "${AB2_KICAD_PATH}/." &> /dev/null \
      || exit $?
  fi
}

if [ -z "$NOSYNC" ]; then
  if [ -z "$NOACT" -a -d "$KICAD_INSTALL_PATH_ORIG" ]; then
    sync
  elif [ -d "$KICAD_INSTALL_PATH" ]; then
    sync
  fi
fi

scriptecho "AB2 KiCad successfully installed. Enjoy!"
