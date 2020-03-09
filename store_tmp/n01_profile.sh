#!/bin/bash                                                                                                                                 

#if [ -f step3*.py ];then
#
#	step3py = eval `ls step3*.py`
#	igprof -d -pp -z -o igprofCPU_step3.gz -t cmsRun cmsRun $step3py >& step3IgprofCPU.log &
#	igprof -d -mp -o igprofMEM_step3.mp -D 1000evts cmsRun $step3py >& step3IgprofMEM.log &
#
#else
#	echo "Error: There is no config file"
#fi


## Start monitoring CPU TIME and MEM
igprof -d -pp -z -o igprofCPU_step3.gz -t cmsRun cmsRun step3_RAW2DIGI_L1Reco_RECO_RECOSIM_PU.py >& step3IgprofCPU.log 
igprof -d -mp -o igprofMEM_step3.mp -D 100evts cmsRun step3_RAW2DIGI_L1Reco_RECO_RECOSIM_PU.py >& step3IgprofMEM.log 




