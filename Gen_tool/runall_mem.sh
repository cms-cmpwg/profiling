#!/bin/bash
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

if [ "X$WORKSPACE" != "X" ]; then
  export WRAPPER=$WORKSPACE/profiling/ascii-out-wrapper.py
fi

if [ "X$RUNALLSTEPS" != "X" ]; then

  echo step1
  igprof -mp -o ./igprofMEM_step1.mp -- cmsRun  $WRAPPER $(ls *GEN_SIM.py)  >& step1_mem.log


  echo step2
  igprof -mp -o ./igprofMEM_step2.mp -- cmsRun $WRAPPER $(ls step2*.py) >& step2_mem.log

fi

echo step3
igprof -mp -o ./igprofMEM_step3.mp -- cmsRun $WRAPPER $(ls step3*.py)  >& step3_mem.log


echo step4
igprof -mp -o ./igprofMEM_step4.mp -- cmsRun $WRAPPER $(ls step4*.py)  >& step4_mem.log
