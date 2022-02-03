import pandas as pd
import requests
from bs4 import BeautifulSoup
from IPython.display import display

import argparse

parser = argparse.ArgumentParser()

parser.add_argument('--old', type=str,
            help="old version ex. CMSSW11_0_0_pre1 or CMSSW11_0_0_pre1PAT")
parser.add_argument('--new', type=str,
            help="new version ex. CMSSW11_0_0_pre2 or CMSSW11_0_0_pre2PAT")
parser.add_argument('--baseurl', type=str, default='https://cmssdt.cern.ch', required=False,
            help="base url for igprof-navigator ex. https://cmssdt.cern.ch")
parser.add_argument('--igprof', type=str, default='/SDT/cgi-bin/igprof-navigator', required=False,
            help="path to igprof-navigator from base url, ex. /SDT/cgi-bin/igprof-navigator")
parser.add_argument('--arch', type=str, default='slc7_amd64_gcc820', required=False,
            help="arch of version, ex slc7_amd64_gcc820")
parser.add_argument('--workflow', type=str, default='34834.21', required=False,
            help="workflow used for profiling, ex 34834.21")

args = parser.parse_args()

isPAT=False
if args.old[-3:] == 'PAT':
    isPAT=True

oldlink='%s/%s/%s/%s/profiling/%s/igprofCPU_step3' % (args.baseurl,args.igprof,args.old,args.arch,args.workflow)
newlink='%s/%s/%s/%s/profiling/%s/igprofCPU_step3' % (args.baseurl,args.igprof,args.new,args.arch,args.workflow)


new_req=requests.get(newlink, verify=False)
new_html = new_req.text
new_soup = BeautifulSoup(new_html,'html.parser')

old_req=requests.get(oldlink, verify=False)
old_html = old_req.text
old_soup = BeautifulSoup(old_html,'html.parser')

### new parsing
## make data frame
columns=new_soup.select('tr > th')
columnlist=[]
for column in columns:
    columnlist.append(column.text)
new_df=pd.DataFrame(columns=columnlist)

contents = new_soup.select('tr')
dfcontent=[]
alldfcontents=[]

for content in contents:
    tds=content.find_all("td")
    for td in tds:
        dfcontent.append(td.text)
    alldfcontents.append(dfcontent)
    dfcontent=[]



new_df=pd.DataFrame(columns=columnlist, data=alldfcontents)


### old parsing
## make data frame
columns=old_soup.select('tr > th')
columnlist=[]
for column in columns:
    columnlist.append(column.text)
old_df=pd.DataFrame(columns=columnlist)

contents = old_soup.select('tr')
dfcontent=[]
alldfcontents=[]

for content in contents:
    tds=content.find_all("td")
    for td in tds:
        dfcontent.append(td.text)
    alldfcontents.append(dfcontent)
    dfcontent=[]
old_df=pd.DataFrame(columns=columnlist, data=alldfcontents)

rank  = columnlist[0]
total = columnlist[1]
comul = columnlist[2]


old_df[comul] = old_df[comul].str.replace(',','').astype('float')
new_df[comul] = new_df[comul].str.replace(',','').astype('float')


### step2

old_df_for_str2  = old_df.dropna()
indexes_for_str2 = old_df['Symbol name'].str.contains('doEvent').dropna()
list_str2 = old_df_for_str2[indexes_for_str2]['Symbol name'].values.tolist()




columnlist=['Rank','total','count_to/from','count_total','path_including','path_total','name']
cnt=0 # cnt for print different str2 initialzed info
global_old_df = pd.DataFrame(columns=columnlist)
global_new_df = pd.DataFrame(columns=columnlist)






for str2 in list_str2:
	link_list=[]
	for link in old_soup.findAll("a"):
	    if 'href' in link.attrs:
	        name=link.text
	        if name.startswith(str2):
	            link_list.append(link.attrs['href'])
	            #print(link.attrs['href'])
	            
	if not link_list:
		continue;
	old_str2_link=args.baseurl+link_list[0]
	
	link_list=[]
	for link in new_soup.findAll("a"):
	    if 'href' in link.attrs:
	        name=link.text
	        if name.startswith(str2):
	            link_list.append(link.attrs['href'])
	            #print(link.attrs['href'])
	
	if not link_list:
		continue;            
	new_str2_link=args.baseurl+link_list[0]
	
	old_req=requests.get(old_str2_link, verify=False)
	old_html = old_req.text
	old_str2_soup = BeautifulSoup(old_html,'html.parser')
	
	new_req=requests.get(new_str2_link, verify=False)
	new_html = new_req.text
	new_str2_soup = BeautifulSoup(new_html,'html.parser')
	
	
	contents = old_str2_soup.select('tr')
	dfcontent=[]
	alldfcontents=[]
	
	for content in contents:
	    tds=content.find_all("td")
	    for td in tds:
	        dfcontent.append(td.text)
	    alldfcontents.append(dfcontent)
	    dfcontent=[]
	
	old_str2_df = pd.DataFrame(columns=columnlist, data=alldfcontents)
	old_str2_df = old_str2_df.dropna()
	stIdx_old	= old_str2_df.loc[old_str2_df['name'] == str2].index[0] -1 
	old_str2_df = old_str2_df[stIdx_old:]
	
	
	contents = new_str2_soup.select('tr')
	dfcontent=[]
	alldfcontents=[]
	
	for content in contents:
	    tds=content.find_all("td")
	    for td in tds:
	        dfcontent.append(td.text)
	    alldfcontents.append(dfcontent)
	    dfcontent=[]
	
	new_str2_df = pd.DataFrame(columns=columnlist, data=alldfcontents)
	new_str2_df = new_str2_df.dropna()
	stIdx_new	= new_str2_df.loc[new_str2_df['name'] == str2].index[0] -1
	new_str2_df = new_str2_df[stIdx_new:]
	
	global_old_df = pd.concat([global_old_df,old_str2_df],ignore_index=True)
	global_new_df = pd.concat([global_new_df,new_str2_df],ignore_index=True)
	

