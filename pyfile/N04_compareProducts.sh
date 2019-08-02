#!/bin/bash

## This code analyzing branch size of step3 output root files
## The CMSSW enviroment is needed


old="$1/src/TimeMemory/step3.root"
new="$2/src/TimeMemory/step3.root"



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

echo "Checking process ${procF} ${fA} and ${fB} (if above ${absMin} or ${dptMin}%):"
ds=`date -u +%s.%N`
os=os.${ds}
edmEventSize -v ${fA} > ${os}

ns=ns.${ds}
edmEventSize -v ${fB} > ${ns}

grep ${procF} ${os} ${ns} | sed -e "s/${os}:/os /g;s/${ns}:/ns /g" 
#grep ${procF} ${os} ${ns} | sed -e "s/${os}:/os /g;s/${ns}:/ns /g" | absMin=${absMin} dptMin=${dptMin} awk -f compareProducts.awk

rm ${os} ${ns}
