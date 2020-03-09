#!/bin/bash

if [ -f step3IgprofCPU.log ] && [ -f step3IgprofMEM.log ]; then

## --For web-based report
	igprof-analyse --sqlite -v -d -g -r MEM_LIVE igprofMEM_step3.mp |sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprofMEM_.sql3 >& MEMsql.log
	igprof-analyse --sqlite -v -d -g igprofCPU_step3.gz | sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprofCPU_.sql3 >& CPUsql.log

## --For ascii-based report
	igprof-analyse  -v -d -g -r MEM_LIVE igprofMEM_step3.mp >& Pre4_igproMEM.res
	igprof-analyse  -v -d -g igprofCPU_step3.gz >& Pre4_igproCPU.res

else
	echo "Error: There are no input files for report"
fi

mkdir Analysis


