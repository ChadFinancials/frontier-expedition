#!/bin/bash
# Renders a screenshot scenario under a virtual display.
#   tools/shot.sh <scenario> <out.png> [extra key=value args...]
cd "$(dirname "$0")/.." || exit 1
G=${GODOT:-/home/user/tools/godot/Godot_v4.7.2-stable_linux.x86_64}
S=$1; O=$2; shift 2
timeout ${SHOT_TIMEOUT:-90} xvfb-run -a -s "-screen 0 1920x1080x24" "$G" --path . --rendering-driver opengl3 --resolution 1920x1080 -- shot=$S out=$O "$@" > /tmp/fe_shot.log 2>&1
grep -E "SCRIPT ERROR|ERROR:|saved|at: " /tmp/fe_shot.log | grep -v -E "ALSA|audio|V-Sync|MSAA|init_output|drivers/alsa|servers/audio|gl_manager|texture_storage" | head -30
