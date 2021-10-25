#!/bin/bash -x
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
else
  export SCRAM_ARCH=slc7_amd64_gcc900
fi
echo $SCRAM_ARCH

if [ "X$RELEASE_FORMAT" == "X" -a  "X$CMSSW_IB" == "X" ]; then
  export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
  source $VO_CMS_SW_DIR/cmsset_default.sh
  source /cvmfs/grid.cern.ch/etc/profile.d/setup-cvmfs-ui.sh
  grid-proxy-init
  unset PYTHONPATH
  export LC_ALL=C
  echo "Start install ${CMSSW_v} ..."
  scramv1 project ${CMSSW_v}
  echo "Install success"
  echo "Set CMSSW environment ...'"
  cd ${CMSSW_v}
  eval `scramv1 runtime -sh`  
else
  cd $WORKSPACE/${CMSSW_v}
fi 

## --2. "RunThematrix" dry run

if [ "X$PROFILING_WORKFLOW" == "X" ];then
  export PROFILING_WORKFLOW="23434.21"
fi 
if [ "X$EVENTS" == "X" ];then
  export EVENTS=20
fi 

if [ "X$NTHREADS" == "X" ]; then
  export NTHREADS=1
fi


if [ "X$WORKSPACE" != "X" ];then
#running on Jenkins WORKSPACE is defined and we want to generate and run the config files
  runTheMatrix.py -w upgrade -l $PROFILING_WORKFLOW --command=--number=$EVENTS\ --nThreads=$NTHREADS\ --no_exec\ --dirin=$WORKSPACE\ --dirout=$WORKSPACE  #200PU for 11_2_X
  outname=$(ls -d ${PROFILING_WORKFLOW}*) 
  mv $outname $PROFILING_WORKFLOW
  cd $PROFILING_WORKFLOW
else
  NCPU=$(cat /proc/cpuinfo | grep processor| wc -l)
  NTHREADS=$((NCPU/2))
  EVENTS=$((NTHREADS*20))
  runTheMatrix.py -w upgrade -l $PROFILING_WORKFLOW --ibeos --command=--number=$EVENTS\ --nThreads=$NTHREADS\ --no_exec #200PU for 11_2_X
# find the workflow subdirectory created by runTheMatrix.py which always starts with the WF number
# rename the WF subdir to TimeMemory
  outname=$(ls -d ${PROFILING_WORKFLOW}_*) 
  mv $outname TimeMemory
  cd TimeMemory
fi

unset steps
declare -a steps
while IFS=$ read -r line; do     steps+=( "$line" ); done < <( grep cmsDriver.py cmdLog | cut -d\> -f1 )

echo "#!/bin/bash " > cmd_ft.sh
echo "#!/bin/bash " > cmd_ig.sh
echo "#!/bin/bash " > cmd_ts.sh
declare -i step
for ((step=0;step<${#steps[@]}; ++step));do 
    echo "${steps[$step]} --customise=Validation/Performance/TimeMemoryInfo.py --python_filename=step$((step+1))_timememoryinfo.py --suffix \"-j step"$((step+1))"_JobReport.xml\"" >>cmd_ig.sh
    echo "${steps[$step]} --customise Validation/Performance/IgProfInfo.customise  --customise_commands \"process.RECOSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.RECOSIMEventContent.outputCommands);process.AODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.AODSIMEventContent.outputCommands);process.MINIAODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.MINIAODSIMEventContent.outputCommands)\" --python_filename=step"$((step+1))"_igprof.py --suffix \"-j step"$((step+1))"_igprof_JobReport.xml\"" >>cmd_ig.sh
    if [ $step -eq 2 ];then
        echo "${steps[$step]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step3_RAW2DIGI_L1Reco_RECO_RECOSIM_PU.resources.json');process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step3_fasttimer.py --suffix \"-j step3_fasttimer_JobReport.xml\"" >>cmd_ft.sh
    fi
    if [ $step -eq 3 ];then
        echo "${steps[$step]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step4_PAT_PU.resources.json');process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step3_fasttimer.py --suffix \"-j step3_fasttimer_JobReport.xml\"" >>cmd_ft.sh
    fi
    if [ $step -eq 4 ];then
        echo "${steps[$step]} --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);process.FastTimerService.jsonFileName = cms.untracked.string('step5_NANO_PU.resources.json');process.options.numberOfConcurrentLuminosityBlocks = 1\" --python_filename=step5_fasttimer.py --suffix \"-j step5_fasttimer_JobReport.xml\"" >>cmd_ft.sh
    fi
done
. cmd_ft.sh
. cmd_ig.sh
. cmd_ts.sh

## --4. Make profiler 

cat << EOF >> profile.sh
#!/bin/bash
for f in \$(ls igprofCPU_step*.gz 2>/dev/null);do
## --For web-based report
    sqlf=\${f/gz/sql3}
    sf=\${f/igprof/}
    logf=\${sf/gz/log}
    igprof-analyse --sqlite -v -d -g \$f | sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 \$sqlf >& \$logf
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
chmod +x profile.sh

cat << EOF >> profile_mem.sh
#!/bin/bash

for f in \$(ls igprofMEM_step*.mp 2>/dev/null);do
## --For web-based report
    sqlf=\${f/mp/sql3}
    sf=\${f/igprofMEM/MEMsql}
    logf=\${sf/mp/log}
    igprof-analyse --sqlite -v -d -g -r MEM_LIVE \$f |sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 \$sqlf >& \$logf
## --For ascii-based report
    rf=\${f/igprof/RES_}
    txtf=\${rf/mp/txt}
    igprof-analyse  -v -d -g -r MEM_LIVE \$f >& \$txtf
done
EOF
chmod +x profile_mem.sh
