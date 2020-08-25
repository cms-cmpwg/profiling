#!/bin/bash
if [ "X$RELEASE_FORMAT" != "X" ];then
  CMSSW_v=$RELEASE_FORMAT
else
  CMSSW_v=$1
fi

## --1. Install CMSSW version and setup environment
echo "Your SCRAM_ARCH "
if [ "X$ARCHITECTURE" != "X" ];then
export SCRAM_ARCH=$ARCHITECTURE
else
  export SCRAM_ARCH=slc7_amd64_gcc900
fi
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
source $VO_CMS_SW_DIR/cmsset_default.sh

if [ "X$WORKSPACE" != "X" ]; then
  cd $WORKSPACE/$CMSSW_v/src
else
  cd $CMSSW_v/src
fi
eval `scramv1 runtime -sh`
cd TimeMemory
echo "My loc"
echo $CMSSW_BASE

if [ "X$WORKSPACE" != "X" ]; then
  export WRAPPER=$WORKSPACE/profiling/wrapper.py
fi

#step1
igprof -mp -o ./igprofMEM_step1.mp -- cmsRun  $WRAPPER $(ls *GEN_SIM.py)  >& step1_mem.log


#step2
igprof -mp -o ./igprofMEM_step2.mp -- cmsRun $WRAPPER $(ls step2*.py) >& step2_mem.log


#step3
igprof -mp -o ./igprofMEM_step3.mp -- cmsRun $WRAPPER $(ls step3*.py)  >& step3_mem.log


#step4
igprof -mp -o ./igprofMEM_step4.mp -- cmsRun $WRAPPER $(ls step4*.py)  >& step4_mem.log
