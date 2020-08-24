#!/bin/bash

CMSSW_v=$1
VDT=$2
## --1. Install CMSSW version and setup environment
echo "Your SCRAM_ARCH "
export SCRAM_ARCH=slc7_amd64_gcc900
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
source $VO_CMS_SW_DIR/cmsset_default.sh

echo "Start install $CMSSW_v ..."
#scramv1 project $CMSSW_v
cd $CMSSW_v
eval `scramv1 runtime -sh`
cd TimeMemory
echo "My loc"
echo $CMSSW_BASE

#step1
cmsRun$VDT $(ls *_GEN_SIM.py)  >& step1$VDT.log


#step2
cmsRun$VDT $(ls step2*.py) >& step2$VDT.log


#step3
cmsRun$VDT $(ls step3*.py)  >& step3$VDT.log


#step4
cmsRun$VDT $(ls step4*.py)  >& step4$VDT.log

