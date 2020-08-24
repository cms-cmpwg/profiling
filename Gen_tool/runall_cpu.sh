#!/bin/bash

CMSSW_v=$1

## --1. Install CMSSW version and setup environment
echo "Your SCRAM_ARCH "
#export SCRAM_ARCH=slc7_amd64_gcc700
export SCRAM_ARCH=slc7_amd64_gcc900
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
source $VO_CMS_SW_DIR/cmsset_default.sh

echo "Start install $CMSSW_v ..."
#scramv1 project $CMSSW_v
cd $CMSSW_v/src
eval `scramv1 runtime -sh`
cd TimeMemory
echo "My loc"
echo $CMSSW_BASE


#step1
igprof -pp -z -o ./igprofCPU_step1.gz -- cmsRun $(ls *GEN_SIM.py) >& step1_cpu.log


#step2
igprof -pp -z -o ./igprofCPU_step2.gz -- cmsRun $(ls step2*.py) >& step2_cpu.log


#step3
igprof -pp -z -o ./igprofCPU_step3.gz -- cmsRun $(ls step3*.py) >& step3_cpu.log


#step4
igprof -pp -z -o ./igprofCPU_step4.gz -- cmsRun $(ls step4*.py) >& step4_cpu.log
