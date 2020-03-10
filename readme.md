## RECO monitoring and integration  
 - ### Website: http://jiwoong.web.cern.ch/jiwoong/  
---

### 1. Generate events  
 -  **Gen_tool/Gen.sh** can setup working-directory: CMSSW_X_X_X
```bash
$ ./Gen.sh CMSSW_X_X_X
```      
 -  The directory includes **cmdLog**, **profile.sh**, read.py(not used)  
 -  You can generate events of all datatier using **cmdLog** files  

#### **1.1 About cmdLog file**  
 -  This is the sample of **cmdLog** file: http://jiwoong.web.cern.ch/jiwoong/results/phase2/cmdlog_CMSSW_11_1_0_pre3  
 - 100 events are generated  
 - I use multi threading only in step1 and step2 to save time  
 - **--customise=Validation/Performance/TimeMemoryInfo.py** option can make time and memory information in logfiles ( step3.log, step4.log )
 - step3.log and step4.log are also used in analysis  

### 2. Igprof  
 - **Gen_tool/runall_cpu.sh** can monitoring **cpu usage** and make **igprofCPU_stepN.gz** output  
 - **Gen_tool/runall_mem.sh** can monitoring **memory usage** and make **igprofMEM_stepN.mp** output  
 - **Your_CMSSW_Working_Dir/profile.sh** read **igprofCPU_stepN.gz** and **igprofMEM_stepN.mp**, then make reports ( **.sql3** and **.res** outputs )  
 - **.sql3 file** is used in **web-based** reports (ex https://jiwoong.web.cern.ch/jiwoong/cgi-bin/igprof-navigator/igprofCPU_CMSSW11_1_0_pre2 )  
 - **.res file** is used in **Ascii-based** report (ex https://jiwoong.web.cern.ch/jiwoong/results/phase2/RES_MEM_CMSSW_11_1_0_pre2.res )  

### 3. Analysis  
 - Go to **Analyze_tool** directory

 

