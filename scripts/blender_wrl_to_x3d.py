#!/usr/bin/env python
# blender_wrl_to_x3d.py
# Austin Beam | Alan Bullick
# Basic blender script to convert VRML2 to X3D, which renders more nicely in
# recent versions of KiCad

import bpy
import sys

argv = sys.argv
argv = argv[argv.index("--") + 1:] # get all args after "--"

wrl_in = argv[0]
x3d_out = argv[1]

# Delete that stupid cube
bpy.ops.object.delete()
bpy.ops.import_scene.x3d(filepath=wrl_in)
bpy.ops.export_scene.x3d(check_existing=False, filepath=x3d_out)
