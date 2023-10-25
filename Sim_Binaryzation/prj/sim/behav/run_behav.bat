@echo off
set bin_path=C:/modelsim_dlx64_10.6c/win64pe
cd D:/Github/PDS_Sim_Binaryzation/Sim_Binaryzation/prj/sim/behav
call "%bin_path%/modelsim"   -do "do {run_behav_compile.tcl};do {run_behav_simulate.tcl}" -l run_behav_simulate.log
if "%errorlevel%"=="1" goto END
if "%errorlevel%"=="0" goto SUCCESS
:END
exit 1
:SUCCESS
exit 0
