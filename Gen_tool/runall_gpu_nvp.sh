#!/bin/bash
if [ "X$CMSSW_VERSION" == "X" ];then
  CMSSW_v=$1
else
  CMSSW_v=$CMSSW_VERSION
fi


if [ "X$ARCHITECTURE" != "X" ]; then
  export SCRAM_ARCH=$ARCHITECTURE
fi

if [ "X$PROFILING_WORKFLOW" == "X" ];then
  export PROFILING_WORKFLOW="21034.508"
fi


if [ "X$WORKSPACE" != "X" ]; then
  cd $WORKSPACE/$CMSSW_v/$PROFILING_WORKFLOW
else
  export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
  echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
  source $VO_CMS_SW_DIR/cmsset_default.sh
  cd $CMSSW_v/$PROFILING_WORKFLOW
  export LC_ALL=C
  eval `scram runtime -sh`
  if [ ! -f $LOCALRT/ibeos_cache.txt ];then
      curl -L -s $LOCALRT/ibeos_cache.txt https://raw.githubusercontent.com/cms-sw/cms-sw.github.io/master/das_queries/ibeos.txt
  fi
  if [ -d $CMSSW_RELEASE_BASE/src/Utilities/General/ibeos ];then
    PATH=$CMSSW_RELEASE_BASE/src/Utilities/General/ibeos:$PATH
    CMS_PATH=/cvmfs/cms-ib.cern.ch
    CMSSW_USE_IBEOS=true
  fi
  if [ -d $CMSSW_BASE/src/Utilities/General/ibeos ];then
    PATH=$CMSSW_BASE/src/Utilities/General/ibeos:$PATH
    CMS_PATH=/cvmfs/cms-ib.cern.ch
    CMSSW_USE_IBEOS=true
  fi
fi

if [ "X$TIMEOUT" == "X" ];then
    export TIMEOUT=18000
fi

#NSYS=/cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin/nsys
#NSYSARGS="profile --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi"

  echo Run with NVProflierService
  if [ "X$RUNALLSTEPS" != "X" ]; then
    if [ -f step1_gpu_nvprof.py ];then
        echo step1 gpu NVProfiler
        #timeout $TIMEOUT nvprof -o step1_gpu.%p.nvprof -s cmsRun step1_gpu_nvprof.py -j step1_gpu_nvprof_JobReport.xml >& step1_gpu_nvprof.txt
        /cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin/nsys profile --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi cmsRun step1_gpu_nvprof.py -j step1_gpu_nvprof_JobReport.xml >& step1_gpu_nvprof.txt
    else
        echo missing step1_gpu_nvprof.py
    fi

    if [ -f step2_gpu_nvprof.py ];then
        echo step2 gpu NVProfiler
        #timeout $TIMEOUT nvprof -o step2_gpu.%p.nvprof -s cmsRun step2_gpu_nvprof.py -j step2_gpu_nvprof_JobReport.xml >& step2_gpu_nvprof.txt
        /cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin/nsys profile --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi cmsRun step2_gpu_nvprof.py -j step2_gpu_nvprof_JobReport.xml >& step2_gpu_nvprof.txt
    else
        echo missing step2_gpu_nvprof.py
    fi
  fi
  if [ -f step3_gpu_nvprof.py ];then
      echo step3 gpu NVProfiler
      #timeout $TIMEOUT nvprof -o step3_gpu.%p.nvprof -s cmsRun step3_gpu_nvprof.py  -j step3_gpu_nvprof_JobReport.xml >& step3_gpu_nvprof.txt
      /cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin/nsys profile --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi cmsRun step3_gpu_nvprof.py  -j step3_gpu_nvprof_JobReport.xml >& step3_gpu_nvprof.txt
  else
      echo missing step3_gpu_nvprof.py
  fi

  if [ -f step4_gpu_nvprof.py ];then
      echo step4 gpu NVProfiler
      #timeout $TIMEOUT nvprof -o step4_gpu.%p.nvprof -s cmsRun step4_gpu_nvprof.py -j step4_gpu_nvprof_JobReport.xml >& step4_gpu_nvprof.txt
      /cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin/nsys profile --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi cmsRun step4_gpu_nvprof.py -j step4_gpu_nvprof_JobReport.xml >& step4_gpu_nvprof.txt 
  else
      echo missing step4_gpu_nvprof.py
  fi

  if [ -f step5_gpu_nvprof.py ]; then
      echo step5 gpu NVProfiler
      #timeout $TIMEOUT nvprof -o step5_gpu.%p.nvprof -s cmsRun step5_gpu_nvprof.py -j step5_gpu_nvprof_JobReport.xml >& step5_gpu_nvprof.txt
      /cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin/nsys profile --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi cmsRun step5_gpu_nvprof.py -j step5_gpu_nvprof_JobReport.xml >& step5_gpu_nvprof.txt
  else
      echo no step5 in workflow
  fi
