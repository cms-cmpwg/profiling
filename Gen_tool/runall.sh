#!/bin/bash -x
if [ "X$CMSSW_VERSION" == "X" ];then
  CMSSW_v=$1
else
  CMSSW_v=$CMSSW_VERSION
fi

if [ "X$ARCHITECTURE" != "X" ]; then
  export SCRAM_ARCH=$ARCHITECTURE
else
  export SCRAM_ARCH=el8_amd64_gcc11
fi

if [ "X$PROFILING_WORKFLOW" == "X" ];then
  export PROFILING_WORKFLOW="21034.21"
fi

if [ -f /cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin/nsys ];then
  NSYS=/cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin/nsys
  NSYSARGS="profile --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi"
else
  NSYS=""
  NSYSARGS=""
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

if [ "X$TIMEOUT" == "X" ];then
    export TIMEOUT=18000
fi

if [ "X$RUNTIMEMEMORY" != "X" ]; then
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
    timeout $TIMEOUT cmsRun step4_timememoryinfo.py >& step3_timememoryinfo.txt
  else
    echo missing step4_timememoryinfo.py
  fi

  if [ -f step5_timememoryinfo.py ]; then
      echo step5 TimeMemory
      timeout $TIMEOUT cmsRun step5_timememoryinfo.py  >& step5_timememoryinfo.txt
  else
    echo no step5 in workflow $PROFILING_WORKFLOW
  fi
else
  echo Run with FastTimerService
  if [ -f step1_fasttimer.py ];then
      echo step1 FastTimer
      timeout $TIMEOUT cmsRun step1_fasttimer.py  >& step1_fasttimer.txt
  else
    echo missing step1_fasttimer.py
  fi

  if [ -f step2_fasttimer.py ];then
      echo step2 FastTimer
      timeout $TIMEOUT cmsRun step2_fasttimer.py  >& step2_fasttimer.txt
  else
    echo missing step2_fasttimer.py
  fi

  if [ -f step3_fasttimer.py ]; then
    echo step3 FastTimer
    timeout $TIMEOUT cmsRun step3_fasttimer.py  >& step3_fasttimer.txt
  else
    echo missing step3_fasttimer.py
  fi

  if [ -f step4_fasttimer.py ]; then
   echo step4 FastTimer
   timeout $TIMEOUT cmsRun step4_fasttimer.py  >& step4_fasttimer.txt
  else
    echo missing step4_fasttimer.py
  fi

  if [ -f step5_fasttimer.py ]; then
      echo step5 FastTimer
      timeout $TIMEOUT cmsRun step5_fasttimer.py  >& step5_fasttimer.txt
  else
    echo no step5 in workflow $PROFILING_WORKFLOW
  fi
fi

echo generating products sizes files
if [ "X$WORKSPACE" != "X" ];then
  if [ -f ${WORKSPACE}/step3.root ]; then edmEventSize -v ${WORKSPACE}/step3.root > step3_sizes_${PROFILING_WORKFLOW}.txt; else echo no step3.root;fi
  if [ -f ${WORKSPACE}/step4.root ]; then edmEventSize -v ${WORKSPACE}/step4.root > step4_sizes_${PROFILING_WORKFLOW}.txt; else echo no step4.root;fi
  if [ -f ${WORKSPACE}/step5.root ]; then edmEventSize -v ${WORKSPACE}/step5.root > step5_sizes_${PROFILING_WORKFLOW}.txt; else echo no step5.root; fi
else
  if [ -f step3.root ]; then edmEventSize -v step3.root > step3_sizes_${PROFILING_WORKFLOW}.txt; else echo no step3.root; fi
  if [ -f step4.root ]; then edmEventSize -v step4.root > step4_sizes_${PROFILING_WORKFLOW}.txt; else echo no step4.root; fi
  if [ -f step5.root ]; then edmEventSize -v step5.root > step5_sizes_${PROFILING_WORKFLOW}.txt; else echo no step5.root; fi
fi
