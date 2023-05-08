#!/bin/bash
scram setup jemalloc-prof
scram b ToolUpdated
eval `scram run -sh`
PATH=$PATH:$JEMALLOC_BASE/bin
which jeprof
for f in $(ls *.heap 2>/dev/null);do
  $JEMALLOC_BASE/bin/jeprof --text --cum --show_bytes --exclude="(jeprof_*|prof_*|fallback*)" `which cmsRunJEProf` $f >$f.txt
done
