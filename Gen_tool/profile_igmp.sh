#!/bin/bash
for f in $(ls *MEM*.gz 2>/dev/null);do
## --For web-based report
    sqlf=${f/gz/sql3}
    sf=${f/igprofMEM/MEMsql}
    logf=${sf/gz/log}
    igprof-analyse --sqlite -v -d -g -r MEM_LIVE $f | sqlite3 $sqlf 2>> $logf 3>&2 &
## --For ascii-based report
    rf=${f/igprof/RES_}
    txtf=${rf/gz/txt.gz}
    igprof-analyse  -v -d -g -r MEM_LIVE $f | gzip -c > $txtf 2>> $logf 3>&2 &
done
wait
