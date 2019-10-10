## CPU and Memory monitoring job  
---
### 1. All results are uploaded here: https://jiwoong.web.cern.ch/jiwoong/  
### 2. ASCII type results are uploaded N01_profile/10_6_X and N02_compare_summary/results_XX  
### 3. N01_profile covers basic output of Igprof and N02_compare_summary covers time and memory comparison based on step3.log*  
##### step3.log(Timechekc output) can be generated adding following code on python config files  

```python
# Automatic addition of the customisation function from Validation.Performance.TimeMemoryInfo
from Validation.Performance.TimeMemoryInfo import customise

#call to customisation function customise imported from Validation.Performance.TimeMemoryInfo
process = customise(process)
```  
---

## Steps for monitoring PhaseII

### 1. Install CMSSW version and setup environment
```bash
CMSSW_v = "YOUR CMSSW VERSION"
echo "Your SCRAM_ARCH "
export SCRAM_ARCH=slc7_amd64_gcc700
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
source $VO_CMS_SW_DIR/cmsset_default.sh
echo "Start install $CMSSW_v ..."
scramv1 project $CMSSW_v
echo "Install success"
echo "Set CMSSW environment and compiling..'"
cd $CMSSW_v/src
eval `scramv1 runtime -sh`
scram b -j 6
```

### 2. "RunThematrix" dryrun

"dryrun" option creates auto scripts for running cmsDriver
```bash
runTheMatrix.py -l 29034.21 -w upgrade --dryRun # NoPU
#runTheMatrix.py -w upgrade -l 29234.21 --dryRun #200PU for 11_0_0_preN (N is low version 1 ,2 ..)
#runTheMatrix.py -l 20634.21 -w upgrade --dryRun    # 200PU for 11_0_0_preN(N is high version)
```
You can check list of all updateded work flow using following commands:
```bash
runTheMatrix.py -w upgrade -n
```

### 3. Modify cmdlog file and run cmsDriver

After "dryrun", cmdLog file will be created.
You can modify or add options.
-n 100: Number of events:100
-- nThreads 8: Number of threads 8
--customise=Validation/Performance/TimeMemoryInfo.py: This add functions about Time Memory info to your python config file. I add this options in step3(RECO)

This options about pileup
--pileup_input das:/RelValMinBias_14TeV/CMSSW_10_6_0_patch2-106X_upgrade2023_realistic_v3_2023D41noPU-v1/GEN-SIM
--pileup AVE_200_BX_25ns # Average number of pileup:200

### 4. Monitoring CPU tims and Memory using "Igprof"
In N01_profile directory, try n01_profile.sh and n02_profile.sh


### 5. Analysis using step3 config file output
To do this, you need to add "--customise=Validation/Performance/TimeMemoryInfo.py: This add functions about Time Memory info to your python config file" options in cmdLog

You can analyze the results using step3.log files
In N02_compare_summary directory,
N02_getTimeMemSummary.sh, N03_timeDiffFromReport.sh, N05_makehist.py

You can analyze the results using step3.root files
N04_compareProducts.sh

