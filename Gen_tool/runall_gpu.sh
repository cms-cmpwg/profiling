#!/bin/bash -x
if [ "X$CMSSW_VERSION" == "X" ];then
  CMSSW_v=$1
else
  CMSSW_v=$CMSSW_VERSION
fi

VDT=""

if [ "X$ARCHITECTURE" != "X" ]; then
  export SCRAM_ARCH=$ARCHITECTURE
else
  export SCRAM_ARCH=el8_amd64_gcc11
fi

if [ "X$PROFILING_WORKFLOW" == "X" ];then
  export PROFILING_WORKFLOW="21034.508"
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
  eval `scramv1 runtime -sh`
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

if [ "X$WORKSPACE" != "X" -a "X$NOWRAPPER" == "X" ]; then
  export WRAPPER=$WORKSPACE/profiling/circles-wrapper.py
else
  export WRAPPER=$HOME/profiling/circles-wrapper.py
  RUNTIMEMEMORY=true
fi

if [ "X$TIMEOUT" == "X" ];then
    export TIMEOUT=18000
fi

# Run with TimeMemoryService
if [ "X$RUNTIMEMEMORY" != "X" ]; then
  if [ -f step1_gpu_timememoryinfo.py ]; then
    echo step1 TimeMemory
    timeout $TIMEOUT cmsRun step1_gpu_timememoryinfo.py >& step1_gpu_timememoryinfo.txt
  else
    echo missing step1_gpu_timememoryinfo.py
    exit 0
  fi
  
  if [ -f step2_gpu_timememoryinfo.py ]; then
   echo step2 TimeMemory
   timeout $TIMEOUT cmsRun step2_gpu_timememoryinfo.py >& step2_gpu_timememoryinfo.txt
  else
   echo missing step2_gpu_timememoryinfo.py
   exit 0
  fi

  if [ -f step3_gpu_timememoryinfo.py ]; then
    echo step3 TimeMemory
    timeout $TIMEOUT cmsRun step3_gpu_timememoryinfo.py >& step3_gpu_timememoryinfo.txt
  else
    echo missing step3_gpu_timememoryinfo.py
    exit 0
  fi

  if [ -f step3_gpu_timememoryinfo.py ]; then
    echo step4 TimeMemory
    timeout $TIMEOUT cmsRun step4_gpu_timememoryinfo.py >& step3_gpu_timememoryinfo.txt
  fi

  if [ -f step5_gpu_timememoryinfo.py ]; then
      echo step5 TimeMemory
      timeout $TIMEOUT cmsRun step5_gpu_timememoryinfo.py  >& step5_gpu_timememoryinfo.txt
  fi
# Run with FastTimerService
else
  if [ -f step1_gpu_fasttimer.py ];then
      echo step1 circles-wrapper optional
      timeout $TIMEOUT cmsRun step1_gpu_fasttimer.py  >& step2_gpu_fasttimer.txt
  fi
  
  if [ -f step2_gpu_fasttimer.py ];then
      echo step2 circles-wrapper optional
      timeout $TIMEOUT cmsRun step2_gpu_fasttimer.py  >& step2_gpu_fasttimer.txt
  fi
  
  if [ -f step3_gpu_fasttimer.py ];then
   echo step3 circles-wrapper optional
   timeout $TIMEOUT cmsRun step3_gpu_fasttimer.py  >& step3_gpu_fasttimer.txt
  fi
  
  if [ -f step4_gpu_fasttimer.py ];then
   echo step4 circles-wrapper optional
   timeout $TIMEOUT cmsRun step4_gpu_fasttimer.py  >& step4_gpu_fasttimer.txt
  fi
  
  if [ -f step5_gpu_fasttimer.py ]; then
      echo step5 circles-wrapper optional
      timeout $TIMEOUT cmsRun step5_gpu_fasttimer.py  >& step5_gpu_fasttimer.txt
  fi
fi

echo generating products sizes files
if [ "X$WORKSPACE" != "X" ];then
  if [ -f ${WORKSPACE}/step3.root ]; then edmEventSize -v ${WORKSPACE}/step3.root > step3_gpu_sizes_${PROFILING_WORKFLOW}.txt; else echo no step3.root;fi
  if [ -f ${WORKSPACE}/step4.root ]; then edmEventSize -v ${WORKSPACE}/step4.root > step4_gpu_sizes_${PROFILING_WORKFLOW}.txt; else echo no step4.root;fi
  if [ -f ${WORKSPACE}/step5.root ]; then edmEventSize -v ${WORKSPACE}/step5.root > step5_gpu_sizes_${PROFILING_WORKFLOW}.txt; else echo no step5.root; fi
else
  if [ -f step3.root ]; then edmEventSize -v step3.root > step3_gpu_sizes_${PROFILING_WORKFLOW}.txt; else echo no step3.root; fi
  if [ -f step4.root ]; then edmEventSize -v step4.root > step4_gpu_sizes_${PROFILING_WORKFLOW}.txt; else echo no step4.root; fi
  if [ -f step5.root ]; then edmEventSize -v step5.root > step5_gpu_sizes_${PROFILING_WORKFLOW}.txt; else echo no step5.root; fi
fi
