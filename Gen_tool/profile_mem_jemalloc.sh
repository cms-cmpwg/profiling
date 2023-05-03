#!/bin/bash
scram setup jemalloc-prof
scram b ToolUpdated
PATH=$PATH:$JEMALLOC_PROF_BASE/bin
for f in $(ls *.heap 2>/dev/null);do
  jeprof --text --cum --show_bytes --exclude="(jeprof_*|prof_*|fallback*)" `which cmsRunJEProf` $f >$f.txt
done
