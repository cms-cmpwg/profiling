#!/bin/bash

## This code analyzing branch size of step3 output root files
## The CMSSW enviroment is needed

old="../$1/src/TimeMemory/step4.root"
new="../$2/src/TimeMemory/step4.root"
isPAT=1

#old="../$1/src/TimeMemory/step3.root"
#new="../$2/src/TimeMemory/step3.root"
#isPAT=0



fA=`echo $old`
if [ ! -f "${fA}" ]; then
    echo ${fA} does not exist
    exit 17
fi
fB=`echo $new`
if [ ! -f "${fB}" ]; then
    echo ${fB} does not exist
    exit 17
fi

procF=$3
if [ "x${procF}" == "x" ]; then
    procF="_RECO"
fi



absMin=$4
if [ "x${absMin}" == "x" ]; then
    absMin=100
fi
dptMin=$5
if [ "x${dptMin}" == "x" ]; then
    dptMin=20
fi

if [ $isPAT = 0 ]; then
	echo "Checking process ${procF} ${fA} and ${fB} (if above ${absMin} or ${dptMin}%):"
else
	echo "Checking process _PAT  ${fA} and ${fB}:"
fi


ds=`date -u +%s.%N`
os=os.${ds}
edmEventSize -v ${fA} > ${os}

ns=ns.${ds}
edmEventSize -v ${fB} > ${ns}

grep "_RECO\|_PAT" ${os} ${ns} | sed -e "s/${os}:/os /g;s/${ns}:/ns /g" | absMin=${absMin} dptMin=${dptMin} awk -f compareProducts.awk > temp.csv
python compareProd.py 

rm ${os} ${ns}
rm temp.csv




