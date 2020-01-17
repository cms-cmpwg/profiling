import pandas as pd
import requests
from bs4 import BeautifulSoup
from IPython.display import display

import argparse

parser = argparse.ArgumentParser()

parser.add_argument('old', type=str,
            help="old version ex. CMSSW11_0_0_pre1 or CMSSW11_0_0_pre1PAT")
parser.add_argument('new', type=str,
            help="new version ex. CMSSW11_0_0_pre2 or CMSSW11_0_0_pre2PAT")

args = parser.parse_args()

isPAT=False
if args.old[-3:] == 'PAT':
    isPAT=True


oldlink='https://jiwoong.web.cern.ch/jiwoong/cgi-bin/igprof-navigator/igprofCPU_' + args.old
newlink='https://jiwoong.web.cern.ch/jiwoong/cgi-bin/igprof-navigator/igprofCPU_' + args.new


new_req=requests.get(newlink)
new_html = new_req.text
new_soup = BeautifulSoup(new_html,'html.parser')

old_req=requests.get(oldlink)
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


####################################################################################################  step1 
#print("### legacy modules {0} --> {1}".format(args.old,args.new))

strs=["edm::WorkerT<edm::EDProducer>",
"edm::WorkerT<edm::stream::EDProducerAdaptorBase>",
"edm::WorkerT<edm::one::OutputModuleBase>",
]


old_global_idx = []
new_global_idx = []

for str in strs:
	
	idx_old=old_df.loc[old_df['Symbol name'].str.startswith(str,na=False)].index
	idx_new=new_df.loc[new_df['Symbol name'].str.startswith(str,na=False)].index
	
	
	if(idx_old.size !=0 and idx_new.size!=0):
		result_old=old_df.loc[idx_old[0]][total]
		result_new=new_df.loc[idx_new[0]][total]
		old_global_idx.append(idx_old[0])
		new_global_idx.append(idx_new[0])
		#print("{0:<5} ====> {1:<10}   {2:>30}".format(old_df.loc[idx_old[0]][total],new_df.loc[idx_new[0]][total],str))
	
	elif(idx_old.size!=0 and idx_new.size==0):
		old_global_idx.append(idx_old[0])
		new_global_idx.append('N')
		#print("{0:<5} ====> {1:<10}   {2:>30}".format(old_df.loc[idx_old[0]][total],"None",str))
	
	elif(idx_old.size==0 and idx_new.size!=0):
		old_global_idx.append('N')
		new_global_idx.append(idx_new[0])
		#print("{0:<5} ====> {1:<10}   {2:>30}".format("None",new_df.loc[idx_new[0]][total],str))
	
	elif(idx_old.size==0 and idx_new.size==0):
		continue;
		#print("{0:<5} ====> {1:<10}   {2:>30}".format("None","None",str))
	
print(" ")


### step2

old_df_for_str2  = old_df.dropna()
indexes_for_str2 = old_df['Symbol name'].str.contains('doEvent').dropna()
list_str2 = old_df_for_str2[indexes_for_str2]['Symbol name'].values.tolist()

#list_str2=["edm::stream::EDProducerAdaptorBase::doEvent(",
#"edm::global::EDProducerBase::doEvent",
#"edm::WorkerT<edm::global::EDProducerBase>::implDo(edm::EventPrincipal const&, edm::EventSetupImpl const&, edm::ModuleCallingContext const*)"]

#print(list_str2)


cnt=0 # cnt for print different str2 initialzed info
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
	old_str2_link="https://jiwoong.web.cern.ch"+link_list[0]
	
	link_list=[]
	for link in new_soup.findAll("a"):
	    if 'href' in link.attrs:
	        name=link.text
	        if name.startswith(str2):
	            link_list.append(link.attrs['href'])
	            #print(link.attrs['href'])
	
	if not link_list:
		continue;            
	new_str2_link="https://jiwoong.web.cern.ch"+link_list[0]
	
	old_req=requests.get(old_str2_link)
	old_html = old_req.text
	old_str2_soup = BeautifulSoup(old_html,'html.parser')
	
	new_req=requests.get(new_str2_link)
	new_html = new_req.text
	new_str2_soup = BeautifulSoup(new_html,'html.parser')
	
	columnlist=['Rank','total','count_to/from','count_total','path_including','path_total','name']
	
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
	
	
	cnt+=1
	if cnt == 3:
		if not isPAT:
			str2_list = list(old_str2_df[4:24]['name']) #step3 AOD
		else: 
			str2_list = list(old_str2_df[4:23]['name']) #step4 PAT
	else:
		if not isPAT:
			str2_list = list(old_str2_df[4:24]['name']) #step3 AOD
		else: 
			str2_list = list(old_str2_df[4:24]['name']) #step4 PAT
	

		
	print(" ")
	for str2 in str2_list:
		idx_new=new_df.loc[new_df['Symbol name']==str2].index 
		idx_old=old_df.loc[old_df['Symbol name']==str2].index  # 1 2 3 4 5... 20
		if(idx_old.size !=0 and idx_new.size!=0):
			old_global_idx.append(idx_old[0])
			new_global_idx.append(idx_new[0])
		elif(idx_old.size!=0 and idx_new.size==0):
			old_global_idx.append(idx_old[0])
			new_global_idx.append('N')
		elif(idx_old.size==0 and idx_new.size!=0):
			old_global_idx.append('N')
			new_global_idx.append(idx_new[0])
		elif(idx_old.size==0 and idx_new.size==0):
			continue;



#sorted_df = old_df.loc[old_global_idx].sort_values(by=[comul],axis=0,ascending=False)
sorted_df = old_df.loc[old_global_idx]

Tot_strs  = sorted_df['Symbol name']

oldAll_=list(old_df.loc[old_df['Symbol name']=="<spontaneous>"][comul])

if not oldAll_:
	oldAll= list(new_df.loc[new_df['Symbol name']=="<spontaneous>"][comul])[0]
else:
	oldAll=list(old_df.loc[old_df['Symbol name']=="<spontaneous>"][comul])[0]
	



print("==================================================================================================================================================================================")
print(" Rank		Total%		Cumulative						Delta								Symbol name")
print("==================================================================================================================================================================================")
for Tot_str in Tot_strs:
	idx_new=new_df.loc[new_df['Symbol name']==Tot_str].index 
	idx_old=old_df.loc[old_df['Symbol name']==Tot_str].index
	
	if not(list(idx_new)):
		continue
	
	if(idx_old.size ==0 or idx_new.size==0): 
		continue;
	
	oldVal=old_df.loc[idx_old[0]][comul]
	newVal=new_df.loc[idx_new[0]][comul]
	
	delta= round((newVal - oldVal) / oldAll * 100.0,2)	
	

	print("[{0:<4} -> {1:<4}] [{2:<6} -> {3:<6}]  [{4:<9} -> {5:<9}]         [ {6:<9}  - {7:<9} / {8:<9} *100% ] = [{9:<6}% ]         {10:<50}".format(old_df.loc[idx_old[0]][rank],new_df.loc[idx_new[0]][rank], old_df.loc[idx_old[0]][total],new_df.loc[idx_new[0]][total],old_df.loc[idx_old[0]][comul],new_df.loc[idx_new[0]][comul],newVal,oldVal,oldAll,delta,Tot_str.split("(edm")[0]))






















