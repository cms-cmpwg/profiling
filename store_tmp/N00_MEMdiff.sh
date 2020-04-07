#!/bin/bash

#igprof-analyse --sqlite -v --demangle --gdb -r MEM_LIVE  -b igprofMEM_800.mp igprofMEM_810.mp | sqlite3 diff_800_810.sql3

oldDir=$1
newDir=$2

oldSW=`basename $1`
newSW=`basename $2`

oldFile=${oldDir}/src/TimeMemory/igprofMEM_step3.mp
newFile=${newDir}/src/TimeMemory/igprofMEM_step3.mp

oldFileCPU=${oldDir}/src/TimeMemory/igprofCPU_step3.gz
newFileCPU=${newDir}/src/TimeMemory/igprofCPU_step3.gz


echo $oldFile
echo $newFile
echo $oldFileCPU
echo $newFileCPU


#igprof-analyse --sqlite -v --demangle --gdb -r MEM_LIVE -b $oldFile $newFile | sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprofMEM_diff_${newSW}_vs_${oldSW}.sql3
#igprof-analyse --sqlite -v --demangle --gdb -r MEM_LIVE -b $newFile $oldFile | sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprofMEM_diffReverse_${newSW}_vs_${oldSW}.sql3


igprof-analyse  -v --demangle --gdb -r MEM_LIVE -b $oldFile $newFile > igprofMEM_diff_${newSW}_vs_${oldSW}.res
igprof-analyse  -v --demangle --gdb -r MEM_LIVE -b $newFile $oldFile > igprofMEM_diffReverse_${newSW}_vs_${oldSW}.res


#igprof-analyse --sqlite -v --demangle --gdb -b $oldFileCPU $newFileCPU |sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g'| sqlite3 igprofCPU_diff_${newSW}_vs_${oldSW}.sql3
#igprof-analyse --sqlite -v --demangle --gdb -b $newFileCPU $oldFileCPU |sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g'| sqlite3 igprofCPU_diffReverse_${newSW}_vs_${oldSW}.sql3

