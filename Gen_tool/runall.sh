#!/bin/bash -x
CMSSW_v=$1


VDT=""

echo "Your SCRAM_ARCH "

if [ "X$ARCHITECTURE" != "X" ]; then
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
  echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
  source $VO_CMS_SW_DIR/cmsset_default.sh
  cd $CMSSW_v/TimeMemory
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

echo "My loc"
echo $PWD

if [ "X$WORKSPACE" != "X" -a "X$NOWRAPPER" == "Xfalse" ]; then
  export WRAPPER=$WORKSPACE/profiling/circles-wrapper.py
fi

if [ "X$TIMEOUT" == "X" ];then
    export TIMEOUT=43200
fi


echo step1 
cmsRun$VDT $(ls *_GEN_SIM.py)  >& step1$VDT.log


echo step2 
cmsRun$VDT $(ls step2*.py) >& step2$VDT.log


echo step3 circles-wrapper optional
cmsRun$VDT $WRAPPER $(ls step3*.py)  >& step3$VDT.log


echo step4 circles-wrapper optional
cmsRun$VDT $WRAPPER $(ls step4*.py)  >& step4$VDT.log

