#!/bin/bash
for f in $(ls *CPU*.gz 2>/dev/null);do
## --For web-based report
    sqlf=${f/gz/sql3}
    sf=${f/igprof/}
    logf=${sf/gz/log}
    igprof-analyse --sqlite -v -d -g $f |  sqlite3 $sqlf 2>> $logf 3>&2 &
## --For ascii-based report
    rf=${f/igprof/RES_}
    txtf=${rf/gz/txt.gz}
    igprof-analyse  -v -d -g $f | gzip -c > $txtf 2>> $logf 3>&2 &
done
wait
if [ -f RES_CPU_step3.txt.gz ]; then
  export IGREP=RES_CPU_step3.txt
  export IGSORT=sorted_RES_CPU_step3.txt
  gzip -dc RES_CPU_step3.txt.gz >RES_CPU_step3.txt && awk -v module=doEvent 'BEGIN { total = 0; } { if(substr($0,0,1)=="-"){good = 0;}; if(good&&length($0)>0){print $0; total += $3;}; if(substr($0,0,1)=="["&&index($0,module)!=0) {good = 1;} } END { print "Total: "total } ' ${IGREP} | sort -n -r -k1 | awk '{ if(index($0,"Total: ")!=0){total=$0;} else{print $0;} } END { print total; }' > ${IGSORT} 2>&1 && rm RES_CPU_step3.txt &
fi
wait
