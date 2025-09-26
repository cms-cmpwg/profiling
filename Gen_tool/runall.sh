#!/bin/bash -x
#
# FastTimer Profiling Runner - Refactored
# Uses the unified profiling runner for better maintainability
#

# Source the unified profiling runner
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=unified_profiling_runner.sh
source "${SCRIPT_DIR}/unified_profiling_runner.sh"

# Run FastTimer profiling using the unified runner
main "fasttimer" "$@"

if [ "X$WORKSPACE" != "X" ]; then
  cd "$WORKSPACE/$CMSSW_v/$PROFILING_WORKFLOW" || exit 1
else
  export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
  echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
  source "$VO_CMS_SW_DIR/cmsset_default.sh"
  cd "$CMSSW_v/$PROFILING_WORKFLOW" || exit 1
  unset PYTHONPATH
  export LC_ALL=C
  eval "$(scram runtime -sh)"
  if [ ! -f "$LOCALRT/ibeos_cache.txt" ]; then
      curl -L -s "$LOCALRT/ibeos_cache.txt" https://raw.githubusercontent.com/cms-sw/cms-sw.github.io/master/das_queries/ibeos.txt
  fi
  if [ -d "$CMSSW_RELEASE_BASE/src/Utilities/General/ibeos" ]; then
    PATH="$CMSSW_RELEASE_BASE/src/Utilities/General/ibeos:$PATH"
    export CMS_PATH=/cvmfs/cms-ib.cern.ch
    export CMSSW_USE_IBEOS=true
  fi
  if [ -d "$CMSSW_BASE/src/Utilities/General/ibeos" ]; then
    PATH="$CMSSW_BASE/src/Utilities/General/ibeos:$PATH"
    export CMS_PATH=/cvmfs/cms-ib.cern.ch
    export CMSSW_USE_IBEOS=true
  fi
fi

if [ "X$TIMEOUT" == "X" ];then
    export TIMEOUT=18000
fi

pwd
. cmd_ft.sh
echo "Run with FastTimerService"

# Run step1 and step2 only if RUNALLSTEPS is set
if [ "X$RUNALLSTEPS" != "X" ]; then
  if [ -f step1_fasttimer.py ]; then
    echo "step1 FastTimer"
    cmsRun step1_fasttimer.py -j step1_cpu_fasttimer_JobReport.xml >& step1_fasttimer.log
  else
    echo "missing step1_fasttimer.py"
  fi

  if [ -f step2_fasttimer.py ]; then
    echo "step2 FastTimer"
    cmsRun step2_fasttimer.py -j step2_cpu_fasttimer_JobReport.xml  >& step2_fasttimer.log
  else
    echo "missing step2_fasttimer.py"
  fi
fi

# Always run step3, step4, and step5 (if they exist)
if [ -f step3_fasttimer.py ]; then
  echo "step3 FastTimer"
  cmsRun step3_fasttimer.py -j step3_cpu_fasttimer_JobReport.xml  >& step3_fasttimer.log
else
  echo "missing step3_fasttimer.py"
fi

if [ -f step4_fasttimer.py ]; then
  echo "step4 FastTimer"
  cmsRun step4_fasttimer.py -j step4_cpu_fasttimer_JobReport.xml  >& step4_fasttimer.log
else
  echo "missing step4_fasttimer.py"
fi

if [ -f step5_fasttimer.py ]; then
  echo "step5 FastTimer"
  cmsRun step5_fasttimer.py -j step5_cpu_fasttimer_JobReport.xml  >& step5_fasttimer.log
else
  echo "no step5 in workflow $PROFILING_WORKFLOW"
fi

echo "generating products sizes files"
if [ -f step3.root ]; then edmEventSize -v step3.root > "step3_sizes_${PROFILING_WORKFLOW}.txt"; else echo "no step3.root"; fi
if [ -f step4.root ]; then edmEventSize -v step4.root > "step4_sizes_${PROFILING_WORKFLOW}.txt"; else echo "no step4.root"; fi
if [ -f step5.root ]; then edmEventSize -v step5.root > "step5_sizes_${PROFILING_WORKFLOW}.txt"; else echo "no step5.root"; fi
