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
  export PROFILING_WORKFLOW="23834.21"
fi

if [ "X$NTHREADS" == "X" ]; then
  export NTHREADS=2
fi

if [ "X$EVENTS" == "X" ];then
  export EVENTS=$((NTHREADS*10))
fi

(runTheMatrix.py -n | grep "^$PROFILING_WORKFLOW " 2>/dev/null) || WHAT='-w upgrade'
[ $(runTheMatrix.py -n $WHAT | grep ^$PROFILING_WORKFLOW | wc -l) -gt 0 ] || exit 0

declare -a outname
if [ "X$WORKSPACE" != "X" ];then
#running on Jenkins WORKSPACE is defined and we want to generate and run the config files
  runTheMatrix.py $WHAT -l $PROFILING_WORKFLOW --command=--number=$EVENTS\ --nThreads=$NTHREADS\ --no_exec
  outname=$(ls -d ${PROFILING_WORKFLOW}*)
  mv $outname $PROFILING_WORKFLOW
  cd $PROFILING_WORKFLOW
else
  NCPU=$(cat /proc/cpuinfo | grep processor| wc -l)
  NTHREADS=$((NCPU/2))
  EVENTS=$((NTHREADS*10))
  runTheMatrix.py $WHAT -l $PROFILING_WORKFLOW --ibeos --command=--number=$EVENTS\ --nThreads=$NTHREADS\ --no_exec
  outname=$(ls -d ${PROFILING_WORKFLOW}_*)
  mv $outname $PROFILING_WORKFLOW
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
echo "#!/bin/bash " > cmd_np.sh
declare -i step
for step in ${!steps[@]};do t1=${steps[$step]/:@phase2Validation+@miniAODValidation,DQM:@phase2+@miniAODDQM/};t2=${t1/,VALIDATION/};t3=${t2/,DQMIO/};t4=${t3/,DQM/};steps[$step]=$t4;echo $steps[$step];done;
# For reHLT workflows the steps are shifted
if ( echo $outname | grep -q '136' ); then
      echo "Workflow 136.XYZ has no gpu enabled modules"
else
  for ((step=0;step<${#steps[@]}; ++step));do
     echo "${steps[$step]} --accelerators gpu-nvidia --procModifiers pixelNtupletFit,gpu --fileout file:step$((step+1))_gpu.root --customise=Validation/Performance/TimeMemorySummary.py --python_filename=step$((step+1))_gpu_timememoryinfo.py" >>cmd_ts.sh
     echo "${steps[$step]} --accelerators gpu-nvidia --procModifiers pixelNtupletFit,gpu --fileout file:step$((step+1))_gpu.root --customise Validation/Performance/IgProfInfo.customise  --customise_commands \"process.FEVTDEBUGoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGEventContent.outputCommands);process.FEVTDEBUGHLToutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGHLTEventContent.outputCommands);process.RECOSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.RECOSIMEventContent.outputCommands);process.AODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.AODSIMEventContent.outputCommands);process.MINIAODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.MINIAODSIMEventContent.outputCommands);process.DQMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.DQMEventContent.outputCommands)\" --python_filename=step"$((step+1))"_gpu_igprof.py" >>cmd_ig.sh
     echo "${steps[$step]} --accelerators gpu-nvidia --procModifiers pixelNtupletFit,gpu --fileout file:step$((step+1))_gpu.root --customise Validation/Performance/IgProfInfo.customise  --customise_commands \"process.FEVTDEBUGoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGEventContent.outputCommands);process.FEVTDEBUGHLToutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGHLTEventContent.outputCommands);process.RECOSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.RECOSIMEventContent.outputCommands);process.AODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.AODSIMEventContent.outputCommands);process.MINIAODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.MINIAODSIMEventContent.outputCommands);process.DQMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.DQMEventContent.outputCommands);process.options.numberOfConcurrentLuminosityBlocks = 1;process.add_(cms.Service('NVProfilerService', highlightModules = cms.untracked.vstring('siPixelClustersPreSplittingCUDA')))\" --python_filename=step"$((step+1))"_gpu_nvprof.py" >>cmd_np.sh
  done
fi

# For reHLT workflows the steps are shifted
if ( echo $outname | grep -q '136') ; then
      echo "Workflow 136.XYZ has no gpu enabled modules"
else
  echo "${steps[0]} --accelerators gpu-nvidia --procModifiers pixelNtupletFit,gpu --fileout file:step1_gpu.root --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step1_gpu.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step1_gpu_fasttimer.py" >>cmd_ft.sh
  echo "${steps[1]} --accelerators gpu-nvidia --procModifiers pixelNtupletFit,gpu --fileout file:step2_gpu.root --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step2_gpu.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step2_gpu_fasttimer.py" >>cmd_ft.sh
  echo "${steps[2]} --accelerators gpu-nvidia --procModifiers pixelNtupletFit,gpu --fileout file:step3_gpu.root --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step3_gpu.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step3_gpu_fasttimer.py" >>cmd_ft.sh
  echo "${steps[3]} --accelerators gpu-nvidia --procModifiers pixelNtupletFit,gpu --fileout file:step4_gpu.root --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step4_gpu.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step4_gpu_fasttimer.py" >>cmd_ft.sh
# check for 5th step
if ( echo ${!steps[@]} | grep -q 4 );then
  echo "${steps[4]} --accelerators gpu-nvidia --procModifiers pixelNtupletFit,gpu --fileout file:step5_gpu.root --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step5_gpu.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1;\" --python_filename=step5_gpu_fasttimer.py" >>cmd_ft.sh
  fi
fi
. cmd_ts.sh
. cmd_ft.sh
. cmd_ig.sh
. cmd_np.sh
