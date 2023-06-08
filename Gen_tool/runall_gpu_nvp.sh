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
  export PROFILING_WORKFLOW="23834.21"
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

if [ -d /cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin ];then
    PATH=$PATH:/cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin
else
   if [ -d /opt/nvidia/nsight-systems/bin ]; then
    PATH=$PATH:/opt/nvidia/nsight-systems/bin
   fi
fi

  echo Run with Nsight Systems Profiler
  if [ "X$RUNALLSTEPS" != "X" ]; then
    if [ -f step1_gpu_nvprof.py ];then
        echo step1 gpu Nsight Systems Profiler
        nsys profile --output=step1_gpu_nsys --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi --show-output=true cmsRun step1_gpu_nvprof.py -j step1_gpu_nsys_JobReport.xml >& step1_gpu_nsys.log
        nsys stats -f csv --report gpukernsum,gpumemtimesum,gpumemsizesum step1_gpu_nsys.nsys-rep > step1_gpu_nsys.txt
    else
        echo missing step1_gpu_nvprof.py
    fi

    if [ -f step2_gpu_nvprof.py ];then
        echo step2 gpu Nsight Systems Profiler
        nsys profile --output=step2_gpu_nsys --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi --show-output=true cmsRun step2_gpu_nvprof.py -j step2_gpu_nsys_JobReport.xml >& step2_gpu_nsys.log
        nsys stats -f csv --report gpukernsum,gpumemtimesum,gpumemsizesum step2_gpu_nsys.nsys-rep > step2_gpu_nsys.txt
    else
        echo missing step2_gpu_nvprof.py
    fi
  fi
  if [ -f step3_gpu_nvprof.py ];then
      echo step3 gpu Nsight Systems Profiler
      nsys profile --output=step3_gpu_nsys --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi --show-output=true cmsRun step3_gpu_nvprof.py  -j step3_gpu_nsys_JobReport.xml >& step3_gpu_nsys.log
      nsys stats -f csv --report gpukernsum,gpumemtimesum,gpumemsizesum step3_gpu_nsys.nsys-rep > step3_gpu_nsys.txt
  else
      echo missing step3_gpu_nvprof.py
  fi

  if [ -f step4_gpu_nvprof.py ];then
      echo step4 gpu Nsight Systems Profiler
      nsys profile --output=step4_gpu_nsys --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi --show-output=true cmsRun step4_gpu_nvprof.py -j step4_gpu_nsys_JobReport.xml >& step4_gpu_nsys.log
      nsys stats -f csv --report gpukernsum,gpumemtimesum,gpumemsizesum step4_gpu_nsys.nsys-rep > step4_gpu_nsys.txt
  else
      echo missing step4_gpu_nvprof.py
  fi

  if [ -f step5_gpu_nvprof.py ]; then
      echo step5 gpu Nsight Systems Profiler
      nsys profile --output=step5_gpu_nsys --export=sqlite --stats=true --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi --show-output=true cmsRun step5_gpu_nvprof.py -j step5_gpu_nsys_JobReport.xml >& step5_gpu_nsys.log
      nsys stats -f csv --report gpukernsum,gpumemtimesum,gpumemsizesum step5_gpu_nsys.nsys-rep > step5_gpu_nsys.txt
  else
      echo no step5 in workflow
  fi
