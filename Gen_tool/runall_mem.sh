#!/bin/bash -x
if [ "X$CMSSW_VERSION" == "X" ];then
  CMSSW_v=$1
else
  CMSSW_v=$CMSSW_VERSION
fi
echo $CMSSW_v
## --1. Install CMSSW version and setup environment
if [ "X$ARCHITECTURE" != "X" ];then
  export SCRAM_ARCH=$ARCHITECTURE
else
  export SCRAM_ARCH=slc7_amd64_gcc900
fi

if [ "X$PROFILING_WORKFLOW" == "X" ];then
  export PROFILING_WORKFLOW="23434.21"
fi 

if [ "X$WORKSPACE" != "X" ]; then
  cd $WORKSPACE/$CMSSW_v/$PROFILING_WORKFLOW
else
  export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
  source $VO_CMS_SW_DIR/cmsset_default.sh
  cd $CMSSW_v/TimeMemory
  eval `scramv1 runtime -sh`
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

if [ "X$WORKSPACE" != "X" ]; then
  export WRAPPER=$WORKSPACE/profiling/ascii-out-wrapper.py
else
  export WRAPPER=$HOME/profiling/ascii-out-wrapper.py
fi
LC_ALL=C

if [ "X$TIMEOUT" == "X" ];then
    export TIMEOUT=43200
fi

function rename_igprof {
for f in $(ls -1 IgProf*.gz);do
    p=${f/IgProf/$1}
    s=${p/gz/$2}
    mv $f $s
done
}

if [ "X$RUNALLSTEPS" == "Xtrue" ]; then

  echo step1 w/igprof -mp
  igprof -mp -o ./igprofMEM_step1.mp -- cmsRunGLibC  step1_igprof.py  >& step1_igprof_mem.log
  rename_igprof igprofMEM_step1 mp

  echo step2 w/igprof -mp
  igprof -mp -o ./igprofMEM_step2.mp -- cmsRunGlibC step2_igprof.py >& step2_igprof_mem.log
  rename_igprof igprofMEM_step1 mp

fi

echo step3 w/igprof -mp
igprof -mp -o ./igprofMEM_step3.mp -- cmsRunGlibC step3_igprof.py  >& step3_igprof_mem.log
rename_igprof igprofMEM_step3 mp


echo step4 w/igprof -mp
igprof -mp -o ./igprofMEM_step4.mp -- cmsRunGlibC  step4_igprof.py  >& step4_igprof_mem.log
rename_igprof igprofMEM_step4 mp

if [ $(ls -d step5*.py | wc -l) -gt 0 ]; then
    echo step5 w/igprof -mp
    igprof -mp -o ./igprofMEM_step5.mp -- cmsRunGlibC  step5_igprof.py  >& step5_igprof_mem.log
    rename_igprof igprofMEM_step5 mp
else
    echo no step5
fi
