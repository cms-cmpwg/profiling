#!/bin/bash

CMSSW_v=$1

## --1. Install CMSSW version and setup environment
echo "Your SCRAM_ARCH "
export SCRAM_ARCH=slc7_amd64_gcc700
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
source $VO_CMS_SW_DIR/cmsset_default.sh

echo "Start install $CMSSW_v ..."
scramv1 project $CMSSW_v
echo "Install success"
echo "Set CMSSW environment and compiling..'"
cd $CMSSW_v/src
eval `scramv1 runtime -sh`
scram b -j 6


## --2. "RunThematrix" dry run
runTheMatrix.py -l 29034.21 -w upgrade --dryRun
tail *.log
mv 290* TimeMemory
cd TimeMemory
echo $PWD


## --3. Make cmdLog run_option  
cat << EOF >> read.py
import subprocess

with open('cmdLog','r') as f:
    cnt=0
    for line in f:
        line=line.rstrip()
        if line.startswith(' cmsDriver'):
            cnt+=1
## --Set N events
            line=line.replace("-n 10","-n 1000")
            if cnt==3:
                line_list = line.split()
                logfile = line_list[-2]
                line_list.insert(-7,"--customise=Validation/Performance/TimeMemoryInfo.py")
                line=' '.join(line_list)
                line=line.replace(logfile,"step3.log")
## --Do not run step4
            if cnt==4: break
## --Excute cmsDriver
            subprocess.check_output (line,shell=True)
			#print(line)
            #print(" ")

EOF

# run cmsDriver.py
python read.py


## --4. Make profiler 

cat << "EOF" >> n01_profile.sh
#!/bin/bash                                                                                                                                 

if [ -f step3*.py ];then

	step3py = eval `ls step3*.py`
	igprof -d -pp -z -o igprofCPU_step3.gz -t cmsRun cmsRun $step3py >& step3IgprofCPU.log &
	igprof -d -mp -o igprofMEM_step3.mp -D 1000evts cmsRun $step3py >& step3IgprofMEM.log &

else
	echo "Error: There is no config file"
fi
EOF

cat << EOF >> n02_profile.sh
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
EOF

# run profiler
n01_profile.sh
n02_profile.sh












