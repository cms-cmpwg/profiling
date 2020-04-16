#!/bin/bash
workdir=/home/users/gartung
eoswwwdir=/eos/usr/g/gartung/www
last-nightly=$(cat ${workdir}/last-nightly)
latest-nightly=$(scram list CMSSW_1 | grep CMSSW_ | sort | tail -1 | awk '{print $2}')
if [[ "${last-nightly}" != "${latest-nightly}" ]];then
     cd ${workdir}
     ${workdir}/ServiceWork/Gen_tool/Gen.sh ${latest-nightly}
fi
echo ${latest-nightly} > ${workdir}/last-nightly
mkdir -p ${eoswwwdir}/results/${latest-nightly}
cp -pv ${workdir}/${latest-nightly}/relval/TimeMemory/*.res ${eoswwwdir}/results/${latest-nightly}
cp -pv ${workdir}/${latest-nightly}/relval/TimeMemory/*.sql3 ${eoswwwdir}/cgi-bin/data
