#!/bin/bash
# ARCHITECTURE, RELEASE_FORMAT and PROFILING_WORKFLOW are defined in Jenkins job
# voms-proxy-init is run in Jenkins Singularity wrapper script.

## --1. Install CMSSW version and setup environment

CMSSW_v=$1
echo $CMSSW_v

if [ "X$ARCHITECTURE" != "X" ];then
  export SCRAM_ARCH=$ARCHITECTURE
else
  export SCRAM_ARCH=slc7_amd64_gcc900
fi
echo $SCRAM_ARCH

if [ "X$RELEASE_FORMAT" == "X" -a  "X$CMSSW_IB" == "X" ]; then
  export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
  source $VO_CMS_SW_DIR/cmsset_default.sh
  source /cvmfs/grid.cern.ch/etc/profile.d/setup-cvmfs-ui.sh
  voms-proxy-init
  echo "Start install ${CMSSW_v} ..."
  scramv1 project ${CMSSW_v}
  echo "Install success"
  echo "Set CMSSW environment ...'"
  cd ${CMSSW_v}/src
  eval `scramv1 runtime -sh`  
else
  cd $WORKSPACE/${CMSSW_v}/src
fi 

## --2. "RunThematrix" dry run

if [ "X$PROFILING_WORKFLOW" == "X" ];then
  export PROFILING_WORKFLOW="23434.21"
  export EVENTS=20
fi 

if [ "X$WORKSPACE" != "X" ];then
#running on Jenkins WORKSPACE is defined and we want to generate and run the config files
runTheMatrix.py -w upgrade -l $PROFILING_WORKFLOW --command=--number=$EVENTS\ --nThreads=4\ --customise=Validation/Performance/TimeMemoryInfo.py\ --dirin=$WORKSPACE\ --dirout=$WORKSPACE #200PU for 11_2_X
else
runTheMatrix.py -w upgrade -l $PROFILING_WORKFLOW --dryRun --command=--number=$EVENTS\ --nThreads=4\ --customise=Validation/Performance/TimeMemoryInfo.py #200PU for 11_2_X
fi

# find the workflow subdirectory created by runTheMatrix.py which always starts with the WF number
for i in $(ls -d [0-9]*/); do 
outname=${i%%/}; done

if [ "X$WORKSPACE" != "X" ];then
# rename the WF subdir to WF num
  dir=$PROFILING_WORKFLOW
  mv $outname $dir
  cd $dir
else
# rename the WF subdir to TimeMemory
  mv $outname TimeMemory
  cd TimeMemory
fi
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
                        if cnt!=5:
                                line_list = line.split()
                                logfile = line_list[-2]
                                line_list.insert(-3,'--no_exec')
                                line_list.insert(-9, '-customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob')
                                line=' '.join(line_list)
                                line=line.replace(logfile,"step%s.log"%cnt)
                                line=line.replace('---customise=Validation/Performance/TimeMemoryInfo.py', '')
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

export IGREP=RES_CPU_step3.txt
export IGSORT=sorted_RES_CPU_step3.txt
awk -v module=doEvent 'BEGIN { total = 0; } { if(substr(\$0,0,1)=="-"){good = 0;}; if(good&&length(\$0)>0){print \$0; total += \$3;}; if(substr(\$0,0,1)=="["&&index(\$0,module)!=0) {good = 1;} } END { print "Total: "total } ' \${IGREP} | sort -n -r -k1 | awk '{ if(index(\$0,"Total: ")!=0){total=\$0;} else{print \$0;} } END { print total; }' > \${IGSORT} 2>&1

## -step4
    igprof-analyse  -v -d -g -r MEM_LIVE igprofMEM_step4.mp >& RES_MEM_step4.txt
    igprof-analyse  -v -d -g igprofCPU_step4.gz >& RES_CPU_step4.txt

EOF

chmod +x profile.sh
