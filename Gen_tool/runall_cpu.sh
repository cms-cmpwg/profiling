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
igprof -d -pp -z -o igprofCPU_step1.gz -t cmsRun cmsRun ./TTbar_14TeV_TuneCP5_cfi_GEN_SIM.py  >& /dev/null


#step2
#igprof -d -pp -z -o igprofCPU_step2.gz -t cmsRun cmsRun ./step2_DIGI_L1_L1TrackTrigger_DIGI2RAW_HLT_PU.py >& /dev/null


#step3
#igprof -d -pp -z -o igprofCPU_step3.gz -t cmsRun cmsRun ./step3_RAW2DIGI_L1Reco_RECO_RECOSIM_PU.py >& /dev/null


#step4
#igprof -d -pp -z -o igprofCPU_step4.gz -t cmsRun cmsRun ./step4_PAT_PU.py > /dev/null
