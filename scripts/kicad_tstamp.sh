#!/bin/bash
# kicad_tstamp.sh
# Austin Beam | Alan Bullick
# Generate a KiCad-formatted hex timestamp. Optionally, use the specified date
# modifier for generating the timestamp.
#
# Examples:
# $ ./kicad_tstamp.sh
# Mon Jul 21 19:26:38 CDT 2014
# 53CDAFBE

# $ ./kicad_tstamp.sh -q
# 53CDAFBE

# $ ./kicad_tstamp.sh tomorrow
# Tue Jul 22 19:26:38 CDT 2014
# 53CF013E

# $ ./kicad_tstamp.sh -q tomorrow
# 53CF013E

INVALID_PATH=127
ABORT=3
ERROR=1
SUCCESS=0

# Directory in which the script is executed
SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
# Name of the script
SCRIPTNAME=$(basename $BASH_SOURCE)

scriptecho() { builtin echo "==> $@"; }

exit() {
  es=$1;
  shift;
  [ $# -gt 0 ] && scriptecho "$@";
  builtin exit "$es";
}

printUsage() {
  echo "
Usage: $SCRIPTNAME [options]

This script generates a KiCad-compatible timestamp (hex seconds since Epoch).
Optionally, a date modifier can be used (simply a string to be passed to date as
the --date parameter). This allows the user to generate timestamps for times
like 'tomorrow' or 'next week' instead of 'now' if needed.

Options:
| OPTS        | DESCRIPTION
| -q, --quiet | Don't print the standard date format first
"
}

for arg; do
  case "$arg" in
    --help|-[hH]*) printUsage && exit 0 ;;
    --quiet) QUIET=true ;;
    -*)
      PARAMS=$(echo " $arg" | sed 's:^ -::')
      NUMPARAMS=$((${#PARAMS}-1))
      for((varnum=0;varnum<=$NUMPARAMS;varnum++)); do
        case "${PARAMS:$varnum:1}" in
          [qQ])
            QUIET=true ;;
          *)
            INVALID_PARAM=true ;;
        esac
      done
      ;;
    *)
      date --date="$arg" &> /dev/null && DATEMOD="$arg" || INVALID_PARAM=true
      ;;
  esac
done

# Check for invalid parameters
if [ ! -z "$INVALID_PARAM" ]; then
  printUsage
  exit $ERROR "Invalid parameter specified"
fi

kicad_tstamp() {
  # Print a seconds since epoch timestamp in hex
  # Optionally, specify a date modifier as well
  if [ -n "$1" ]; then
    [ -z "$QUIET" ] && date --date="$1"
    printf "%X\n" $(date --date="$1" +%s)
  else
    [ -z "$QUIET" ] && date
    printf "%X\n" $(date +%s)
  fi
}

kicad_tstamp "$DATEMOD"
