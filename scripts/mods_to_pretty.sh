#!/bin/bash
# mods_to_pretty.sh
# Austin Beam | Alan Bullick
# Convert all modules to .pretty format
# NOTE: Must have a recent version of KiCad installed that supports the .pretty
# format. Also, must have the lib_convert.py script in place.

SCRIPTNAME="$(basename ${BASH_SOURCE[0]} .sh)"
SCRIPTDIR="$(cd $(dirname "$(readlink -f ${BASH_SOURCE[0]})"); pwd)"

# Source the colors file if it exists
[ -f ~/.bash_colors ] && . ~/.bash_colors

# Use colors if the functionality is available
if [ "$(type -t echoColor)" == "function" ]; then
  RED="$(echoColor $RED_FG)"
  RST="$(echoColor $COLOR_RESET)"
fi

# Try to intelligently figure out where the KICAD directory is
[ -z "$GIT_DIR" ] \
  && KICAD="$(git rev-parse --show-toplevel)" \
  || KICAD="$(cd $GIT_DIR/..; pwd)"

# Make sure KICAD directory exists and change to it
[ -z "$KICAD" ] && exit 1 "KiCad directory doesn't exist"
cd "$KICAD" || exit 1 "Couldn't change to KiCad directory"

exit() {
  es=$1;
  shift;
  [ $# -gt 0 ] && scriptecho "$@";
  builtin exit "$es";
}

scriptecho() { builtin echo "==> $@"; }

# First, make sure the repository is clean. We could try to handle all the
# scenarios for a dirty repository, but it would still leave room for issues.
# Furthermore, it would require more effort to determine if our conversions
# actually did anything if the repository isn't clean.
[ -z "$(git status --porcelain)" ] || \
  exit 1 "Repository is not clean. Not safe to continue."

# Next, convert all modules.
scriptecho "Beginning module conversion"
for lib in $(ls modules/ab2*.mod); do
  scriptecho "  Converting '$lib' to '${lib%mod}pretty'"
  python scripts/lib_convert.py $lib ${lib%mod}pretty
done

# Next, modify 3D model paths to work with the newer versions of KiCad. This
# will also repair any model path changes we might have made.
scriptecho "Executing 3D model path modifications"
for file in $(ls -d -1 modules/ab2*pretty/*.kicad_mod); do
  # Point to the X3D model instead of the WRL model
  sed 's#\(\s*(model.*\).wrl#\1.x3d#g' -i "$file"
  # Remove the leading '../3d_models' path prefix since newer versions of KiCad
  # rely on environment variables and don't handle relative paths cleanly
  sed 's#\.\./3d_models/##g' -i "$file"
done

# Next, print out a list of modules that exist as .pretty modules but not in the
# older .mod libraries. Go ahead and check the last known version of these files
# out so they aren't deleted with the commit of these changes.
echo -e "${RED}==> The following modules only exist as .kicad_mod files:"
git ls-files --deleted
echo -en "${RST}"
git ls-files --deleted | xargs git checkout

# Go ahead and make sure all 3D models have been appropriately converted to X3D
bash "${SCRIPTDIR}/convert_wrl.sh"

# Finally, make a commit listing all the changes.
if [ -z "$(git status --porcelain)" ]; then
  scriptecho "No commit needed -- .pretty modules all up to date"
else
  git commit -am "modules: Mass update .pretty mods from .mod files"
fi

scriptecho "Done!"
