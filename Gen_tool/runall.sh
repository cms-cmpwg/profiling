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
  export PROFILING_WORKFLOW="23834.21"
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

  echo Run with FastTimerService
  if [ -f step1_fasttimer.py ];then
      echo step1 FastTimer
      cmsRun step1_fasttimer.py -j step1_cpu_fasttimer_JobReport.xml >& step1_fasttimer.log
  else
    echo missing step1_fasttimer.py
  fi

  if [ -f step2_fasttimer.py ];then
      echo step2 FastTimer
      cmsRun step2_fasttimer.py -j step2_cpu_fasttimer_JobReport.xml  >& step2_fasttimer.log
  else
    echo missing step2_fasttimer.py
  fi

  if [ -f step3_fasttimer.py ]; then
    echo step3 FastTimer
    cmsRun step3_fasttimer.py -j step3_cpu_fasttimer_JobReport.xml  >& step3_fasttimer.log
  else
    echo missing step3_fasttimer.py
  fi

  if [ -f step4_fasttimer.py ]; then
   echo step4 FastTimer
   cmsRun step4_fasttimer.py -j step4_cpu_fasttimer_JobReport.xml  >& step4_fasttimer.log
  else
    echo missing step4_fasttimer.py
  fi

  if [ -f step5_fasttimer.py ]; then
      echo step5 FastTimer
      cmsRun step5_fasttimer.py -j step5_cpu_fasttimer_JobReport.xml  >& step5_fasttimer.log
  else
    echo no step5 in workflow $PROFILING_WORKFLOW
  fi

