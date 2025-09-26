#!/bin/bash -x 
#
# Jemalloc Memory Profiling Runner - Refactored
# Uses the unified profiling runner for better maintainability
#

# Source the unified profiling runner
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=unified_profiling_runner.sh
source "${SCRIPT_DIR}/unified_profiling_runner.sh"

# Run jemalloc profiling using the unified runner
main "jemal" "$@"

if [ "X$WORKSPACE" != "X" ]; then
  cd $WORKSPACE/$CMSSW_v/$PROFILING_WORKFLOW
  scram setup jemalloc-prof
  scram b ToolUpdated
else
  export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
  source $VO_CMS_SW_DIR/cmsset_default.sh
  cd $CMSSW_v/$PROFILING_WORKFLOW
  scram setup jemalloc-prof
  scram b ToolUpdated
  eval `scram runtime -sh`
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

LC_ALL=C

if [ "X$TIMEOUT" == "X" ];then
    export TIMEOUT=18000
fi

function rename_jeprof {
for f in $(ls jeprof.*.heap 2>/dev/null | grep -v step);do
   mv $f $1_$f
done
}

pwd
. cmd_je.sh
export MALLOC_CONF=prof_leak:true,lg_prof_sample:10,prof_final:true
if [ "X$RUNALLSTEPS" != "X" ]; then
  if [ -f step1_jeprof.py ]; then
    echo step1 w/jeprof
    MALLOC_CONF=prof_leak:true,lg_prof_sample:10,prof_final:true  cmsRunJEProf step1_jeprof.py -j step1_jeprof_mem_JobReport.xml >& step1_jeprof_mem.log
    rename_jeprof step1
  else
    echo missing step1_jeprof.py
  fi

  if [ -f step2_jeprof.py ]; then
    echo step2 w/jeprof
    MALLOC_CONF=prof_leak:true,lg_prof_sample:10,prof_final:true  cmsRunJEProf step2_jeprof.py -j step2_jeprof_mem_JobReport.xml >& step2_jeprof_mem.log
    rename_jeprof step2
  else
    echo missing step2_jeprof.py
  fi
fi

if [ -f step3_jeprof.py ]; then
    echo step3 w/jeprof
    MALLOC_CONF=prof_leak:true,lg_prof_sample:10,prof_final:true  cmsRunJEProf step3_jeprof.py -j step3_jeprof_mem_JobReport.xml >& step3_jeprof_mem.log
    rename_jeprof step3
else
    echo missing step3_jeprof.py
fi


if [ -f step4_jeprof.py ]; then
    echo step4 w/jeprof
    MALLOC_CONF=prof_leak:true,lg_prof_sample:10,prof_final:true  cmsRunJEProf step4_jeprof.py -j step4_jeprof_mem_JobReport.xml >& step4_jeprof_mem.log
    rename_jeprof step4
else
    echo missing step4_jeprof.py
fi

if [ $(ls -d step5_jeprof.py | wc -l) -gt 0 ]; then
    echo step5 w/jeprof
    MALLOC_CONF=prof_leak:true,lg_prof_sample:10,prof_final:true  cmsRunJEProf step5_jeprof.py -j step1_jeprof_mem_JobReport.xml >& step5_jeprof_mem.log
    rename_jeprof step5
else
    echo no step5 in workflow $PROFILING_WORKFLOW
fi
unset MALLOC_CONF
