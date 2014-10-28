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

MODELS_3D="${KICAD}/3d_models"

WRL_FILES=( $(find "$MODELS_3D" -name "*wrl") )

for wrl_file in "${WRL_FILES[@]}"; do
  x3d_file="${wrl_file%*.wrl}.x3d"
  [ -f "$x3d_file" ] && continue
  scriptecho "Converting '$wrl_file' to '$x3d_file'" | tee -a "$LOGFILE"
  blender --background --python "$WRL2X3D" -- "$wrl_file" "$x3d_file" &>> "$LOGFILE"
done
