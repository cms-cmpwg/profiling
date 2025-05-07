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
fi

if [ "X$PROFILING_WORKFLOW" == "X" ];then
  export PROFILING_WORKFLOW="29834.21"
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

LC_ALL=C


if [ "X$TIMEOUT" == "X" ];then
    export TIMEOUT=18000
fi


function rename_igprof {
for f in $(ls -1 IgProf*.gz);do
    mv $f ${f/IgProf/$1}
done
}

pwd

# ensure that compiler include paths are added to ROOT_INCLUDE_PATH
for path in $(LC_ALL=C g++   -xc++ -E -v /dev/null 2>&1 | sed -n -e '/^.include/,${' -e '/^ \/.*++/p' -e '}');do ROOT_INCLUDE_PATH=$path:$ROOT_INCLUDE_PATH; done

scram tool info tensorflow
case $CMSSW_VERSION in
	CMSSW_15_1_*)
	  file=$( ls -1 /cvmfs/cms-ib.cern.ch/sw/x86_64/nweek-*/$SCRAM_ARCH/cms/cmssw/CMSSW_15_1_MKLDNN0_*/config/toolbox/$SCRAM_ARCH/tools/selected/tensorflow.xml|tail -1);echo $file; scram setup $file | /bin/true; scram b ToolUpdated;scram tool info tensorflow ;;
esac

export TF_ENABLE_ZENDNN_OPTS=1
export OMP_NUM_THREADS=1
export MALLOC_CONF=zero:true
export TF_ENABLE_ONEDNN_OPTS=0
#export ONEDNN_MAX_CPU_ISA=avx2
#export ONEDNN_JIT_PROFILE=6
#export JITDUMPDIR=.

. cmd_ig.sh

if [ "X$RUNALLSTEPS" != "X" ]; then
  if [ -f step1_igprof.py ]; then
    echo step1 w/igprof -pp cmsRun
    igprof -pp -d -t cmsRun -z -o ./igprofCPU_step1.gz -- cmsRun step1_igprof.py >& step1_igprof_cpu.log
    rename_igprof igprofCPU_step1
  else
    echo missing step1_igprof.py
  fi

  if [ -f step2_igprof.py ]; then
    echo step2  w/igprof -pp cmsRun
    igprof -pp -d -t cmsRun -z -o ./igprofCPU_step2.gz -- cmsRun step2_igprof.py  >& step2_igprof_cpu.log
    rename_igprof igprofCPU_step2
  else
    echo missing step2_igprof.py
  fi
fi

if [ -f step3_igprof.py ]; then
  echo step3  w/igprof -pp cmsRun
  igprof -pp -d -t cmsRun -z -o ./igprofCPU_step3.gz -- cmsRun step3_igprof.py >& step3_igprof_cpu.log
  rename_igprof igprofCPU_step3
else
    echo missing step3_igprof.py
fi

#if [ -f step4_igprof.py ]; then
#  echo step4  w/igprof -pp cmsRun
#  igprof -pp -d -t cmsRun -z -o ./igprofCPU_step4.gz -- cmsRun step4_igprof.py >& step4_igprof_cpu.log
#  rename_igprof igprofCPU_step4
#else
#    echo missing step4_igprof.py
#fi

#if [ -f step5_igprof.py ]; then
#  echo step5  w/igprof -pp cmsRun
#  igprof -pp -d -t cmsRun -z -o ./igprofCPU_step5.gz -- cmsRun step5_igprof.py >& step5_igprof_cpu.log
#  rename_igprof igprofCPU_step5
#else
#    echo no step5 in workflow $PROFILING_WORKFLOW
#fi

