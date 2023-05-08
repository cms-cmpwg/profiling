#!/bin/bash
scram setup jemalloc-prof
scram b ToolUpdated
eval `scram run -sh`
PATH=$PATH:$(scram tool info jemalloc | grep BINDIR | cut -d= -f2)
which jeprof
for f in $(ls *.heap 2>/dev/null);do
  jeprof --text --cum --show_bytes --exclude="(jeprof_*|prof_*|fallback*)" `which cmsRunJEProf` $f >$f.txt
done
