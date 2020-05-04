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
cmsRun$VDT ./TTbar_14TeV_TuneCP5_cfi_GEN_SIM.py  >& step1$VDT.log


#step2
cmsRun$VDT ./step2_DIGI_L1_L1TrackTrigger_DIGI2RAW_HLT_PU.py >& step2$VDT.log


#step3
cmsRun$VDT ./step3_RAW2DIGI_L1Reco_RECO_RECOSIM_PU.py  >& step3$VDT.log


#step4
cmsRun$VDT ./step4_PAT_PU.py  >& step4$VDT.log

