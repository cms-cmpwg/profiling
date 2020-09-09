#!/bin/bash

### --This code makes summarry of Max RSS VSIZE CPUtime ....
## step3.log (or step4.log) is needed  



## -- step3 AOD
path_="$1"

## -- step4 MINIAOD
#path_="../$1/src/TimeMemory/logs/step4.log"



## --------------------- mode1 makes summary mode2 makes input if N05_makehist.py

## mode1
grep "^MemoryCheck\|^TimeEvent>" $path_  | awk -f getTimeMemSummary.awk


## mode2 -- For make hist
#grep "^MemoryCheck\|^TimeEvent>" $path_  > SUM_$1\.txt
#grep "^MemoryCheck\|^TimeEvent>" $path_  
#grep "^MemoryCheck\|^TimeEvent>" $path_  > PAT_SUM_$1\.txt
