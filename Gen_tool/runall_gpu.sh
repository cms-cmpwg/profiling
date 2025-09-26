#!/bin/bash
#
# GPU Profiling Runner - Refactored
# Uses the unified profiling runner for better maintainability
#

# Source the unified profiling runner
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=unified_profiling_runner.sh
source "${SCRIPT_DIR}/unified_profiling_runner.sh"

# Run GPU profiling using the unified runner
main "gpu" "$@"

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

pwd

  echo Run with FastTimerService
  if [ -f step1_gpu_fasttimer.py ];then
      echo step1 gpu FastTimer
      cmsRun step1_gpu_fasttimer.py -j step1_gpu_fasttimer_JobReport.xml >& step1_gpu_fasttimer.log
  else
      echo missing step1_gpu_fasttimer.py
  fi

  if [ -f step2_gpu_fasttimer.py ];then
      echo step2 gpu FastTimer
      cmsRun step2_gpu_fasttimer.py -j step2_gpu_fasttimer_JobReport.xml >& step2_gpu_fasttimer.log
  else
      echo missing step2_gpu_fasttimer.py
  fi

  if [ -f step3_gpu_fasttimer.py ];then
      echo step3 gpu FastTimer
      cmsRun step3_gpu_fasttimer.py  -j step3_gpu_fasttimer_JobReport.xml >& step3_gpu_fasttimer.log
  else
      echo missing step3_gpu_fasttimer.py
  fi

  if [ -f step4_gpu_fasttimer.py ];then
      echo step4 gpu FastTimer
      cmsRun step4_gpu_fasttimer.py -j step4_gpu_fasttimer_JobReport.xml >& step4_gpu_fasttimer.log
  else
      echo missing step4_gpu_fasttimer.py
  fi

  if [ -f step5_gpu_fasttimer.py ]; then
      echo step5 gpu FastTimer
      cmsRun step5_gpu_fasttimer.py -j step5_gpu_fasttimer_JobReport.xml >& step5_gpu_fasttimer.log
  else
      echo no step5 in workflow
  fi
