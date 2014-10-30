#!/bin/bash
# convert_wrl.sh
# Austin Beam | Alan Bullick
# Script to leverage blender and an associated python script to convert all AB2
# KiCad 3D models from VRML2 (.wrl) format to X3D (.x3d) format.

SCRIPTNAME="$(basename ${BASH_SOURCE[0]} .sh)"
SCRIPTDIR="$(cd $(dirname "$(readlink -f ${BASH_SOURCE[0]})"); pwd)"
WRL2X3D="${SCRIPTDIR}/blender_wrl_to_x3d.py"
LOGFILE="/dev/shm/$SCRIPTNAME"

scriptecho() { builtin echo "==> $@"; }

# Try to intelligently figure out where the KICAD directory is
[ -z "$GIT_DIR" ] \
  && KICAD="$(git rev-parse --show-toplevel)" \
  || KICAD="$(cd $GIT_DIR/..; pwd)"

# Make sure KICAD directory exists and change to it
[ -z "$KICAD" ] && exit 1 "KiCad directory doesn't exist"
cd "$KICAD" || exit 1 "Couldn't change to KiCad directory"

# Make sure dependencies exist on system
DEPS="blender"
for dep in "$DEPS"; do
  which "$dep" &> /dev/null
  [ $? -ne 0 ] && { scriptecho "$dep dependency not satisfied"; exit 1; }
done
[ -f "$WRL2X3D" ] || { scriptecho "Need '$WRL2X3D' to continue"; exit 1; }

MODELS_3D="${KICAD}/3d_models"

WRL_FILES=( $(find "$MODELS_3D" -name "*wrl") )

for wrl_file in "${WRL_FILES[@]}"; do
  # Path to the corresponding X3D file
  x3d_file="${wrl_file%*.wrl}.x3d"
  # Check to see if the X3D file exists -- if not, we'll need to create it
  if [ -f "$x3d_file" ]; then
    # Check if the WRL file has been modified -- if it has, we'll need to create
    # a new X3D file
    WRL_DIRTY=$(git status --porcelain $wrl_file 2>/dev/null)
    if [ -z "$WRL_DIRTY" ]; then
    # If it has not been modified, we still need to check if a new WRL version
    # was committed
      WRL_LAST_CHANGE=$(git log -1 --pretty=format:"%at" "$wrl_file")
      X3D_LAST_CHANGE=$(git log -1 --pretty=format:"%at" "$x3d_file")
      [ $X3D_LAST_CHANGE -ge $WRL_LAST_CHANGE ] && continue
    fi
  fi
  # Indicate that we're converting the WRL to X3D
  scriptecho "Converting '$wrl_file' to '$x3d_file'" | tee -a "$LOGFILE"
  # Use blender to convert the WRL file to X3D
  blender --background --python "$WRL2X3D" -- "$wrl_file" "$x3d_file" &>> "$LOGFILE"
done
