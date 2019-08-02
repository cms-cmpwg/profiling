#!/bin/bash

igprof -d -pp -z -o igprofCPU_step3.gz -t cmsRun cmsRun step3_RAW2DIGI_L1Reco_RECO_RECOSIM.py >& step3IgprofCPU.log &
igprof -d -mp -o igprofMEM_step3.mp -D 10evts cmsRun step3_RAW2DIGI_L1Reco_RECO_RECOSIM.py >& step3IgprofMEM.log &

