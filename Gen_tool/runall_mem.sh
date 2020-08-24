#!/bin/bash

CMSSW_v=$RELEASE_FORMAT

## --1. Install CMSSW version and setup environment
echo "Your SCRAM_ARCH "
export SCRAM_ARCH=$ARCHITECTURE
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
source $VO_CMS_SW_DIR/cmsset_default.sh

cd $WORKSPACE/$CMSSW_v/src
eval `scramv1 runtime -sh`
cd TimeMemory
echo "My loc"
echo $CMSSW_BASE

#step1
igprof -mp -o ./igprofMEM_step1.mp -- cmsRun  $WORKSPACE/profiling/wrapper.py $(ls *GEN_SIM.py)  >& step1_mem.log


#step2
igprof -mp -o ./igprofMEM_step2.mp -- cmsRun $WORKSPACE/profiling/wrapper.py $(ls step2*.py) >& step2_mem.log


#step3
igprof -mp -o ./igprofMEM_step3.mp -- cmsRun $WORKSPACE/profiling/wrapper.py $(ls step3*.py)  >& step3_mem.log


#step4
igprof -mp -o ./igprofMEM_step4.mp -- cmsRun $WORKSPACE/profiling/wrapper.py $(ls step4*.py)  >& step4_mem.log