global_old_df['count_total'] =global_old_df['count_total'].str.replace(',','').astype('float')
global_new_df['count_total'] =global_new_df['count_total'].str.replace(',','').astype('float')

global_old_df['count_to/from'] =global_old_df['count_to/from'].str.replace(',','').astype('float')
global_new_df['count_to/from'] =global_new_df['count_to/from'].str.replace(',','').astype('float')

global_old_df = global_old_df.sort_values(by=['count_total'],axis=0,ascending=False)
global_new_df = global_new_df.sort_values(by=['count_total'],axis=0,ascending=False)

global_old_df = global_old_df.reset_index(drop=True)
global_new_df = global_new_df.reset_index(drop=True)

sorted_df = global_old_df










Tot_strs  = sorted_df['name']

oldAll_=list(old_df.loc[old_df['Symbol name']=="<spontaneous>"][comul])

if not oldAll_:
	oldAll= list(new_df.loc[new_df['Symbol name']=="<spontaneous>"][comul])[0]
else:
	oldAll=list(old_df.loc[old_df['Symbol name']=="<spontaneous>"][comul])[0]
	


print("==================================================================================================================================================================================")
print("Rank			Total%	 		Cumulative					Delta						Symbol name")
print("==================================================================================================================================================================================")


oldVal_sum=0
newVal_sum=0

for Tot_str in Tot_strs:
	idx_new = global_new_df.loc[global_new_df['name']==Tot_str].index 
	idx_old = global_old_df.loc[global_old_df['name']==Tot_str].index
	
	if not(list(idx_new)):
		continue
	
	if(idx_old.size ==0 or idx_new.size==0): 
		continue
	
	if(Tot_str == "_init"):
	    continue
	if Tot_str.startswith("edm::service::Timing::postModuleEvent"):
		continue
	if Tot_str.startswith("edm::Event::commit_"):
	    continue
	if Tot_str.startswith("edm::Event::~Event()"):
	    continue
	if Tot_str.startswith("edm::Event::setProducer"):
	    continue
	if Tot_str.startswith("edm::Event::setConsumer"):
	    continue
	if Tot_str.startswith("edm::SystemTimeKeeper::startModuleEvent"):
	    continue  
	if Tot_str.startswith("edm::ModuleCallingContext::getStreamContext()"):
	    continue   
	if Tot_str.startswith("edm::service::MessageLogger::unEstablishModule"):
	    continue   

	module_name = Tot_str.split("(edm")[0] 
	splited_module = module_name.split(">,")
	if len(splited_module) > 1:
		out_name = splited_module[0] + "..."
	else:
		out_name = module_name
	
	oldVal=global_old_df.loc[idx_old[0]]["count_total"]
	newVal=global_new_df.loc[idx_new[0]]["count_total"]
	
	oldVal_sum += oldVal
	newVal_sum += newVal
	
	delta	  = round((newVal - oldVal) / oldAll * 100.0,2)	
	#delta_sum = round((newVal_sum - oldVal_sum) / oldAll * 100.0,2)	

	print("[{0:<4} -> {1:<4}] [{2:<6} -> {3:<6}]  [{4:<9} -> {5:<9}]         [ {6:<9}  - {7:<9} / {8:<9} *100% ] = [{9:<6}% ]         {10:<50}".format(idx_old[0],idx_new[0], global_old_df.loc[idx_old[0]]['total'],global_new_df.loc[idx_new[0]]['total'],global_old_df.loc[idx_old[0]]['count_total'],global_new_df.loc[idx_new[0]]['count_total'],newVal,oldVal,oldAll,delta,out_name))


print(" ")

print(">> Total Cumulative(old->new): {0:<5} -> {1:<5}".format(oldVal_sum,newVal_sum))


print(" ")















