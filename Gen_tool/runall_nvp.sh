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
  export PROFILING_WORKFLOW="23834.99"
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

  echo Run with NVProflierService
  if [ "X$RUNALLSTEPS" != "X" ]; then
    if [ -f step1_nvprof.py ];then
        echo step1 gpu NVProfiler
        nvprof -o step1.nvprof -s cmsRun step1_nvprof.py -j step1_nvprof_JobReport.xml >& step1_nvprof.log
    else
        echo missing step1_nvprof.py
    fi

    if [ -f step2_nvprof.py ];then
        echo step2 gpu NVProfiler
        nvprof -o step2.nvprof -s cmsRun step2_nvprof.py -j step2_nvprof_JobReport.xml >& step2_nvprof.log
    else
        echo missing step2_nvprof.py
    fi
  fi
  if [ -f step3_nvprof.py ];then
      echo step3 gpu NVProfiler
      nvprof -o step3.nvprof -s cmsRun step3_nvprof.py  -j step3_nvprof_JobReport.xml >& step3_nvprof.log
  else
      echo missing step3_nvprof.py
  fi

  if [ -f step4_nvprof.py ];then
      echo step4 gpu NVProfiler
      nvprof -o step4.nvprof -s cmsRun step4_nvprof.py -j step4_nvprof_JobReport.xml >& step4_nvprof.log
  else
      echo missing step4_nvprof.py
  fi

  if [ -f step5_nvprof.py ]; then
      echo step5 gpu NVProfiler
      nvprof -o step5.nvprof -s cmsRun step5_nvprof.py -j step5_nvprof_JobReport.xml >& step5_nvprof.log
  else
      echo no step5 in workflow
  fi
