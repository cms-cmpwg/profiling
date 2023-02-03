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
  export PROFILING_WORKFLOW="21034.21"
fi

if [ "X$NTHREADS" == "X" ]; then
  export NTHREADS=1
fi

if [ "X$EVENTS" == "X" ];then
  export EVENTS=$(($NTHREADS*10))
fi

(runTheMatrix.py -n | grep "^$PROFILING_WORKFLOW " 2>/dev/null) || WHAT='-w upgrade'

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
declare -i step
# For reHLT workflows the steps are shifted
if ( echo $outname | grep '136' ); then
  for ((step=0;step<${#steps[@]}; ++step));do
      echo "${steps[$step]} --customise=Validation/Performance/TimeMemoryInfo.py --python_filename=step$((step+2))_timememoryinfo.py" >>cmd_ts.sh
      echo "${steps[$step]} --customise Validation/Performance/IgProfInfo.customise  --customise_commands \"process.FEVTDEBUGHLToutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGHLTEventContent.outputCommands);process.RECOSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.RECOSIMEventContent.outputCommands);process.AODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.AODSIMEventContent.outputCommands);process.MINIAODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.MINIAODSIMEventContent.outputCommands);process.DQMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.DQMEventContent.outputCommands);process.options.numberOfThreads = 1\" --python_filename=step"$((step+2))"_igprof.py" >>cmd_ig.sh
  done
else
  for ((step=0;step<${#steps[@]}; ++step));do
      echo "${steps[$step]} --customise=Validation/Performance/TimeMemoryInfo.py --python_filename=step$((step+1))_timememoryinfo.py" >>cmd_ts.sh
      echo "${steps[$step]} --customise Validation/Performance/IgProfInfo.customise  --customise_commands \"process.FEVTDEBUGoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGEventContent.outputCommands);process.FEVTDEBUGHLToutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGHLTEventContent.outputCommands);process.RECOSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.RECOSIMEventContent.outputCommands);process.AODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.AODSIMEventContent.outputCommands);process.MINIAODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.MINIAODSIMEventContent.outputCommands);process.DQMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.DQMEventContent.outputCommands);process.options.numberOfThreads = 1\" --python_filename=step"$((step+1))"_igprof.py"  >>cmd_ig.sh
  done
fi

# For reHLT workflows the steps are shifted
if ( echo $outname | grep -q '136') ; then
  echo "${steps[0]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step2_L1REPACK_HLT.resources.json');process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step2_fasttimer.py" >>cmd_ft.sh
  echo "${steps[1]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step3_RAW2DIGI_L1Reco_RECO_SKIM_PAT_ALCA_DQM.resources.json');process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step3_fasttimer.py" >>cmd_ft.sh
  echo "${steps[2]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step4_HARVESTING.resources.json');process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step4_fasttimer.py" >>cmd_ft.sh
else
  echo "${steps[0]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step1_GEN_SIM.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step1_fasttimer.py " >>cmd_ft.sh
  echo "${steps[1]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step2_DIGI_L1TrackTrigger_L1_DIGI2RAW_HLT_PU.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step2_fasttimer.py" >>cmd_ft.sh
  echo "${steps[2]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step3_RAW2DIGI_L1Reco_RECO_RECOSIM_PU.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step3_fasttimer.py" >>cmd_ft.sh
  echo "${steps[3]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step4_PAT_PU.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step4_fasttimer.py" >>cmd_ft.sh
# check for 5th step
if ( echo ${!steps[@]} | grep -q 4 );then
  echo "${steps[4]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step5_NANO_PU.resources.json');process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step5_fasttimer.py" >>cmd_ft.sh
  fi
fi
. cmd_ft.sh
. cmd_ig.sh
. cmd_ts.sh
## --4. Make profiler

cat << EOF >> profile_igpp.sh
#!/bin/bash
wget https://raw.githubusercontent.com/cms-sw/cms-bot/master/fix-igprof-sql.py
for f in \$(ls igprofCPU_step*.gz 2>/dev/null);do
## --For web-based report
    sqlf=\${f/gz/sql3}
    sf=\${f/igprof/}
    logf=\${sf/gz/log}
    igprof-analyse --sqlite -v -d -g \$f >\$f.tmp
    python fix-igprof-sql.py \$f.tmp |  sqlite3 \$sqlf >& \$logf
## --For ascii-based report
    rf=\${f/igprof/RES_}
    txtf=\${rf/gz/txt}
    igprof-analyse  -v -d -g \$f >& \$txtf
done

if [ -f RES_CPU_step3.txt ]; then
  export IGREP=RES_CPU_step3.txt
  export IGSORT=sorted_RES_CPU_step3.txt
  awk -v module=doEvent 'BEGIN { total = 0; } { if(substr(\$0,0,1)=="-"){good = 0;}; if(good&&length(\$0)>0){print \$0; total += \$3;}; if(substr(\$0,0,1)=="["&&index(\$0,module)!=0) {good = 1;} } END { print "Total: "total } ' \${IGREP} | sort -n -r -k1 | awk '{ if(index(\$0,"Total: ")!=0){total=\$0;} else{print \$0;} } END { print total; }' > \${IGSORT} 2>&1
fi
EOF
chmod +x profile_igpp.sh

cat << EOF >> profile_igmp.sh
#!/bin/bash

for f in \$(ls igprofMEM_*[0-9].gz 2>/dev/null);do
## --For web-based report
    sqlf=\${f/gz/sql3}
    sf=\${f/igprofMEM/MEMsql}
    logf=\${sf/gz/log}
    igprof-analyse --sqlite -v -d -g -r MEM_LIVE \$f >\$f.tmp
    python fix-igprof-sql.py \$f.tmp | sqlite3 \$sqlf >& \$logf
## --For ascii-based report
    rf=\${f/igprof/RES_}
    txtf=\${rf/gz/txt}
    igprof-analyse  -v -d -g -r MEM_LIVE \$f >& \$txtf
done
EOF
chmod +x profile_igmp.sh

cat << EOF >>profile_mem_jemalloc.sh
#!/bin/bash
for f in \$(ls *.heap 2>/dev/null);do
  jeprof --text --cum --show_bytes --exclude="(jeprof_*|prof_*|fallback*)" `which cmsRunJE` \$f >\$f.txt
done
EOF
chmod +x profile_mem_jemalloc.sh
