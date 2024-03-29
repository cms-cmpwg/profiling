#!/bin/bash
# ARCHITECTURE, RELEASE_FORMAT and PROFILING_WORKFLOW are defined in Jenkins job
# voms-proxy-init is run in Jenkins Singularity wrapper script.

## --1. Install CMSSW version and setup environment
if [ "X$CMSSW_VERSION" == "X" ];then
  CMSSW_v=$1
else
  CMSSW_v=$CMSSW_VERSION
fi
echo $CMSSW_v

if [ "X$ARCHITECTURE" != "X" ];then
  export SCRAM_ARCH=$ARCHITECTURE
fi
echo $SCRAM_ARCH

if [ "X$RELEASE_FORMAT" == "X" -a  "X$CMSSW_IB" == "X" ]; then
  export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
  source $VO_CMS_SW_DIR/cmsset_default.sh
  voms-proxy-init -voms cms
  echo "Start install ${CMSSW_v} ..."
  scram project ${CMSSW_v}
  echo "Install success"
  echo "Set CMSSW environment ...'"
  cd ${CMSSW_v}
  eval `scram runtime -sh`
else
  cd $WORKSPACE/${CMSSW_v}
fi

## --2. "RunThematrix" dry run

if [ "X$PROFILING_WORKFLOW" == "X" ];then
  export PROFILING_WORKFLOW="24834.21"
fi
if [ "X$NTHREADS" == "X" ]; then
  export NTHREADS=1
fi
if [ "X$EVENTS" == "X" ];then
  export EVENTS=10
fi


(runTheMatrix.py -n | grep "^$PROFILING_WORKFLOW " 2>/dev/null) || WHAT='-w cleanedupgrade,standard,highstats,pileup,generator,extendedgen,production,identity,ged,machine,premix,nano,gpu,2017,2026'
[ $(runTheMatrix.py -n $WHAT | grep "^$PROFILING_WORKFLOW" | wc -l) -gt 0 ] || exit 0
declare -a outname
if [ "X$WORKSPACE" != "X" ];then
#running on Jenkins WORKSPACE is defined and we want to generate and run the config files
  runTheMatrix.py $WHAT -l $PROFILING_WORKFLOW --command=--number=$EVENTS\ --nThreads=$NTHREADS\ --no_exec
  outname=$(ls -d ${PROFILING_WORKFLOW}*)
  if [ -d $PROFILING_WORKFLOW ];then
	  mv $outname $PROFILING_WORKFLOW.1
  else 
	  mv $outname $PROFILING_WORKFLOW
  fi 
  cd $PROFILING_WORKFLOW
else
  NCPU=$(cat /proc/cpuinfo | grep processor| wc -l)
  NTHREADS=$((NCPU/2))
  EVENTS=$((NTHREADS*10))
  runTheMatrix.py $WHAT -l $PROFILING_WORKFLOW --ibeos --command=--number=$EVENTS\ --nThreads=$NTHREADS\ --no_exec #200PU for 11_2_X
  outname=$(ls -d ${PROFILING_WORKFLOW}_*)
  if [ -d $PROFILING_WORKFLOW];then
	  mv $outname $PROFILING_WORKFLOW.1
  else 
	  mv $outname $PROFILING_WORKFLOW
  fi 
  cd $PROFILING_WORKFLOW
fi

#source /cvmfs/projects.cern.ch/intelsw/oneAPI/linux/x86_64/2024/vtune/latest/vtune-vars.sh
#source /opt/intel/oneapi/vtune/latest/vtune-vars.sh
#CMSRUN=`which cmsRun`
#VTUNE=`which vtune`
#$VTUNE -collect hotspots -collect-with runss -data-limit=0 -knob enable-stack-collection=true -knob stack-size=4096 -knob sampling-mode=sw -- $CMSRUN $(ls TTbar*.py) >step1.log 2>&1
#$VTUNE -collect hotspots -collect-with runss -data-limit=0 -knob enable-stack-collection=true -knob stack-size=4096 -knob sampling-mode=sw -- $CMSRUN $(ls step2*.py) >step2.log 2>&1
#$VTUNE -collect hotspots -collect-with runss -data-limit=0 -knob enable-stack-collection=true -knob stack-size=4096 -knob sampling-mode=sw -- $CMSRUN $(ls step3*.py) >step3.log 2>&1
#$VTUNE -collect hotspots -collect-with runss -data-limit=0 -knob enable-stack-collection=true -knob stack-size=4096 -knob sampling-mode=sw -- $CMSRUN $(ls step4*.py) >step4.log 2>&1
#$VTUNE -collect hotspots -collect-with runss -data-limit=0 -knob enable-stack-collection=true -knob stack-size=4096 -knob sampling-mode=sw -- $CMSRUN $(ls step5*.py) >step5.log 2>&1
#$VTUNE -report gprof-cc -r r000hs -format=csv -csv-delimiter=semicolon >r000hs.gprof_cc.csv; gzip r000hs.gprof_cc.csv
#$VTUNE -report gprof-cc -r r001hs -format=csv -csv-delimiter=semicolon >r001hs.gprof_cc.csv; gzip r001hs.gprof_cc.csv
#$VTUNE -report gprof-cc -r r002hs -format=csv -csv-delimiter=semicolon >r002hs.gprof_cc.csv; gzip r002hs.gprof_cc.csv
#$VTUNE -report gprof-cc -r r003hs -format=csv -csv-delimiter=semicolon >r003hs.gprof_cc.csv; gzip r003hs.gprof_cc.csv
#$VTUNE -report gprof-cc -r r004hs -format=csv -csv-delimiter=semicolon >r004hs.gprof_cc.csv; gzip r004hs.gprof_cc.csv
#$VTUNE -collect memory-consumption -- $CMSRUN $(ls step3*.py) >step3-mem.log 2>&1
#$VTUNE -collect memory-consumption -- $CMSRUN $(ls step4*.py) >step4-mem.log 2>&1
