#!/bin/bash



### --Read html

curl -s https://ycyang.web.cern.ch/ycyang/cgi-bin/igprof-navigator/CMSSW_8_1_0_pre3_igprofCPU > new.html
curl -s https://ycyang.web.cern.ch/ycyang/cgi-bin/igprof-navigator/CMSSW_8_1_0_pre2_igprofCPU > old.html


html2text  new.html --body-width=10000 | sed -e "s/&amp;/\&/g" > new.txt
html2text  old.html --body-width=10000 | sed -e "s/&amp;/\&/g" > old.txt




### --Step 1 start ####

## 1.  <spontaneous>의 cmulative 값 
sponValueOld=`grep "spontaneous" old.txt | awk '{print $3}'`
sponValueNew=`grep "spontaneous" new.txt | awk '{print $3}'`
sponValueOld=${sponValueOld//,/}
sponValueNew=${sponValueNew//,/}



## 2. str 각각의Total% 값
strs="
edm::WorkerT&lt;edm::EDProducer&gt;::implDo(
edm::WorkerT&lt;edm::stream::EDProducerAdaptorBase&gt;::implDo(
edm::WorkerT&lt;edm::one::OutputModuleBase&gt;::implDo(
"

result1="compare1_${oldCMSSW}_${newCMSSW}.txt"
rm -rf $result1
for str in $strs
do
    valueOld=`grep $str old.txt | head -n 1 | awk '{print $2}'`
    valueNew=`grep $str new.txt | head -n 1 | awk '{print $2}'`
    if [ "$valueOld" == "" ]; then valueOld=Non; fi
    if [ "$valueNew" == "" ]; then valueNew=Non; fi
    echo "$valueOld ---> $valueNew $str" >> $result1
done
mv $result1 ${result1}.temp
column -t ${result1}.temp > $result1
rm -rf ${result1}.temp
cat $result1

echo "Done step1"



### --Step 1 start ####



