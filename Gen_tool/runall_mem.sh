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

#step3
igprof -d -mp -o igprofMEM_step3.mp -D 100evts cmsRun /x5/cms/jwkim/ServiceWork/tmp/$CMSSW_v/src/TimeMemory/step3_RAW2DIGI_L1Reco_RECO_RECOSIM_PU.py >& /dev/null 


#step4
#igprof -d -mp -o igprofMEM_step4.mp -D 100evts cmsRun /x5/cms/jwkim/ServiceWork/tmp/$CMSSW_v/src/TimeMemory/step4_PAT_PU.py >& /dev/null

