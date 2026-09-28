#!/bin/bash
# Re-imports the project headlessly, then force-compiles every script and prints errors.
cd "$(dirname "$0")/.." || exit 1
G=${GODOT:-/home/user/tools/godot/Godot_v4.7.2-stable_linux.x86_64}
timeout 200 "$G" --headless --path . --import > /tmp/fe_import.log 2>&1
timeout 120 "$G" --headless --path . res://tests/compile_all.tscn > /tmp/fe_compile.log 2>&1
grep -A1 -E "SCRIPT ERROR|Parse Error|Compile Error|FAILED" /tmp/fe_compile.log | grep -v "^--$" | head -${1:-30}
grep "compile check done" /tmp/fe_compile.log
