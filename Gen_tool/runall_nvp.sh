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

if [ -f /cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin/nsys ];then
  NSYS=/cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin/nsys
  NSYSARGS="profile --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi"
  echo Run with NVProflierService
  if [ "X$RUNALLSTEPS" != "X" ]; then
    if [ -f step1_nvprof.py ];then
        echo step1 gpu NVProfiler
        timeout $TIMEOUT cmsRun step1_nvprof.py -j step1_nvprof_JobReport.xml >& step1_nvprof.txt
    else
        echo missing step1_nvprof.py
    fi

    if [ -f step2_nvprof.py ];then
        echo step2 gpu NVProfiler
        timeout $TIMEOUT cmsRun step2_nvprof.py -j step2_nvprof_JobReport.xml >& step2_nvprof.txt
    else
        echo missing step2_nvprof.py
    fi
  fi
  if [ -f step3_nvprof.py ];then
      echo step3 gpu NVProfiler
      timeout $TIMEOUT cmsRun step3_nvprof.py  -j step3_nvprof_JobReport.xml >& step3_nvprof.txt
  else
      echo missing step3_nvprof.py
  fi

  if [ -f step4_nvprof.py ];then
      echo step4 gpu NVProfiler
      timeout $TIMEOUT cmsRun step4_nvprof.py -j step4_nvprof_JobReport.xml >& step4_nvprof.txt
  else
      echo missing step4_nvprof.py
  fi

  if [ -f step5_nvprof.py ]; then
      echo step5 gpu NVProfiler
      timeout $TIMEOUT cmsRun step5_nvprof.py -j step5_nvprof_JobReport.xml >& step5_nvprof.txt
  else
      echo no step5 in workflow
  fi
else
  NSYS=""
  NSYSARGS=""

  echo Run with FastTimerService
  if [ "X$RUNALLSTEPS" != "X" ]; then
    if [ -f step1_fasttimer.py ];then
        echo step1 gpu FastTimer
        timeout $TIMEOUT $NSYS $NSYSARGS cmsRun step1_fasttimer.py -j step1_fasttimer_JobReport.xml >& step1_fasttimer.txt
    else
        echo missing step1_fasttimer.py
    fi

    if [ -f step2_fasttimer.py ];then
        echo step2 gpu FastTimer
        timeout $TIMEOUT $NSYS $NSYSARGS cmsRun step2_fasttimer.py -j step2_fasttimer_JobReport.xml >& step2_fasttimer.txt
    else
        echo missing step2_fasttimer.py
    fi
  fi
  if [ -f step3_fasttimer.py ];then
      echo step3 gpu FastTimer
      timeout $TIMEOUT $NSYS $NSYSARGS cmsRun step3_fasttimer.py  -j step3_fasttimer_JobReport.xml >& step3_fasttimer.txt
  else
      echo missing step3_fasttimer.py
  fi

  if [ -f step4_fasttimer.py ];then
      echo step4 gpu FastTimer
      timeout $TIMEOUT $NSYS $NSYSARGS cmsRun step4_fasttimer.py -j step4_fasttimer_JobReport.xml >& step4_fasttimer.txt
  else
      echo missing step4_fasttimer.py
  fi

  if [ -f step5_fasttimer.py ]; then
      echo step5 gpu FastTimer
      timeout $TIMEOUT $NSYS $NSYSARGS cmsRun step5_fasttimer.py -j step5_fasttimer_JobReport.xml >& step5_fasttimer.txt
  else
      echo no step5 in workflow
  fi
fi
