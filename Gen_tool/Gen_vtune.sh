#!/bin/bash -x
# ARCHITECTURE, RELEASE_FORMAT and PROFILING_WORKFLOW are defined in Jenkins job
# voms-proxy-init is run in Jenkins Singularity wrapper script.

## --1. Install CMSSW version and setup environment
if [ "X$CMSSW_VERSION" == "X" ];then
  CMSSW_v=$1
else
  CMSSW_v=$CMSSW_VERSION
fi
echo $CMSSW_v

if [ "X$ARCHITECTURE" != "X" ];then
  export SCRAM_ARCH=$ARCHITECTURE
else
  export SCRAM_ARCH=slc7_amd64_gcc10
fi
echo $SCRAM_ARCH

if [ "X$RELEASE_FORMAT" == "X" -a  "X$CMSSW_IB" == "X" ]; then
  export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
  source $VO_CMS_SW_DIR/cmsset_default.sh
  source /cvmfs/grid.cern.ch/etc/profile.d/setup-cvmfs-ui.sh
  grid-proxy-init
  unset PYTHONPATH
  export LC_ALL=C
  echo "Start install ${CMSSW_v} ..."
  scramv1 project ${CMSSW_v}
  echo "Install success"
  echo "Set CMSSW environment ...'"
  cd ${CMSSW_v}
  eval `scramv1 runtime -sh`
else
  cd $WORKSPACE/${CMSSW_v}
fi

## --2. "RunThematrix" dry run

if [ "X$PROFILING_WORKFLOW" == "X" ];then
  export PROFILING_WORKFLOW="35234.21"
fi
if [ "X$EVENTS" == "X" ];then
  export EVENTS=20
fi

if [ "X$NTHREADS" == "X" ]; then
  export NTHREADS=1
fi

(runTheMatrix.py -n | grep "^$PROFILING_WORKFLOW " 2>/dev/null) || WHAT='-w upgrade'

declare -a outname
if [ "X$WORKSPACE" != "X" ];then
#running on Jenkins WORKSPACE is defined and we want to generate and run the config files
  runTheMatrix.py $WHAT -l $PROFILING_WORKFLOW --command=--number=$EVENTS\ --nThreads=$NTHREADS\ --no_exec\ --dirin=$WORKSPACE\ --dirout=$WORKSPACE  #200PU for 11_2_X
  outname=$(ls -d ${PROFILING_WORKFLOW}*)
  mv $outname $PROFILING_WORKFLOW
  cd $PROFILING_WORKFLOW
else
  NCPU=$(cat /proc/cpuinfo | grep processor| wc -l)
  NTHREADS=$((NCPU/2))
  EVENTS=$((NTHREADS*20))
  runTheMatrix.py $WHAT -l $PROFILING_WORKFLOW --ibeos --command=--number=$EVENTS\ --nThreads=$NTHREADS\ --no_exec #200PU for 11_2_X
  outname=$(ls -d ${PROFILING_WORKFLOW}_*)
  mv $outname $PROFILING_WORKFLOW
  cd $PROFILING_WORKFLOW
fi

cat << EOF >> vtune.sh
#!/bin/bash
. /cvmfs/projects.cern.ch/intelsw/oneAPI/linux/x86_64/2022/vtune/latest/vtune-vars.sh
CMSRUN=`which cmsRun`
VTUNE=`which vtune`
\$VTUNE -collect hotspots -data-limit=0 -knob enable-stack-collection=true -knob stack-size=4096 -- \$CMSRUN \$(ls TTbar*.py) >step1.log
\$VTUNE -collect hotspots -data-limit=0 -knob enable-stack-collection=true -knob stack-size=4096 -- \$CMSRUN \$(ls step2*.py) >step2.log
\$VTUNE -collect hotspots -data-limit=0 -knob enable-stack-collection=true -knob stack-size=4096 -- \$CMSRUN \$(ls step3*.py) >step3.log
\$VTUNE -collect hotspots -data-limit=0 -knob enable-stack-collection=true -knob stack-size=4096 -- \$CMSRUN \$(ls step4*.py) >step4.log
\$VTUNE -report gprof-cc -r r000hs -format=csv -csv-delimiter=semicolon >r000hs.gprof_cc.csv
\$VTUNE -report gprof-cc -r r001hs -format=csv -csv-delimiter=semicolon >r001hs.gprof_cc.csv
\$VTUNE -report gprof-cc -r r002hs -format=csv -csv-delimiter=semicolon >r002hs.gprof_cc.csv
\$VTUNE -report gprof-cc -r r003hs -format=csv -csv-delimiter=semicolon >r003hs.gprof_cc.csv
EOF

# execute the workflows under vtune to gather the profiling data
chmod +x vtune.sh
cat ./vtune.sh
echo  Run ./vtune.sh to generate profiling data
echo  optionally start the vtune-backend server to make the reports web accessible with this command
echo  cd path to TimeMemory
echo  vtune-backend --web-port 9090 --data-directory $PWD
echo
echo  the console will display the url with a one time password
echo  https://localhost:9090?pw=############
echo  you will be prompted to enter a new password when you connect.
echo  the is saved in a session cookie
echo  the connection is self signed you will get a warnings from your browser
echo  you will have to make a ssh tunnel for port 9090 to 127.0.0.1:9900
