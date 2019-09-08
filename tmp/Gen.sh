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

## --3. Make cmdLog run option
cat << EOF >> read.py
import subprocess

with open('cmdLog','r') as f:
    cnt=0
    for line in f:
        line=line.rstrip()
        if line.startswith(' cmsDriver'):
            cnt+=1

            line=line.replace("-n 10","-n 1000")

            if cnt==2:
                line=line.replace("*.log",step3.log")


            print(line)
            #subprocess.check_output (line,shell=True)


    #print("line number: ",cnt)

EOF
