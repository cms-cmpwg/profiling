#!/bin/bash

for f in $(ls *.gz 2>/dev/null);do
## --For web-based report
    sqlf=${f/gz/sql3}
    sf=${f/igprofMEM/MEMsql}
    logf=${sf/gz/log}
    igprof-analyse --sqlite -v -d -g -r MEM_LIVE $f >$f.tmp 2> $logf 3>&2
    ./fix-igprof-sql.py $f.tmp | sqlite3 $sqlf 2>> $logf 3>&2
## --For ascii-based report
    rf=${f/igprof/RES_}
    txtf=${rf/gz/txt}
    igprof-analyse  -v -d -g -r MEM_LIVE $f > $txtf 2>> $logf 3>&2
done