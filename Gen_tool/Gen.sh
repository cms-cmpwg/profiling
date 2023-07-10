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

if [ "X$RELEASE_FORMAT" == "X" -a  "X$CMSSW_IB" == "X" -a "X$ARCHITECTURE" == "X" ]; then
  export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
  source $VO_CMS_SW_DIR/cmsset_default.sh
  voms-proxy-init
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
  export PROFILING_WORKFLOW="23834.59521"
fi

if [ "X$NTHREADS" == "X" ]; then
  export NTHREADS=1
fi

if [ "X$EVENTS" == "X" ];then
  export EVENTS=$(($NTHREADS*10))
fi

(runTheMatrix.py -n | grep "^$PROFILING_WORKFLOW " 2>/dev/null) || WHAT='-w upgrade'
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
  runTheMatrix.py $WHAT -l $PROFILING_WORKFLOW --ibeos --command=--number=$EVENTS\ --nThreads=$NTHREADS\ --no_exec
  outname=$(ls -d ${PROFILING_WORKFLOW}_*)
  if [ -d $PROFILING_WORKFLOW];then
	  mv $outname $PROFILING_WORKFLOW.1
  else 
	  mv $outname $PROFILING_WORKFLOW
  fi 
  cd $PROFILING_WORKFLOW
fi

unset steps
declare -a steps
while IFS=$ read -r line; do     steps+=( "$line" ); done < <( grep cmsDriver.py cmdLog | cut -d\> -f1 )
echo ${steps[@]}
echo ${!steps[@]}

echo "#!/bin/bash " > cmd_ft.sh
echo "#!/bin/bash " > cmd_ig.sh
echo "#!/bin/bash " > cmd_ts.sh
echo "#!/bin/bash " > cmd_je.sh
declare -i step
# For reHLT workflows the steps are shifted
if ( echo $outname | grep '136' ); then
  for ((step=0;step<${#steps[@]}; ++step));do
      echo "${steps[$step]} --customise=Validation/Performance/TimeMemorySummary.py --python_filename=step$((step+2))_timememoryinfo.py" >>cmd_ts.sh
      echo "${steps[$step]} --customise Validation/Performance/IgProfInfo.customise  --customise_commands \"process.FEVTDEBUGHLToutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGHLTEventContent.outputCommands);process.RECOSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.RECOSIMEventContent.outputCommands);process.AODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.AODSIMEventContent.outputCommands);process.MINIAODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.MINIAODSIMEventContent.outputCommands);process.DQMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.DQMEventContent.outputCommands);process.options.numberOfThreads = 1\" --python_filename=step"$((step+2))"_igprof.py" >>cmd_ig.sh
      echo "${steps[$step]} --customise Validation/Performance/JeProfInfo.customise  --customise_commands \"process.FEVTDEBUGHLToutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGHLTEventContent.outputCommands);process.RECOSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.RECOSIMEventContent.outputCommands);process.AODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.AODSIMEventContent.outputCommands);process.MINIAODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.MINIAODSIMEventContent.outputCommands);process.DQMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.DQMEventContent.outputCommands);process.options.numberOfThreads = 1\" --python_filename=step"$((step+2))"_jeprof.py" >>cmd_je.sh
  done
else
  for ((step=0;step<${#steps[@]}; ++step));do
      echo "${steps[$step]} --customise=Validation/Performance/TimeMemorySummary.py --python_filename=step$((step+1))_timememoryinfo.py" >>cmd_ts.sh
      echo "${steps[$step]} --customise Validation/Performance/IgProfInfo.customise  --customise_commands \"process.FEVTDEBUGoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGEventContent.outputCommands);process.FEVTDEBUGHLToutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGHLTEventContent.outputCommands);process.RECOSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.RECOSIMEventContent.outputCommands);process.AODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.AODSIMEventContent.outputCommands);process.MINIAODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.MINIAODSIMEventContent.outputCommands);process.DQMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.DQMEventContent.outputCommands);process.options.numberOfThreads = 1\" --python_filename=step"$((step+1))"_igprof.py"  >>cmd_ig.sh
      echo "${steps[$step]} --customise Validation/Performance/JeProfInfo.customise  --customise_commands \"process.FEVTDEBUGoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGEventContent.outputCommands);process.FEVTDEBUGHLToutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGHLTEventContent.outputCommands);process.RECOSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.RECOSIMEventContent.outputCommands);process.AODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.AODSIMEventContent.outputCommands);process.MINIAODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.MINIAODSIMEventContent.outputCommands);process.DQMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.DQMEventContent.outputCommands);process.options.numberOfThreads = 1\" --python_filename=step"$((step+1))"_jeprof.py"  >>cmd_je.sh
  done
fi

# For reHLT workflows the steps are shifted
if ( echo $outname | grep -q '136') ; then
  echo "${steps[0]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step2_cpu.resources.json');process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step2_fasttimer.py" >>cmd_ft.sh
  echo "${steps[1]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step3_cpu.resource.json');process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step3_fasttimer.py" >>cmd_ft.sh
  echo "${steps[2]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step4_cpu.resources.json');process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step4_fasttimer.py" >>cmd_ft.sh
else
  echo "${steps[0]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step1_cpu.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step1_fasttimer.py " >>cmd_ft.sh
  echo "${steps[1]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step2_cpu.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step2_fasttimer.py" >>cmd_ft.sh
  echo "${steps[2]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step3_cpu.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step3_fasttimer.py" >>cmd_ft.sh
  echo "${steps[3]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step4_cpu.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step4_fasttimer.py" >>cmd_ft.sh
# check for 5th step
if ( echo ${!steps[@]} | grep -q 4 );then
  echo "${steps[4]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step5_cpu.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step5_fasttimer.py" >>cmd_ft.sh
  fi
fi
. cmd_ts.sh
. cmd_ft.sh
if [ "$JOB_BASE_NAME" == "ib-run-profiling-mem" ];then
  . cmd_je.sh
else
  . cmd_ig.sh
fi
