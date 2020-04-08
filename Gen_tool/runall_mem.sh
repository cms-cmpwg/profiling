#!/bin/bash

CMSSW_v=$1

## --1. Install CMSSW version and setup environment
echo "Your SCRAM_ARCH "
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
igprof -d -mp -o igprofMEM_step1.mp -D 100evts cmsRun ./TTbar_14TeV_TuneCP5_cfi_GEN_SIM.py 


#step2
igprof -d -mp -o igprofMEM_step2.mp -D 100evts cmsRun ./step2_DIGI_L1_L1TrackTrigger_DIGI2RAW_HLT_PU.py 


#step3
igprof -d -mp -o igprofMEM_step3.mp -D 100evts cmsRun ./step3_RAW2DIGI_L1Reco_RECO_RECOSIM_PU.py 


#step4
igprof -d -mp -o igprofMEM_step4.mp -D 100evts cmsRun ./step4_PAT_PU.py 

