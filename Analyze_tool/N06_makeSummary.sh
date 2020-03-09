maxVSIZ=`./N02_getTimeMemSummary.sh $1 | grep "Max VSIZ" | awk '{print $3,"(",$6,")"}'`
maxRSS=`./N02_getTimeMemSummary.sh  $1 | grep "max RSS"  | awk '{print $10,"(",$13,")"}'`
avCPU=`./N02_getTimeMemSummary.sh   $1 | grep "M1 Time"  | awk '{print $4}'`
maxCPU=`./N02_getTimeMemSummary.sh  $1 | grep "M1 Time"  | awk '{print $7,"(",$11,")"}'`

cat << EOF 
<html>
<head>
<style>
table {
   border-collapse: collapse;
   border:0;
   text-align:center;
   width: 50%;
   table-layout:fixed;
}
th, td {
   text-align: center;
   width:230px;
   padding: 2px;
}
tr:nth-child(odd){background-color: #f2f2f2}
</style>
<title>Summary Time and Memory Test</title>
</head>
<body>

<h2>Summary : Time and Memory Test: `basename $1`</h2>
<div style="overflow-x:auto;">
<table>
<tr></th><th> VERSION          </th><th> (RSS)MaxMemory(evt)</th><th> (VSIZE)MaxMemory(evt)</th><th> AverageTime</th><th> MaxTime(evt)</th></tr>
EOF


echo " <tr></td><td> $1 </td><td> $maxRSS </td><td> $maxVSIZ </td><td> $avCPU </td><td> $maxCPU </td></tr>"
