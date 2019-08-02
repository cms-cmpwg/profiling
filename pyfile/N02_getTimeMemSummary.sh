#!/bin/bash

### --This code makes summarry of Max RSS VSIZE CPUtime ....
## Args ex: CMSSW_10_6_10
## Step3.log is needed  


path_="$1/src/TimeMemory/step3.log"

## mode1
grep "^MemoryCheck\|^TimeEvent>" $path_  | awk -f /afs/cern.ch/user/j/jiwoong/private/10_6_0/getTimeMemSummary.awk



## mode2 -- For make hist
#grep "^MemoryCheck\|^TimeEvent>" $path_  
