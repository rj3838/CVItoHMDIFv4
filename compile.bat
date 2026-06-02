@echo off

REM Name of your script and app
set SCRIPT=CVItoHMDIF_v2.jl
set APPNAME=CVItoHMDIF

REM Launch Julia to compile
julia --project=. -e ^
"using PackageCompiler; ^
create_app(pwd(), \"%APPNAME%\"; ^
    filter_stdlibs=true)"

echo.
echo Build complete!
pause
