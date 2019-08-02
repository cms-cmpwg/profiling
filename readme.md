## CPU and Memory monitoring job  
---
### 1. All results are uploaded here: https://jiwoong.web.cern.ch/jiwoong/  
### 2. ASCII type results are uploaded N01_profile/10_6_X and N02_compare_summary/results_XX  
### 3. N01_profile covers basic output of Igprof and N02_compare_summary covers time and memory comparison based on step3.log*  
##### step3.log(Timechekc output) can be generated adding following code on python config files  

```python
# Automatic addition of the customisation function from Validation.Performance.TimeMemoryInfo
from Validation.Performance.TimeMemoryInfo import customise

#call to customisation function customise imported from Validation.Performance.TimeMemoryInfo
process = customise(process)
```  

