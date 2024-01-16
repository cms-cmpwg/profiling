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
  export PROFILING_WORKFLOW="23834.21"
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

scram setup /cvmfs/cms.cern.ch/el8_amd64_gcc12/cms/cmssw-tool-conf/60.0/tools/selected/tensorflow.xml
scram b ToolUpdated
scram tool info tensorflow 

if [ "X$RUNALLSTEPS" != "X" ]; then
  if [ -f step1_igprof.py ]; then
    echo step1 w/igprof -pp cmsRun
    igprof -pp -d -t cmsRun -z -o ./igprofCPU_step1.gz -- cmsRun step1_igprof.py -j step1_igprof_cpu_JobReport.xml >& step1_igprof_cpu.log
    rename_igprof igprofCPU_step1
  else
    echo missing step1_igprof.py
  fi

  if [ -f step2_igprof.py ]; then
    echo step2  w/igprof -pp cmsRun
    igprof -pp -d -t cmsRun -z -o ./igprofCPU_step2.gz -- cmsRun step2_igprof.py -j step2_igprof_cpu_JobReport.xml >& step2_igprof_cpu.log
    rename_igprof igprofCPU_step2
  else
    echo missing step2_igprof.py
  fi
fi

if [ -f step3_igprof.py ]; then
  echo step3  w/igprof -pp cmsRun
  igprof -pp -d -t cmsRun -z -o ./igprofCPU_step3.gz -- cmsRun step3_igprof.py -j step3_igprof_cpu_JobReport.xml >& step3_igprof_cpu.log
  rename_igprof igprofCPU_step3
else
    echo missing step3_igprof.py
fi

if [ -f step4_igprof.py ]; then
  echo step4  w/igprof -pp cmsRun
  igprof -pp -d -t cmsRun -z -o ./igprofCPU_step4.gz -- cmsRun step4_igprof.py -j step4_igprof_cpu_JobReport.xml >& step4_igprof_cpu.log
  rename_igprof igprofCPU_step4
else
    echo missing step4_igprof.py
fi

if [ -f step5_igprof.py ]; then
  echo step5  w/igprof -pp cmsRun
  igprof -pp -d -t cmsRun -z -o ./igprofCPU_step5.gz -- cmsRun step5_igprof.py -j step5_igprof_cpu_JobReport.xml >& step5_igprof_cpu.log
  rename_igprof igprofCPU_step5
else
    echo no step5 in workflow $PROFILING_WORKFLOW
fi

