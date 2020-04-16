#!/bin/bash
workdir=/home/users/gartung
eoswwwdir=/eos/usr/g/gartung/www
last-nightly=$(cat ${workdir}/last-nightly)
latest-nightly=$(scram list CMSSW_1 | grep CMSSW_ | sort | tail -1 | awk '{print $2}')
if [[ "${last-nightly}" != "${latest-nightly}" ]];then
     cd ${workdir}
     ${workdir}/ServiceWork/Gen_tool/Gen.sh ${latest-nightly}
     ${workdir}/ServiceWork/Gen_tool/runall_mem.sh ${latest-nightly}
     ${workdir}/ServiceWork/Gen_tool/runall_cpu.sh ${latest-nightly}
     cd ${workdir}/${latest-nightly}/src/TimeMemory
     ./profile.sh
     cd ${workdir}
fi
echo ${latest-nightly} > ${workdir}/last-nightly
mkdir -p ${eoswwwdir}/results/${latest-nightly}
cp -pv ${workdir}/${latest-nightly}/src/TimeMemory/*.res ${eoswwwdir}/results/${latest-nightly}
cp -pv ${workdir}/${latest-nightly}/src/TimeMemory/*.sql3 ${eoswwwdir}/cgi-bin/data
