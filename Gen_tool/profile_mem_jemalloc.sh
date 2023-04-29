#!/bin/bash
for f in $(ls *.heap 2>/dev/null);do
  jeprof --text --cum --show_bytes --exclude="(jeprof_*|prof_*|fallback*)" /build/gartung/CMSSW_13_1_0_SKYLAKEAVX512_pre3/bin/el8_amd64_gcc11/cmsRunJEProf $f >$f.txt
done
