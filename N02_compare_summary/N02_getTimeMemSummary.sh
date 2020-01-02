#!/bin/bash

### --This code makes summarry of Max RSS VSIZE CPUtime ....
## Step3.log is needed  

#path_="../$1/src/TimeMemory/logs/step3_AOD.log"
#path_="../$1/src/TimeMemory/logs/step3.log"


path_="../$1/src/TimeMemory/logs/step3.log"

#path_="../$1/src/TimeMemory/logs/step4.log"


## mode1
#grep "^MemoryCheck\|^TimeEvent>" $path_  | awk -f getTimeMemSummary.awk


## mode2 -- For make hist
#grep "^MemoryCheck\|^TimeEvent>" $path_  > SUM_$1\.txt
grep "^MemoryCheck\|^TimeEvent>" $path_  
#grep "^MemoryCheck\|^TimeEvent>" $path_  > PAT_SUM_$1\.txt
