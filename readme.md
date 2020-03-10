## RECO monitoring and integration  
 - ### Website: http://jiwoong.web.cern.ch/jiwoong/  
---

### 1. Generate events  
 -  **Gen_tool** directory  
 -  **Gen.sh** can setup working-directory: CMSSW_X_X_X
```bash
$ ./Gen.sh CMSSW_X_X_X
```      
 -  The directory includes **cmdLog**, **profile.sh**, read.py(not used)  
 -  You can generate events of all datatier using **cmdLog** files  

#### 1.1 About cmdLog file  
 -  This is the sample of **cmdLog** file: http://jiwoong.web.cern.ch/jiwoong/results/phase2/cmdlog_CMSSW_11_1_0_pre3  
 - 100 events are generated  
 - I used multi threading only in step1 and step2 to save time  
 - I run step3 and step4 **without igprof** first  
 - The outputs of step3 and step4 ( step3.log and step4.log ) are also used in analysis  

### 2. Igprof  
 

