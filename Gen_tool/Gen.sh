#!/bin/bash

CMSSW_v=$1
## --1. Install CMSSW version and setup environment
echo "Your SCRAM_ARCH "
export SCRAM_ARCH=slc7_amd64_gcc900
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
source $VO_CMS_SW_DIR/cmsset_default.sh

echo "Start install $CMSSW_v ..."
scramv1 project $CMSSW_v
echo "Install success"
echo "Set CMSSW environment ...'"
cd ${CMSSW_v}/src
eval `scramv1 runtime -sh`
#echo "Compiling ...'"
#scram b -j 6

## --2. "RunThematrix" dry run

runTheMatrix.py -w upgrade $WORKFLOWS --dryRun #200PU for 11_2_X

#tail *.log

for i in $(ls -d [0-9]*/); do 
outname=${i%%/}; done
mv $outname TimeMemory
cd TimeMemory


# --3. Make cmdLog run_option  -- Set N events
cat << EOF >> read.py
#!/usr/bin/env python
import subprocess

with open('cmdLog','r') as f:
        cnt=0
        for line in f:
                line=line.rstrip()
                if line.startswith(' cmsDriver'):
                        cnt+=1
## --Set N events
                        line=line.replace("-n 10","-n 20")
                        if cnt!=5:
                                line_list = line.split()
                                logfile = line_list[-2]
                                line_list.insert(-3,'--nThreads 1')
                                line_list.insert(-3,'--no_exec')
                                line_list.insert(-9,"--customise Validation/Performance/TimeMemoryInfo.py")
                                line=' '.join(line_list)
                                line=line.replace(logfile,"step%s.log"%cnt)
                                line=line.replace('file:', 'file:${OUTPUT_DIR:-"."}/')
## --Do not run step4
                        else:
                                 break
## --Excute cmsDriver
                        print(line)
                        print(" ")
                        subprocess.check_output (line,shell=True)
EOF

# run cmsDriver.py
chmod +x read.py
./read.py


## --4. Make profiler 



#EOF

cat << EOF >> profile.sh
#!/bin/bash


## --For web-based report


## -step1
   igprof-analyse --sqlite -v -d -g -r MEM_LIVE igprofMEM_step1.mp |sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprofMEM_step1.sql3 >& MEMsql_step1.log
   igprof-analyse --sqlite -v -d -g igprofCPU_step1.gz | sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprofCPU_step1.sql3 >& CPUsql_step1.log

## -step2
   igprof-analyse --sqlite -v -d -g -r MEM_LIVE igprofMEM_step2.mp |sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprofMEM_step2.sql3 >& MEMsql_step2.log
   igprof-analyse --sqlite -v -d -g igprofCPU_step2.gz | sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprofCPU_step2.sql3 >& CPUsql_step2.log

## -step3
   igprof-analyse --sqlite -v -d -g -r MEM_LIVE igprofMEM_step3.mp |sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprofMEM_step3.sql3 >& MEMsql_step3.log
   igprof-analyse --sqlite -v -d -g igprofCPU_step3.gz | sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprofCPU_step3.sql3 >& CPUsql_step3.log

## -step4
    igprof-analyse --sqlite -v -d -g -r MEM_LIVE igprofMEM_step4.mp |sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprofMEM_step4.sql3 >& MEMsql_step4.log
    igprof-analyse --sqlite -v -d -g igprofCPU_step4.gz | sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprofCPU_step4.sql3 >& CPUsql_step4.log


## --For ascii-based report

## -step1
   igprof-analyse  -v -d -g -r MEM_LIVE igprofMEM_step1.mp >& RES_MEM_step1.txt
   igprof-analyse  -v -d -g igprofCPU_step1.gz >& RES_CPU_step1.txt

## -step2
   igprof-analyse  -v -d -g -r MEM_LIVE igprofMEM_step2.mp >& RES_MEM_step2.txt
   igprof-analyse  -v -d -g igprofCPU_step2.gz >& RES_CPU_step2.txt

## -step3
   igprof-analyse  -v -d -g -r MEM_LIVE igprofMEM_step3.mp >& RES_MEM_step3.txt
   igprof-analyse  -v -d -g igprofCPU_step3.gz >& RES_CPU_step3.txt

## -step4
    igprof-analyse  -v -d -g -r MEM_LIVE igprofMEM_step4.mp >& RES_MEM_step4.txt
    igprof-analyse  -v -d -g igprofCPU_step4.gz >& RES_CPU_step4.txt

EOF

chmod +x profile.sh
