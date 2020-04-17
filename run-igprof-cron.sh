#!/bin/bash
source /cvmfs/cms.cern.ch/cmsset_default.sh
WORKDIR=/home/users/gartung
EOSWWWDIR=/eos/user/g/gartung/www
LASTNIGHTLY=`cat ${WORKDIR}/last-nightly`
echo $LASTNIGHTLY
LATESTNIGHTLY=`scram list CMSSW_1 | grep CMSSW_ | sort | tail -1 | awk '{print $2}'`
echo $LATESTNIGHTLY
if [[ "${LASTNIGHTLY}" != "${LATESTNIGHTLY}" ]];then
     cd ${WORKDIR}
     ${WORKDIR}/ServiceWork/Gen_tool/Gen.sh ${LATESTNIGHTLY}
     ${WORKDIR}/ServiceWork/Gen_tool/runall_mem.sh ${LATESTNIGHTLY}
     ${WORKDIR}/ServiceWork/Gen_tool/runall_cpu.sh ${LATESTNIGHTLY}
     cd ${WORKDIR}/${LATESTNIGHTLY}/src/TimeMemory
     ./profile.sh
     cd ${WORKDIR}
     echo ${LATESTNIGHTLY} > ${WORKDIR}/last-nightly
     mkdir -p ${EOSWWWDIR}/results/${LATESTNIGHTLY}
     cp -pv ${WORKDIR}/${LATESTNIGHTLY}/src/TimeMemory/*.res ${EOSWWWDIR}/results/${LATESTNIGHTLY}
     cp -pv ${WORKDIR}/${LATESTNIGHTLY}/src/TimeMemory/*.sql3 ${EOSWWWDIR}/cgi-bin/data
     rm -fv *.root
fi
