@echo off
rem Vulkan (Forward+) is now the project default, so this does the same as play.bat.
rem Kept so existing shortcuts keep working.
set "FE_RENDER=--rendering-method forward_plus"
call "%~dp0play.bat"
