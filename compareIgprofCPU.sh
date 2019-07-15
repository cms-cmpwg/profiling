#!/bin/bash

web="http://155.230.186.130"

function single() {
if [ ! -d igprofCompare ]; then mkdir igprofCompare; fi

step=step3
type=CPU
oldCMSSW=$1
newCMSSW=$2

nevOld=1000.0
nevNew=1000.0

curl -s ${web}/~ycyang/cgi-bin/igprof-navigator/${oldCMSSW}_igprofCPU > old.html 
curl -s ${web}/~ycyang/cgi-bin/igprof-navigator/${newCMSSW}_igprofCPU > new.html 

html2text -width 10000 old.html | sed -e "s/&amp;/\&/g" > old.txt
html2text -width 10000 new.html | sed -e "s/&amp;/\&/g" > new.txt


## 1.  <spontaneous>의 cmulative 값 
sponValueOld=`grep "<spontaneous>" old.txt | awk '{print $3}'`
sponValueNew=`grep "<spontaneous>" new.txt | awk '{print $3}'`
sponValueOld=${sponValueOld//,/}
sponValueNew=${sponValueNew//,/}

## 2. str 각각의Total% 값
strs="
edm::WorkerT<edm::EDProducer>::implDo(
edm::WorkerT<edm::stream::EDProducerAdaptorBase>::implDo(
edm::WorkerT<edm::one::OutputModuleBase>::implDo(
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

##############################################################################
echo "Done step1"
##############################################################################

## 3. 링크를 클릭해 들어간다
string2="edm::stream::EDProducerAdaptorBase::doEvent("
oldLink=`grep $string2 old.html | head -n 1 | sed -e 's/\(^.*href="\)\(.*\)\(">.*$\)/\2/'`
newLink=`grep $string2 new.html | head -n 1 | sed -e 's/\(^.*href="\)\(.*\)\(">.*$\)/\2/'`

echo "OldLink: $oldLink"
echo "NewLink: $newLink"
curl -s $web/$oldLink > old2.html
curl -s $web/$newLink > new2.html
html2text -width 10000 old2.html | sed -e "s/&amp;/\&/g" > old.txt
html2text -width 10000 new2.html | sed -e "s/&amp;/\&/g" > new.txt

## 3-1 전체 라인 수
allLineOld=`cat old.txt | wc -l`
allLineNew=`cat new.txt | wc -l`

## 3-2 해당 글귀가 포함된 라인이 전체에서 몇번 째 인지
firstLineOld=`grep -n $string2 old.txt | cut -f1 -d:`
firstLineNew=`grep -n $string2 new.txt | cut -f1 -d:`


head -n `expr $allLineOld - 1` old.txt | tail -n `expr $allLineOld - $firstLineOld - 1` > old1.txt
head -n `expr $allLineNew - 1` new.txt | tail -n `expr $allLineNew - $firstLineNew - 1` > new1.txt

cat -n old1.txt > old2.txt
cat -n new1.txt > new2.txt

result2="compare2_${oldCMSSW}_${newCMSSW}.txt"
rm -rf $result2
index=0
for str in `head -n 20 old2.txt | awk '{print $7}'`
do
   ((index++))
   oldDat=`grep $str old2.txt | awk -v str=$str '{if ($7 == str) {print}}'`
   newDat=`grep $str new2.txt | awk -v str=$str '{if ($7 == str) {print}}'`

   oldRank=`echo $oldDat | awk '{print $1}'`
   newRank=`echo $newDat | awk '{print $1}'`

   oldValue=`echo $oldDat | awk '{print $2}'`
   newValue=`echo $newDat | awk '{print $2}'`

   if [ "$oldRank" == "" ]; then oldRank="Non"; fi
   if [ "$newRank" == "" ]; then newRank="Non"; fi
   if [ "$oldValue" == "" ]; then oldValue="Non"; fi
   if [ "$newValue" == "" ]; then newValue="Non"; fi

   echo "[ $oldRank -> $newRank ] [ $oldValue --> $newValue ] $str" >> $result2
done
mv $result2 ${result2}.temp
column -t ${result2}.temp > $result2
rm -rf ${result2}.temp
cat $result2

##############################
echo "Done step2"
##############################


strs="
EcalUncalibRecHitProducer
MultiTrackSelector
CkfTrackCandidateMakerBase
SeedGeneratorFromRegionHitsEDProducer
MuonIdProducer
HcalHitReconstructor
"

names=""
for str in $strs
do
	names="$names `grep $str old1.txt | awk '{print $6}'`"
done

cp old1.txt myOld1.txt
cp new1.txt myNew1.txt

result3="compare3_${oldCMSSW}_${newCMSSW}.txt"
rm -rf $result3
rm -rf delta_report.txt
for name in $names
do
	oldDat=`grep $name old2.txt | awk -v name=$name '{if ($7 == name) {print}}'`
	newDat=`grep $name new2.txt | awk -v name=$name '{if ($7 == name) {print}}'`
	oldValue=`echo $oldDat | awk '{print $3}'`
	newValue=`echo $newDat | awk '{print $3}'`
	oldValue=${oldValue//,/}
	newValue=${newValue//,/}
	echo "Value $name new $newValue old $oldValue"
	if [ "$newValue" == "" ]; then continue; fi
	if [ "$oldValue" == "" ]; then continue; fi
	newValue=`python -c "print $newValue * $nevOld / $nevNew"`
	delta=`python -c "print round(($newValue - $oldValue) / $sponValueOld * 100.0 ,2)"`
	echo "(${newValue}-${oldValue})/${sponValueOld}*100%)= $delta% $name" >> $result3
	isReport=`python -c "if $delta > 0.5: print 1"`
	if [ "$isReport" == "1" ]; then
		echo "(${newValue}-${oldValue})/${sponValueOld}*100%)= $delta% $name" >> delta_report.txt
	fi
	isReport=`python -c "if $delta < -0.5: print 1"`
	if [ "$isReport" == "1" ]; then
		echo "(${newValue}-${oldValue})/${sponValueOld}*100%)= $delta% $name" >> delta_report.txt
	fi
done
mv $result3 ${result3}.temp
column -t ${result3}.temp > $result3
rm -rf ${result3}.temp
cat $result3

##############################
echo "Done step3"
##############################

###   string3="edm::EDProducer::doEvent("
###   oldLink=`grep $string3 old.html | sed -e 's/\(^.*href="\)\(.*\)\(">.*$\)/\2/'`
###   newLink=`grep $string3 new.html | sed -e 's/\(^.*href="\)\(.*\)\(">.*$\)/\2/'`
###   
###   curl -s $web/$oldLink > old3.html
###   curl -s $web/$newLink > new3.html
###   html2text -width 10000 old3.html | sed -e "s/&amp;/\&/g" > old.txt
###   html2text -width 10000 new3.html | sed -e "s/&amp;/\&/g" > new.txt
###   
###   allLineNew=`cat new.txt | wc -l`
###   allLineOld=`cat old.txt | wc -l`
###   
###   firstLineNew=`grep -n $string3 new.txt | cut -f1 -d:`
###   firstLineOld=`grep -n $string3 old.txt | cut -f1 -d:`
###   
###   head -n `expr $allLineNew - 1` new.txt | tail -n `expr $allLineNew - $firstLineNew - 1` > new1.txt
###   head -n `expr $allLineOld - 1` old.txt | tail -n `expr $allLineOld - $firstLineOld - 1` > old1.txt
###   
###   result4Old="compare4Old_${oldCMSSW}_${newCMSSW}.txt"
###   result4New="compare4New_${oldCMSSW}_${newCMSSW}.txt"
###   
###   cat old1.txt | awk '{print $1," ",$6}' > $result4Old
###   cat new1.txt | awk '{print $1," ",$6}' > $result4New
###   
###   mv $result4Old ${result4Old}.temp
###   column -t ${result4Old}.temp > $result4Old
###   rm -rf ${result4Old}.temp
###   cat $result4Old
###   
###   mv $result4New ${result4New}.temp
###   column -t ${result4New}.temp > $result4New
###   rm -rf ${result4New}.temp
###   cat $result4New
##############################
###   echo "Done step4"
##############################



resultAll="compareIgprof${type}_${step}_${newCMSSW}_${oldCMSSW}.dat"

echo "Compare Igprof ${type} ${step} $oldCMSSW vs $newCMSSW" > $resultAll
echo "" >> $resultAll

echo "### legacy modules $oldCMSSW --> $newCMSSW " >> $resultAll
sed -e "s/_/ /g" $result1 >> $resultAll 
echo "" >> $resultAll

echo "### top 20 ::stream ED producers Rank and Cost [$oldCMSSW --> $newCMSSW]" >> $resultAll
sed -e "s/_/ /g" $result2 >> $resultAll
echo "" >> $resultAll

echo "### Delta Check : [$newCMSSW - $oldCMSSW / total * 100% = delta]" >> $resultAll
sed -e "s/_/ /g" $result3 >> $resultAll
echo "" >> $resultAll

# echo "### top-5 legacy modules for $newCMSSW  " >> $resultAll
# sed -e "s/_/ /g" $result4New >> $resultAll
# echo "" >> $resultAll
# 
# echo "### top-5 legacy modules for $oldCMSSW  " >> $resultAll
# sed -e "s/_/ /g" $result4Old >> $resultAll
# echo "" >> $resultAll


echo "####### Result ######### " 
cat $resultAll

echo "### result file"
ls -al $resultAll
echo ""

if [ -f delta_report.txt ]; then 
	echo ""
	mv delta_report.txt delta_report.txt.temp
	column -t delta_report.txt.temp > delta_report.txt
	rm -rf delta_report.txt.temp
	sed -e "s/_/ /g" delta_report.txt > delta_report.txt.temp
	rm -rf delta_report.txt
	mv delta_report.txt.temp delta_report.txt

#	echo -e "\033[0;31m<br> &nbsp; &nbsp; &nbsp; &nbsp; - delta report \033[0m"
	cat delta_report.txt | \
	while read CMD; do
		delta=`echo $CMD | awk '{print $2}'`
		if [ "${delta:0:1}" == "-" ]; then
			echo -e "\033[0;32m<br> &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <small><font color=\"green\"> ${CMD} </font></small> \033[0m"
		else
			echo -e "\033[0;31m<br> &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <small><font color=\"red\"> ${CMD} </font></small> \033[0m"
		fi
	done 
fi

rm -rf *.html *.txt
ReresultAll=${resultAll/.dat/.txt}
mv $resultAll igprofCompare/${ReresultAll}
}

# single CMSSW_7_6_0_pre7 CMSSW_7_6_0
# single CMSSW_7_6_0_pre6 CMSSW_7_6_0_pre7
# single CMSSW_7_6_0_pre5 CMSSW_7_6_0_pre6
# single CMSSW_7_6_0_pre4 CMSSW_7_6_0_pre5
if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ ! $1 ] || [ ! $2 ]; then echo "usage $0 oldCMSSW_BASE newCMSSW_BASE"; exit; fi

old=$1
new=$2
single $old $new





