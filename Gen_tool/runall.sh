#!/bin/bash -x
if [ "X$CMSSW_VERSION" == "X" ];then
  CMSSW_v=$1
else
  CMSSW_v=$CMSSW_VERSION
fi

VDT=""

if [ "X$ARCHITECTURE" != "X" ]; then
  export SCRAM_ARCH=$ARCHITECTURE
else
  export SCRAM_ARCH=slc7_amd64_gcc100
fi

if [ "X$PROFILING_WORKFLOW" == "X" ];then
  export PROFILING_WORKFLOW="35234.21"
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

if [ "X$WORKSPACE" != "X" -a "X$NOWRAPPER" == "X" ]; then
  export WRAPPER=$WORKSPACE/profiling/circles-wrapper.py
else
  export WRAPPER=$HOME/profiling/circles-wrapper.py
fi

if [ "X$TIMEOUT" == "X" ];then
    export TIMEOUT=43200
fi

if [ -f step1_timememoryinfo.py ]; then
  echo step1 TimeMemory
  cmsRun$VDT step1_timememoryinfo.py >& step1_timememoryinfo$VDT.txt
fi

echo step2 TimeMemory
cmsRun$VDT step2_timememoryinfo.py >& step2_timememoryinfo$VDT.txt

if [ "X$RUNTIMEMEMORY" != "X" ]; then
  echo step3 TimeMemory
  cmsRun$VDT step3_timememoryinfo.py >& step2_timememoryinfo$VDT.txt

  echo step4 TimeMemory
  cmsRun$VDT step3_timememoryinfo.py >& step3_timememoryinfo$VDT.txt

  if [ -f step5_timememoryinfo.py ]; then
      echo step5 TimeMemory
      cmsRun$VDT step5_timememoryinfo.py  >& step5_timememoryinfo$VDT.txt
  fi
fi

if [ -f step2_fasttimer.py ];then
    echo step2 circles-wrapper optional
    cmsRun$VDT step2_fasttimer.py  >& step2_fasttimer$VDT.txt
fi

echo step3 circles-wrapper optional
cmsRun$VDT step3_fasttimer.py  >& step3_fasttimer$VDT.txt

echo step4 circles-wrapper optional
cmsRun$VDT step4_fasttimer.py  >& step4_fasttimer$VDT.txt

if [ -f step5_fasttimer.py ]; then
    echo step5 circles-wrapper optional
    cmsRun$VDT step5_fasttimer.py  >& step5_fasttimer$VDT.txt
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
