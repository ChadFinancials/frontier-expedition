@echo off
rem Same as play.bat, but asks Godot for its Vulkan renderer (Forward+) instead of OpenGL.
rem A test for the combat crashes, which look like an OpenGL driver problem; Vulkan is the
rem better-tested path on NVIDIA cards and also supports smooth (MSAA) edges in 2D.
rem If Vulkan cannot start, Godot falls back to OpenGL on its own. The console line
rem "Vulkan ... Forward+" (instead of "OpenGL API ... Compatibility") confirms it took.
set "FE_RENDER=--rendering-method forward_plus"
call "%~dp0play.bat"
