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
    echo step1 w/igprof -mp cmsRunTC
    igprof -mp -z -o ./igprofMEM_TC_step1.gz -- cmsRunTC step1_igprof.py -j step1_igprof_mem_TC_JobReport.xml >& step1_igprof_mem_TC.log
    rename_igprof igprofMEM_TC_step1
  else
    echo missing step1_igprof.py
  fi

  if [ -f step2_igprof.py ]; then
    echo step2 w/igprof -mp cmsRunTC
    igprof -mp -z -o ./igprofMEM_TC_step2.gz -- cmsRunTC step2_igprof.py -j step2_igprof_mem_TC_JobReport.xml >& step2_igprof_mem_TC.log
    rename_igprof igprofMEM_TC_step1
  else
    echo missing step2_igprof.py
  fi
fi

if [ -f step3_igprof.py ]; then
    echo step3 w/igprof -mp cmsRunTC
    igprof -mp -z -o ./igprofMEM_TC_step3.gz -- cmsRunTC step3_igprof.py -j step3_igprof_mem_TC_JobReport.xml >& step3_igprof_mem_TC.log
    rename_igprof igprofMEM_TC_step3
else
    echo missing step3_igprof.py
fi


if [ -f step4_igprof.py ]; then
    echo step4 w/igprof -mp cmsRunTC
    igprof -mp -z -o ./igprofMEM_TC_step4.gz -- cmsRunTC step4_igprof.py -j step4_igprof_mem_TC_JobReport.xml >& step4_igprof_mem_TC.log
    rename_igprof igprofMEM_TC_step4
else
    echo missing step4_igprof.py
fi

if [ $(ls -d step5*.py | wc -l) -gt 0 ]; then
    echo step5 w/igprof -mp cmsRunTC
    igprof -mp -z -o ./igprofMEM_TC_step5.gz -- cmsRunTC step5_igprof.py -j step5_igprof_mem_TC_JobReport.xml >& step5_igprof_mem_TC.log
    rename_igprof igprofMEM_TC_step5
else
    echo no step5 in workflow $PROFILING_WORKFLOW
fi
