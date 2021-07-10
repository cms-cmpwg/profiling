#!/bin/bash -x
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
  if [ ! -f $LOCALRT/ibeos_cache.txt ];then
      curl -L -s $LOCALRT/ibeos_cache.txt https://raw.githubusercontent.com/cms-sw/cms-sw.github.io/master/das_queries/ibeos.txt
  fi
  if [ -d $CMSSW_RELEASE_BASE/src/Utilities/General/ibeos ];then
    PATH=$CMSSW_BASE/src/Utilities/General/ibeos:$PATH
    CMS_PATH=/cvmfs/cms-ib.cern.ch
    CMSSW_USE_IBEOS=true
  fi
  if [ -d $CMSSW_BASE/src/Utilities/General/ibeos ];then
    PATH=$CMSSW_BASE/src/Utilities/General/ibeos:$PATH
    CMS_PATH=/cvmfs/cms-ib.cern.ch
    CMSSW_USE_IBEOS=true
  fi
fi

echo "My loc"
echo $PWD

if [ "X$WORKSPACE" != "X" ]; then
  export WRAPPER=$WORKSPACE/profiling/ascii-out-wrapper.py
fi
LC_ALL=C

if [ "X$TIMEOUT" == "X" ];then
    export TIMEOUT=43200
fi

if [ "X$RUNALLSTEPS" == "Xtrue" ]; then

  echo step1 w/igprof -mp
  igprof -mp -o ./igprofMEM_step1.mp -- cmsRunGLibC  $WRAPPER $(ls *GEN_SIM.py)  >& step1_mem.log


  echo step2 w/igprof -mp
  igprof -mp -o ./igprofMEM_step2.mp -- cmsRunGlibC $WRAPPER $(ls step2*.py) >& step2_mem.log

fi

echo step3 w/igprof -mp
igprof -mp -o ./igprofMEM_step3.mp -- cmsRunGlibC $WRAPPER $(ls step3*.py)  >& step3_mem.log


echo step4 w/igprof -mp
igprof -mp -o ./igprofMEM_step4.mp -- cmsRunGlibC  $WRAPPER $(ls step4*.py)  >& step4_mem.log

if [ $(ls -d step5*.py | wc -l) -gt 0 ]; then
    echo step5 w/igprof -mp
    igprof -mp -o ./igprofMEM_step5.mp -- cmsRunGlibC  $WRAPPER $(ls step5*.py)  >& step5_mem.log
else
    echo skipping step5 w/igprof -mp
fi
