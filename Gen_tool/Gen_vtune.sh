#!/bin/bash

CMSSW_v=$1

## --1. Install CMSSW version and setup environment
echo "Your SCRAM_ARCH "
export SCRAM_ARCH=slc7_amd64_gcc900
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
source $VO_CMS_SW_DIR/cmsset_default.sh

echo "Start install $CMSSW_v ..."
scramv1 project $CMSSW_v
echo "Install success"
echo "Set CMSSW environment ...'"
cd ${CMSSW_v}/src
eval `scramv1 runtime -sh`
#echo "Compiling ...'"
#scram b -j 6

## --2. "RunThematrix" dry run


#runTheMatrix.py -l 29034.21 -w upgrade --dryRun # NoPU

runTheMatrix.py -l 20634.21 -w upgrade --dryRun	# 200PU for 4 5 6 
#runTheMatrix.py -w upgrade -l 29234.21 --dryRun #200PU for 11_0_0_pre1 2 3 


#tail *.log

for i in $(ls -d 2*/); do 
outname=${i%%/}; done
mv $outname TimeMemory
cd TimeMemory


# --3. Make cmdLog run_option  -- Set N events
cat << EOF >> read.py
#!/usr/bin/env python
import subprocess

with open('cmdLog','r') as f:
        cnt=0
        for line in f:
                line=line.rstrip()
                if line.startswith(' cmsDriver'):
                        cnt+=1
## --Set N events
                        line=line.replace("-n 10","-n 160")
                        if cnt!=5:
                                line_list = line.split()
                                logfile = line_list[-2]
                                line_list.insert(-3,'--nThreads 16')
                                line_list.insert(-3,'--no_exec')
                                line_list.insert(-9,"--customise Validation/Performance/TimeMemoryInfo.py")
                                line=' '.join(line_list)
                                line=line.replace(logfile,"step%s.log"%cnt)
                                line=line.replace('file:', 'file:${OUTPUT_DIR:-"."}/')
## --Do not run step4
                        else:
                                 break
## --Excute cmsDriver
                        print(line)
                        print(" ")
                        subprocess.check_output (line,shell=True)
EOF

# run cmsDriver.py
chmod +x read.py
./read.py


## --4. Make profiler 



#EOF

cat << EOF >> vtune.sh
#!/bin/bash -x
. /cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/intel/oneapi-2021.1-beta05/inteloneapi/setvars.sh
. /cvmfs/cms.cern.ch/cmsset_default.sh
eval $(scram runtime -sh)
which cmsRun
which vtune
vtune -collect hotspots -collect gpu-offload -collect threading  $(which cmsRun) ./TTbar_14TeV_TuneCP5_cfi_GEN_SIM.py >step1.log 2>&1
vtune -collect hotspots -collect gpu-offload -collect threading  $(which cmsRun) ./step2_DIGI_L1_L1TrackTrigger_DIGI2RAW_HLT_PU.py >step2.log 2>&1
vtune -collect hotspots -collect gpu-offload -collect threading  $(which cmsRun) ./step3_RAW2DIGI_L1Reco_RECO_RECOSIM_PU.py >step3.log 2>&1
vtune -collect hotspots -collect gpu-offload -collect threading  $(which cmsRun) ./step4_PAT_PU.py >step4.log 2>&1
EOF

chmod +x vtune.sh
./vtune.sh