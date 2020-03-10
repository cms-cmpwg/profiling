#!/bin/bash



#!/bin/bash


# Single shot

ol='CMSSW11_1_0_pre1'
ne='CMSSW11_1_0_pre2'

python N01_compare_cpu.py $ol $ne > cl_compare_cpu_11_1_0Pre1vsPre2.txt
python N01_compare_cpu.py $ol\PAT $ne\PAT > cl_PAT_compare_cpu_11_1_0Pre1vsPre2.txt




## 1 to 13
#for i in `seq 1 12`
#do
#    idx=`expr $i + 1`
#    for j in `seq $idx 13`
#    do
#		echo "Start $i $j"
#		echo CMSSW11_0_0_pre$i\ PAT CMSSW11_0_0_pre$j\PAT
#        python N01_compare_cpu.py CMSSW11_0_0_pre$i CMSSW11_0_0_pre$j > compare_results/cl_compare_cpu_11_0_0Pre$i\vsPre$j\.txt
#		python N01_compare_cpu.py CMSSW11_0_0_pre$i\PAT CMSSW11_0_0_pre$j\PAT > compare_results/cl_PAT_compare_cpu_11_0_0Pre$i\vsPre$j\.txt
#    done
#done
#
#
## for 11_1_0
#for i in `seq 1 13`
#do
#
#	echo "START pre$i vs 11_0_0"
#	python N01_compare_cpu.py CMSSW11_0_0_pre$i CMSSW11_0_0 > compare_results/cl_compare_cpu_11_0_0Pre$i\vs11_0_0.txt
#	python N01_compare_cpu.py CMSSW11_0_0_pre$i\PAT CMSSW11_0_0PAT > compare_results/cl_PAT_compare_cpu_11_0_0Pre$i\vs11_0_0.txt
#done



