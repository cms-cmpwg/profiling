## Tools for analyze results  
### 1. N01_compare_cpu.py  
 - This can compare CPU usages based on igprof web-based reports ( web crawler is used )  
```bash  
$ python CMSSW11_1_0_pre1 CMSSW11_1_0_pre2
```
 - Output example: https://jiwoong.web.cern.ch/jiwoong/results/phase2/compare_results/cl_compare_cpu_11_1_0Pre1vsPre2.txt  

### 2. N02_getTimeMemSummary.sh   
 - This has two modes  
 - mode 1 makes simple summary (ex https://jiwoong.web.cern.ch/jiwoong/results/phase2/getTimeMemSummary_CMSSW_11_1_0_pre2.txt )  
 - mode 2 makes input file used in making histogram ( N05_makehist.py )  
```bash
$ ./N02_getTimeMemSummary.sh CMSSW_11_1_0
```  

### 3. N03_timeDiffFromReport.sh  
 - This can compare CPU-time of two different CMSSW versions based on step3.log(or step4.log) file  
```bash
$ ./N03_timeDiffFromReport.sh CMSSW_11_1_0_pre1 CMSSW_11_1_0_pre2
```
 - output examples: https://jiwoong.web.cern.ch/jiwoong/results/phase2/compare_timedff/tdf_compare_cpu_11_1_0Pre1vsPre2.txt  

### 4. N04_compareProducts.sh  
 - This can compare branch sizes of two  different CMSSW versions based on step3.root(or step4.root) file  
 - Please comment out https://github.com/ico1036/ServiceWork/blob/master/Analyze_tool/compareProducts.awk#L47 and L55 when you run step4  
```bash
$ ./N04_compareProducts.sh CMSSW_11_1_0_pre1 CMSSW_11_1_0_pre2
```  

### 5. N05_makehist.py ( N05_makehist_PAT.py )  
 - This makes image file of **histogram** using N02_getTimeMemSummary.sh ( mode2 ) output  

### 6. N06_makeSummary.sh  
 - This makes **Summary page** using output image of N05_makehist.py  
 - examples: https://jiwoong.web.cern.ch/jiwoong/results/phase2/shortSummary_step3.html  


