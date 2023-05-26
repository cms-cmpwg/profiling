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
    cmsRun step1_timememoryinfo.py >& step1_timememoryinfo.log
  else
    echo missing step1_timememoryinfo.py
  fi

  if [ -f step2_timememoryinfo.py ]; then
    echo step2 TimeMemory
    cmsRun step2_timememoryinfo.py >& step2_timememoryinfo.log
  else
    echo missing step2_timememoryinfo.py
  fi

  if [ -f step3_timememoryinfo.py ]; then
    echo step3 TimeMemory
    cmsRun step3_timememoryinfo.py >& step3_timememoryinfo.log
  else
    echo missing step3_timememoryinfo.py
  fi

  if [ -f step4_timememoryinfo.py ]; then
    echo step4 TimeMemory
    cmsRun step4_timememoryinfo.py >& step4_timememoryinfo.log
  else
    echo missing step4_timememoryinfo.py
  fi

  if [ -f step5_timememoryinfo.py ]; then
    echo step5 TimeMemory
    cmsRun step5_timememoryinfo.py  >& step5_timememoryinfo.log
  else
    echo no step5 in workflow $PROFILING_WORKFLOW
  fi

  echo generating products sizes files
  if [ -f step3.root ]; then edmEventSize -v step3.root > step3_sizes_${PROFILING_WORKFLOW}.txt; else echo no step3.root; fi
  if [ -f step4.root ]; then edmEventSize -v step4.root > step4_sizes_${PROFILING_WORKFLOW}.txt; else echo no step4.root; fi
  if [ -f step5.root ]; then edmEventSize -v step5.root > step5_sizes_${PROFILING_WORKFLOW}.txt; else echo no step5.root; fi
