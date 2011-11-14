@ECHO OFF
IF NOT "%~f0" == "~f0" GOTO :WinNT
@"jruby.exe" "C:/SteppesCRM/steppes2DEV/dm-accepts_nested_attributes/jruby/1.8/bin/rake2thor" %1 %2 %3 %4 %5 %6 %7 %8 %9
GOTO :EOF
:WinNT
@"jruby.exe" "%~dpn0" %*
