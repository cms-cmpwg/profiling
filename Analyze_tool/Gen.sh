#!/bin/bash

CMSSW_v=$1

## --1. Install CMSSW version and setup environment
#echo "Your SCRAM_ARCH "
#export SCRAM_ARCH=slc7_amd64_gcc900
#export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
#echo "$VO_CMS_SW_DIR $SCRAM_ARCH"
#source $VO_CMS_SW_DIR/cmsset_default.sh

#echo "Start install $CMSSW_v ..."
#scramv1 project $CMSSW_v
#echo "Install success"
#echo "Set CMSSW environment and compiling..'"
cd $CMSSW_v/src
#eval `scramv1 runtime -sh`
#scram b -j 6


## --2. "RunThematrix" dry run


#runTheMatrix.py -l 29034.21 -w upgrade --dryRun # NoPU

#runTheMatrix.py -l 20634.21 -w upgrade --dryRun	# 200PU for 4 5 6 
#runTheMatrix.py -w upgrade -l 29234.21 --dryRun #200PU for 11_0_0_pre1 2 3 


#tail *.log

#for i in $(ls -d */); do 
#outname=${i%%/}; done
#mv $outname TimeMemory
cd TimeMemory


## -- Not yet ---------
# --3. Make cmdLog run_option  -- Set N events
#cat << EOF >> read.py
#import subprocess
#
#with open('cmdLog','r') as f:
#	cnt=0
#	for line in f:
#		line=line.rstrip()
#		if line.startswith(' cmsDriver'):
#			cnt+=1
### --Set N events
#            #line=line.replace("-n 10","-n 1000")
#			if cnt==3:
#				line_list = line.split()
#				logfile = line_list[-2]
#				line_list.insert(-7,"--customise=Validation/Performance/TimeMemoryInfo.py")
#				line=' '.join(line_list)
#				line=line.replace(logfile,"step3.log")
### --Do not run step4
#			if cnt==4: break
### --Excute cmsDriver
#            #subprocess.check_output (line,shell=True)
#			print(line)
#			print(" ")
#EOF
# run cmsDriver.py
#python read.py
# ---------------------------------------

## --4. Make profiler 




cat << EOF >> analyze.sh
#!/bin/bash


## --For web-based report

## -step1
   igprof-analyse --sqlite -v -d -g -r MEM_LIVE igprofMEM_step1.mp |sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprof_MEM_GENSIM_${1}.sql3 
   igprof-analyse --sqlite -v -d -g igprofCPU_step1.gz | sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprof_CPU_GENSIM_${1}.sql3 

## -step2
   igprof-analyse --sqlite -v -d -g -r MEM_LIVE igprofMEM_step2.mp |sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprof_MEM_DIGIRAW_${1}.sql3 
   igprof-analyse --sqlite -v -d -g igprofCPU_step2.gz | sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprof_CPU_DIGIRAW_${1}.sql3

## -step3
   igprof-analyse --sqlite -v -d -g -r MEM_LIVE igprofMEM_step3.mp |sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprof_MEM_RECO_${1}.sql3
   igprof-analyse --sqlite -v -d -g igprofCPU_step3.gz | sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprof_CPU_RECO_${1}.sql3

## -step4
    igprof-analyse --sqlite -v -d -g -r MEM_LIVE igprofMEM_step4.mp |sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprof_MEM_PAT_${1}.sql3
    igprof-analyse --sqlite -v -d -g igprofCPU_step4.gz | sed -e 's/INSERT INTO files VALUES (\([^,]*\), \"[^$]*/INSERT INTO files VALUES (\1, \"ABCD\");/g' | sqlite3 igprof_CPU_PAT_${1}.sql3


## --For ascii-based report
## -step1
   igprof-analyse  -v -d -g -r MEM_LIVE igprofMEM_step1.mp >& RES_GENSIM_MEM_${1}.res
   igprof-analyse  -v -d -g igprofCPU_step1.gz >& RES_GENSIM_CPU_${1}.res

## -step2
   igprof-analyse  -v -d -g -r MEM_LIVE igprofMEM_step2.mp >& RES_DIGIRAW_MEM_${1}.res
   igprof-analyse  -v -d -g igprofCPU_step2.gz >& RES_DIGIRAW._CPU_${1}.res

## -step3
   igprof-analyse  -v -d -g -r MEM_LIVE igprofMEM_step3.mp >& RES_RECO_MEM_${1}.res
   igprof-analyse  -v -d -g igprofCPU_step3.gz >& RES_RECO_CPU_${1}.res

## -step4
    igprof-analyse  -v -d -g -r MEM_LIVE igprofMEM_step4.mp >& RES_PAT_MEM_${1}.res
    igprof-analyse  -v -d -g igprofCPU_step4.gz >& RES_PAT_CPU_${1}.res

EOF

chmod +x analyze.sh

#mkdir igprofs
#mkdir logs

#cat << EOF >> sendtoCERN.sh
#scp cmdLog  jiwoong@lxplus.cern.ch:/eos/user/j/jiwoong/www/results/phase2/cmdlog_$1
#scp igprofs/*.res jiwoong@lxplus.cern.ch:/eos/user/j/jiwoong/www/results/phase2
#scp igprofs/*.sql3 jiwoong@lxplus.cern.ch:/eos/user/j/jiwoong/www/cgi-bin/data
#EOF

