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
  export PROFILING_WORKFLOW="29834.21"
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

pwd
scram tool info tensorflow
case $SCRAM_ARCH in
	el8*)
        scram setup /cvmfs/cms-ib.cern.ch/sw/x86_64/latest/$SCRAM_ARCH/cms/cmssw/CMSSW_15_1_MKLDNN0_*/config/toolbox/$SCRAM_ARCH/tools/selected/tensorflow.xml;;
esac
scram b ToolUpdated
scram tool info tensorflow

export TF_ENABLE_ZENDNN_OPTS=1
export OMP_NUM_THREADS=1
export MALLOC_CONF=zero:true
export TF_ENABLE_ONEDNN_OPTS=0
#export ONEDNN_MAX_CPU_ISA=avx2
#export ONEDNN_JIT_PROFILE=1
#export JITDUMPDIR=.
. cmd_ts.sh
echo Run with Vtune
if [ "X$RUNALLSTEPS" != "X" ]; then
  if [ -f step1_timememoryinfo.py ];then
      echo step1 Vtune
      vtune -collect hotspots -r r-step1-$PROFILING_WORKFLOW-hs -data-limit=0 -knob enable-stack-collection=true -knob  stack-size=4096 -knob sampling-mode=sw -- cmsRun step1_timememoryinfo.py >& step1-vtune.log
      vtune -report gprof-cc -r r-step1-$PROFILING_WORKFLOW-hs -format=csv -csv-delimiter=semicolon  -report-output step1-$PROFILING_WORKFLOW.gprof-cc.csv
      gzip step1-$PROFILING_WORKFLOW.gprof-cc.csv
  else
    echo missing step1_timememoryinfo.py
  fi

  if [ -f step2_timememoryinfo.py ];then
      echo step2 FastTimer
      vtune -collect hotspots -r r-step2-$PROFILING_WORKFLOW-hs -data-limit=0 -knob enable-stack-collection=true -knob  stack-size=4096 -knob sampling-mode=sw -- cmsRun step2_timememoryinfo.py >& step2-vtune.log
      vtune -report gprof-cc -r r-step2-$PROFILING_WORKFLOW-hs -format=csv -csv-delimiter=semicolon  -report-output step2-$PROFILING_WORKFLOW.gprof-cc.csv
      gzip step2-$PROFILING_WORKFLOW.gprof-cc.csv
  else
    echo missing step2_timememoryinfo.py
  fi
fi
  if [ -f step3_timememoryinfo.py ]; then
    echo step3 Vtune
    vtune -collect hotspots -r r-step3-$PROFILING_WORKFLOW-hs -data-limit=0 -knob enable-stack-collection=true -knob  stack-size=4096 -knob sampling-mode=sw -- cmsRun step3_timememoryinfo.py >& step3-vtune.log
      vtune -report gprof-cc -r r-step3-$PROFILING_WORKFLOW-hs -format=csv -csv-delimiter=semicolon  -report-output step3-$PROFILING_WORKFLOW.gprof-cc.csv
      gzip step3-$PROFILING_WORKFLOW.gprof-cc.csv
  else
    echo missing step3_timememoryinfo.py
  fi

  if [ -f step4_timememoryinfo.py ]; then
    echo step4 Vtune
    vtune -collect hotspots -r r-step4-$PROFILING_WORKFLOW-hs -data-limit=0 -knob enable-stack-collection=true -knob  stack-size=4096 -knob sampling-mode=sw -- cmsRun step4_timememoryinfo.py >& step4-vtune.log
      vtune -report gprof-cc -r r-step4-$PROFILING_WORKFLOW-hs -format=csv -csv-delimiter=semicolon  -report-output step4-$PROFILING_WORKFLOW.gprof-cc.csv
      gzip step4-$PROFILING_WORKFLOW.gprof-cc.csv
  else
    echo missing step4_timememoryinfo.py
  fi

  if [ -f step5_timememoryinfo.py ]; then
      echo step5 FastTimer
      vtune -collect hotspots -r r-step5-$PROFILING_WORKFLOW-hs -data-limit=0 -knob enable-stack-collection=true -knob  stack-size=4096 -knob sampling-mode=sw -- cmsRun step5_timememoryinfo.py >& step5-vtune.log
      vtune -report gprof-cc -r r-step5-$PROFILING_WORKFLOW-hs -format=csv -csv-delimiter=semicolon  -report-output step5-$PROFILING_WORKFLOW.gprof-cc.csv
      gzip step5-$PROFILING_WORKFLOW.gprof-cc.csv
  else
    echo no step5 in workflow $PROFILING_WORKFLOW
  fi

