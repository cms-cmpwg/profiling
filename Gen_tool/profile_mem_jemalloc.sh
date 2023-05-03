#!/bin/bash
for f in $(ls *.heap 2>/dev/null);do
  jeprof --text --cum --show_bytes --exclude="(jeprof_*|prof_*|fallback*)" `which cmsRunJEProf` $f >$f.txt
done
