#!/bin/bash
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
  export PROFILING_WORKFLOW="21034.508"
fi

if [ -f $(which nsys) ];then
  NSYS=nsys
  NSYSARGS="profile --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi "
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

if [ "X$RUNTIMEMEMORY" != "X" ]; then
  echo Run with TimeMemoryService
  if [ -f step1_gpu_timememoryinfo.py ]; then
    echo step1 TimeMemory
    $NSYS $NSYSARGS cmsRun step1_gpu_timememoryinfo.py -j step1_gpu_timememoryinfo_JobReport.xml >& step1_gpu_timememoryinfo.txt
  else
    echo missing step1_gpu_timememoryinfo.py
  fi

  if [ -f step2_gpu_timememoryinfo.py ]; then
    echo step2 TimeMemory
    $NSYS $NSYSARGS cmsRun step2_gpu_timememoryinfo.py -j step2_gpu_timememoryinfo_JobReport.xml >& step2_gpu_timememoryinfo.txt
  else
   echo missing step2_gpu_timememoryinfo.py
  fi

  if [ -f step3_gpu_timememoryinfo.py ]; then
    echo step3 TimeMemory
    $NSYS $NSYSARGS cmsRun step3_gpu_timememoryinfo.py -j step3_gpu_timememoryinfo_JobReport.xml >& step3_gpu_timememoryinfo.txt
  else
    echo missing step3_gpu_timememoryinfo.py
  fi

  if [ -f step4_gpu_timememoryinfo.py ]; then
    echo step4 TimeMemory
    $NSYS $NSYSARGS cmsRun step4_gpu_timememoryinfo.py -j step4_gpu_timememoryinfo_JobReport.xml >& step4_gpu_timememoryinfo.txt
  else
    echo missing step4_timememoryinfo.py
  fi

  if [ -f step5_gpu_timememoryinfo.py ]; then
    echo step5 TimeMemory
    $NSYS $NSYSARGS cmsRun step5_gpu_timememoryinfo.py -j step5_gpu_timememoryinfo_JobReport.xml >& step5_gpu_timememoryinfo.txt
  else
    echo no step5 in workflow
  fi
else
  echo Run with FastTimerService
  if [ -f step1_gpu_fasttimer.py ];then
      echo step1 gpu FastTimer
      $NSYS $NSYSARGS cmsRun step1_gpu_fasttimer.py -j step1_gpu_fasttimer_JobReport.xml >& step1_gpu_fasttimer.txt
  else
      echo missing step1_gpu_fasttimer.py
  fi

  if [ -f step2_gpu_fasttimer.py ];then
      echo step2 gpu FastTimer
      $NSYS $NSYSARGS cmsRun step2_gpu_fasttimer.py -j step2_gpu_fasttimer_JobReport.xml >& step2_gpu_fasttimer.txt
  else
      echo missing step2_gpu_fasttimer.py
  fi

  if [ -f step3_gpu_fasttimer.py ];then
      echo step3 gpu FastTimer
      $NSYS $NSYSARGS cmsRun step3_gpu_fasttimer.py  -j step3_gpu_fasttimer_JobReport.xml >& step3_gpu_fasttimer.txt
  else
      echo missing step3_gpu_fasttimer.py
  fi

  if [ -f step4_gpu_fasttimer.py ];then
      echo step4 gpu FastTimer
      $NSYS $NSYSARGS cmsRun step4_gpu_fasttimer.py -j step4_gpu_fasttimer_JobReport.xml >& step4_gpu_fasttimer.txt
  else
      echo missing step4_gpu_fasttimer.py
  fi

  if [ -f step5_gpu_fasttimer.py ]; then
      echo step5 gpu FastTimer
      $NSYS $NSYSARGS cmsRun step5_gpu_fasttimer.py -j step5_gpu_fasttimer_JobReport.xml >& step5_gpu_fasttimer.txt
  else
      echo no step5 in workflow
  fi
fi

echo generating products sizes files
  if [ -f step3.root ]; then edmEventSize -v step3.root > step3_gpu_sizes_${PROFILING_WORKFLOW}.txt; else echo no step3.root; fi
  if [ -f step4.root ]; then edmEventSize -v step4.root > step4_gpu_sizes_${PROFILING_WORKFLOW}.txt; else echo no step4.root; fi
  if [ -f step5.root ]; then edmEventSize -v step5.root > step5_gpu_sizes_${PROFILING_WORKFLOW}.txt; else echo no step5.root; fi
