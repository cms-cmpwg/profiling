#!/bin/bash

# WORKSPACE is defined in Jenkins job

CMSSW_v=$1

## --1. Install CMSSW version and setup environment
if [ "X$ARCHITECTURE" != "X" ];then
  export SCRAM_ARCH=$ARCHITECTURE
else 
  export SCRAM_ARCH=slc7_amd64_gcc900
fi
echo "Your SCRAM_ARCH $SCRAM_ARCH"

if [ "X$PROFILING_WORKFLOW" == "X" ];then
  export PROFILING_WORKFLOW="23434.21"
fi 

if [ "X$WORKSPACE" != "X" ]; then
  cd $WORKSPACE/$CMSSW_v/$PROFILING_WORKFLOW
else
  export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
  source $VO_CMS_SW_DIR/cmsset_default.sh
  cd $CMSSW_v/TimeMemory
  eval `scramv1 runtime -sh`
fi

echo "My loc"
echo $PWD

if [ "X$WORKSPACE" != "X" ];then
  export WRAPPER=$WORKSPACE/profiling/ascii-out-wrapper.py 
fi

if [ "X$RUNALLSTEPS" != "X" ]; then

  echo step1

  igprof -pp -z -o ./igprofCPU_step1.gz -- cmsRun $WRAPPER $(ls *GEN_SIM.py) >& step1_cpu.log


  echo step2
  igprof -pp -z -o ./igprofCPU_step2.gz -- cmsRun $WRAPPER $(ls step2*.py) >& step2_cpu.log

fi

echo step3
igprof -pp -z -o ./igprofCPU_step3.gz -- cmsRun $WRAPPER $(ls step3*.py) >& step3_cpu.log


echo step4
igprof -pp -z -o ./igprofCPU_step4.gz -- cmsRun $WRAPPER $(ls step4*.py) >& step4_cpu.log

echo generating products sizes files
if [ "X$WORKSPACE" != "X" ];then
  edmEventSize -v ${WORKSPACE}/step3.root > step3_sizes_${PROFILING_WORKFLOW}.txt
  edmEventSize -v ${WORKSPACE}/step4.root > step4_sizes_${PROFILING_WORKFLOW}.txt
else
  edmEventSize -v step3.root > step3_sizes_${PROFILING_WORKFLOW}.txt
  edmEventSize -v step4.root > step4_sizes_${PROFILING_WORKFLOW}.txt
fi
