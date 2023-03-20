#!/bin/bash
if [ "X$CMSSW_VERSION" == "X" ];then
  CMSSW_v=$1
else
  CMSSW_v=$CMSSW_VERSION
fi
echo $CMSSW_v
## --1. Install CMSSW version and setup environment
if [ "X$ARCHITECTURE" != "X" ];then
  export SCRAM_ARCH=$ARCHITECTURE
fi

if [ "X$PROFILING_WORKFLOW" == "X" ];then
  export PROFILING_WORKFLOW="21034.21"
fi

if [ "X$WORKSPACE" != "X" ]; then
  cd $WORKSPACE/$CMSSW_v/$PROFILING_WORKFLOW
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

function rename_igprof {
for f in $(ls -1 IgProf*.gz);do
    mv $f ${f/IgProf/$1}
done
}

function rename_jeprof {
for f in $(ls jeprof*.heap);do
   mv $f $1_jeprof.heap
done
}

if [ "X$RUNALLSTEPS" != "X" ]; then
  if [ -f step1_igprof.py ]; then
    echo step1 w/jeprof
    MALLOC_CONF=prof_leak:true,lg_prof_sample:10,prof_final:true  cmsRunJEProf step1_igprof.py -j step1_jeprof_mem_JobReport.xml >& step1_jeprof_mem.log
    rename_jeprof step1
  else
    echo missing step1_igprof.py
  fi

  if [ -f step2_igprof.py ]; then
    echo step2 w/jeprof
    MALLOC_CONF=prof_leak:true,lg_prof_sample:10,prof_final:true  cmsRunJEProf step2_igprof.py -j step2_jeprof_mem_JobReport.xml >& step2_jeprof_mem.log
    rename_jeprof step2
  else
    echo missing step2_igprof.py
  fi
fi

if [ -f step3_igprof.py ]; then
    echo step3 w/jeprof
    MALLOC_CONF=prof_leak:true,lg_prof_sample:10,prof_final:true  cmsRunJEProf step3_igprof.py -j step3_jeprof_mem_JobReport.xml >& step3_jeprof_mem.log
    rename_jeprof step3
else
    echo missing step3_igprof.py
fi


if [ -f step4_igprof.py ]; then
    echo step4 w/jeprof
    MALLOC_CONF=prof_leak:true,lg_prof_sample:10,prof_final:true  cmsRunJEProf step4_igprof.py -j step4_jeprof_mem_JobReport.xml >& step4_jeprof_mem.log
    rename_jeprof step5
else
    echo missing step4_igprof.py
fi

if [ $(ls -d step5*.py | wc -l) -gt 0 ]; then
    echo step5 w/jeprof
    MALLOC_CONF=prof_leak:true,lg_prof_sample:10,prof_final:true  cmsRunJEProf step5_igprof.py -j step1_jeprof_mem_JobReport.xml >& step5_jeprof_mem.log
    rename_jeprof step5
else
    echo no step5 in workflow $PROFILING_WORKFLOW
fi
