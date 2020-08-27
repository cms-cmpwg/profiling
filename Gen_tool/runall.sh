#!/bin/bash

if [ "X$WORKSPACE" != "X" ]; then
  CMSSW_v=$RELEASE_FORMAT
else 
  CMSSW_v=$1
fi
VDT=""

echo "Your SCRAM_ARCH "

if [ "X$WORKSPACE" != "X" ]; then
  export SCRAM_ARCH=$ARCHITECTURE
else
  export SCRAM_ARCH=slc7_amd64_gcc820
fi

export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
source $VO_CMS_SW_DIR/cmsset_default.sh

if [ "X$WORKSPACE" != "X" ]; then
  WF=`echo $WORKFLOWS | cut -d" " -f2`
  cd $WORKSPACE/$CMSSW_v/src/$WF
else
  cd $CMSSW_v/src/TimeMemory
fi

eval `scramv1 runtime -sh`

echo "My loc"
echo $PWD

if [ "X$WORKSPACE" != "X" ]; then
  export WRAPPER=$WORKSPACE/profiling/circles-wrapper.py
fi

#step1
cmsRun$VDT $WRAPPER $(ls *_GEN_SIM.py)  >& step1$VDT.log


#step2
cmsRun$VDT $WRAPPER $(ls step2*.py) >& step2$VDT.log


#step3
cmsRun$VDT $WRAPPER $(ls step3*.py)  >& step3$VDT.log


#step4
cmsRun$VDT $WRAPPER $(ls step4*.py)  >& step4$VDT.log

