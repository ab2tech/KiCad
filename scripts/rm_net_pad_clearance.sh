#!/bin/bash
# rm_net_pad_clearance.sh
# Austin Beam | Alan Bullick
# Remove net pad clearance values that we shouldn't have ever added :)

# Check for dependencies
DEPS="find dos2unix sed unix2dos"
for dep in $DEPS; do
  if [ -z "$(which $dep)" ]; then
    echo "Script cannot execute...require dependency $dep"
    exit 1
  fi
done

FILESTOEDIT=( $(find modules -name ab2*.mod) )
DATEHDR="$(date "+%-m/%-d/%Y %-I:%M:%S %p")"
DATEHEX="$(printf %X $(date +%s))"
TMPFILE="/tmp/tmp-$DATEHEX"

echo() { builtin echo "$(basename $0): $@"; }
for ((i=0; i<${#FILESTOEDIT[@]}; i++)); do
  isDirty="$(grep ".LocalClearance" "${FILESTOEDIT[$i]}")"
  if [ -z "$isDirty" ]; then
    echo "${FILESTOEDIT[$i]} - no changes needed"
  else
    # We'll have to convert line endings first so sed doesn't trash them
    dos2unix "${FILESTOEDIT[$i]}" &> /dev/null
    sed -i '/^\s*.LocalClearance\s*[0-9]*\.[0-9]*\s*$/d' "${FILESTOEDIT[$i]}"
    sed -i "s|^\(PCBNEW-LibModule-V1\s\).*$|\1$DATEHDR|" "${FILESTOEDIT[$i]}"
    sed -i "/\$MODULE.*$/{
    N;
    s|\(Po [0-9]* [0-9]* [0-9]* [0-9]* \)[0-9A-Fa-f]*\( [0-9]*.*$\)|\1$DATEHEX\2|
    }" "${FILESTOEDIT[$i]}"
    # Restore the line endings
    unix2dos "${FILESTOEDIT[$i]}" &> /dev/null
    echo "${FILESTOEDIT[$i]} - removed net pad clearance value(s)"
  fi
done
