#!/bin/bash



#!/bin/bash



# tur on off step3 or step4 manually in source code


cd /x5/cms/jwkim/ServiceWork/tmp/Analysis



for i in `seq 1 12`
do
    idx=`expr $i + 1`
    for j in `seq $idx 13`
    do
		echo "Start $i $j"
		./N04_compareProducts.sh CMSSW_11_0_0_pre$i CMSSW_11_0_0_pre$j > compare_products/prod_compare_cpu_11_0_0Pre$i\vsPre$j\.txt
        #./N04_compareProducts.sh CMSSW_11_0_0_pre$i CMSSW_11_0_0_pre$j > compare_products/prod_PAT_compare_cpu_11_0_0Pre$i\vsPre$j\.txt
    done
done




for i in `seq 1 13`
do

	echo "Start pre$i vs 11_0_0"
	./N04_compareProducts.sh CMSSW_11_0_0_pre$i CMSSW_11_0_0 > compare_products/prod_compare_cpu_11_0_0Pre$i\vs11_0_0.txt
    #./N04_compareProducts.sh CMSSW_11_0_0_pre$i CMSSW_11_0_0 > compare_products/prod_PAT_compare_cpu_11_0_0Pre$i\vs11_0_0.txt
done







