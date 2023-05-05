#!/bin/bash
if [ "X$CMSSW_VERSION" == "X" ];then
  CMSSW_v=$1
else
  CMSSW_v=$CMSSW_VERSION
fi

if [ "X$ARCHITECTURE" != "X" ]; then
  export SCRAM_ARCH=$ARCHITECTURE
fi

if [ "X$PROFILING_WORKFLOW" == "X" ];then
  export PROFILING_WORKFLOW="23834.99"
fi

if [ "X$WORKSPACE" != "X" ]; then
  cd $WORKSPACE/$CMSSW_v/$PROFILING_WORKFLOW
else
  export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
  echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
  source $VO_CMS_SW_DIR/cmsset_default.sh
  cd $CMSSW_v/$PROFILING_WORKFLOW
  unset PYTHONPATH
  export LC_ALL=C
  eval `scram runtime -sh`
  if [ ! -f $LOCALRT/ibeos_cache.txt ];then
      curl -L -s $LOCALRT/ibeos_cache.txt https://raw.githubusercontent.com/cms-sw/cms-sw.github.io/master/das_queries/ibeos.txt
  fi
  if [ -d $CMSSW_RELEASE_BASE/src/Utilities/General/ibeos ];then
    PATH=$CMSSW_RELEASE_BASE/src/Utilities/General/ibeos:$PATH
    CMS_PATH=/cvmfs/cms-ib.cern.ch
    CMSSW_USE_IBEOS=true
  fi
  if [ -d $CMSSW_BASE/src/Utilities/General/ibeos ];then
    PATH=$CMSSW_BASE/src/Utilities/General/ibeos:$PATH
    CMS_PATH=/cvmfs/cms-ib.cern.ch
    CMSSW_USE_IBEOS=true
  fi
fi

if [ "X$TIMEOUT" == "X" ];then
    export TIMEOUT=18000
fi

  echo Run with TimeMemoryService
  if [ -f step1_timememoryinfo.py ]; then
    echo step1 TimeMemory
    timeout $TIMEOUT cmsRun step1_timememoryinfo.py >& step1_timememoryinfo.txt
  else
    echo missing step1_timememoryinfo.py
  fi

  if [ -f step2_timememoryinfo.py ]; then
    echo step2 TimeMemory
    timeout $TIMEOUT cmsRun step2_timememoryinfo.py >& step2_timememoryinfo.txt
  else
    echo missing step2_timememoryinfo.py
  fi

  if [ -f step3_timememoryinfo.py ]; then
    echo step3 TimeMemory
    timeout $TIMEOUT cmsRun step3_timememoryinfo.py >& step3_timememoryinfo.txt
  else
    echo missing step3_timememoryinfo.py
  fi

  if [ -f step4_timememoryinfo.py ]; then
    echo step4 TimeMemory
    timeout $TIMEOUT cmsRun step4_timememoryinfo.py >& step4_timememoryinfo.txt
  else
    echo missing step4_timememoryinfo.py
  fi

  if [ -f step5_timememoryinfo.py ]; then
    echo step5 TimeMemory
    timeout $TIMEOUT cmsRun step5_timememoryinfo.py  >& step5_timememoryinfo.txt
  else
    echo no step5 in workflow $PROFILING_WORKFLOW
  fi

