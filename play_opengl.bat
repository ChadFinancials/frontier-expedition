@echo off
rem Same as play.bat, but with Godot's OpenGL renderer (Compatibility) instead of the
rem default Vulkan (Forward+). A fallback if Vulkan ever misbehaves on this PC. OpenGL
rem was the default until round 8; on the owner's NVIDIA card it was laggier and crashed
rem mid-battle twice.
set "FE_RENDER=--rendering-method gl_compatibility"
call "%~dp0play.bat"
