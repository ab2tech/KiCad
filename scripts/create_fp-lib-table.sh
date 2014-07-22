#!/bin/bash
# create_fp-lib-table.sh
# Austin Beam | Alan Bullick
# Create KiCad fp-lib-table based on existence of pattern-define KiCad '.pretty'
# module libraries

INVALID_PATH=127
ABORT=3
ERROR=1
SUCCESS=0

# Directory in which the script is executed
SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
# Name of the script
SCRIPTNAME=$(basename $BASH_SOURCE)

# Default output file
OUTFILE="${SCRIPTDIR}/../template/fp-lib-table"
# Default search pattern
PATTERN="ab2*.pretty"
# Default module directory
MODDIR="${SCRIPTDIR}/../modules"

scriptecho() { builtin echo "==> $@"; }

exit() {
  es=$1;
  shift;
  [ $# -gt 0 ] && scriptecho "$@";
  builtin exit "$es";
}

printUsage()
{
  echo "
Usage: $SCRIPTNAME [options]

This script creates a KiCad-compatible file in the format of fp-lib-table based
on a search pattern for the modules directory. A predefined pattern is in place
for creating an AB2-compatible fp-lib-table file. Otherwise, the user can
specify his/her own pattern. By default, this file is placed in '$OUTFILE',
but this is also user-customizable.

NOTE: While the MODDIR is user-definable, it is the responsiblity of the user to
ensure KISYSMOD is defined and pointed to the right place as well. For this, see
or execute kicad_install.sh.

Options:
| OPTS          | ARGS | DESCRIPTION
| -f, --force   |      | Force overwrite of existing file
| -h, --help    |      | Print this usage information
| -m, --moddir  | DIR  | Specify a module directory DIR
                         --> Default: '$MODDIR'
| -o, --output  | FILE | Specify an output file FILE
| -p, --pattern | PATT | Specify a search pattern PATT
"
}

for arg; do
  if [ -n "$MODD" ]; then
    if [ -d "$arg" ]; then
      MODDIR="$arg"
    else
      scriptecho "Invalid module directory specified"
      INVALID_PARAM=true
    fi
    unset MODD
    continue
  elif [ -n "$OUT" ]; then
    if [ ! -e "$arg" ]; then
      touch "$arg" && { OUTFILE="$arg"; WEMADEIT=true; } || INVALID_PARAM=true
    else
      OUTFILE="$arg"
    fi
    unset OUT
    continue
  elif [ -n "$PAT" ]; then
    PATTERN="$arg"
    unset PAT
    continue
  fi
  case "$arg" in
    --force) FORCE=true ;;
    --help|-[hH]*) printUsage && exit 0 ;;
    --moddir) MODD=true ;;
    --out) OUT=true ;;
    --pattern) PATTERN=true ;;
    -*)
      PARAMS=$(echo " $arg" | sed 's:^ -::')
      NUMPARAMS=$((${#PARAMS}-1))
      for((varnum=0;varnum<=$NUMPARAMS;varnum++)); do
        case "${PARAMS:$varnum:1}" in
          [fF])
            FORCE=true ;;
          [mM])
            MODD=true ;;
          [oO])
            OUT=true ;;
          [pP])
            PAT=true ;;
          *)
            INVALID_PARAM=true ;;
        esac
      done
      ;;
    *)
      INVALID_PARAM=true
  esac
done

# Check for invalid parameters
if [ ! -z "$INVALID_PARAM" ]; then
  printUsage
  exit $ERROR "Invalid parameter specified"
fi

# Abort if the output file exists and we didn't make it
[ -e "$OUTFILE" -a -z "$WEMADEIT" -a -z "$FORCE" ] && \
  { echo "'$OUTFILE' exists. Aborting."; exit 1; }

# Get the absolute path of the output file
OUTFILE="$(readlink -f "$OUTFILE")"
scriptecho "Proceeding to create '$OUTFILE'"

echo "(fp_lib_table" > "$OUTFILE"

# Change to the module directory before continuing
cd "$MODDIR"
for dir in $(find -name "$PATTERN" | sort); do
  dir="${dir#./}"
  name="${dir%.pretty}"
  echo "  (lib (name \"$name\")(type KiCad)(uri \"\${KISYSMOD}/$dir\")(options \"\")(descr \"\"))" >> "$OUTFILE"
done

echo ")" >> "$OUTFILE"
