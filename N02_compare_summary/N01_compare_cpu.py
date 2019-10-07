import pandas as pd
import requests
from bs4 import BeautifulSoup

#oldlink='https://ycyang.web.cern.ch/ycyang/cgi-bin/igprof-navigator/CMSSW_8_1_0_pre2_igprofCPU'
#newlink='https://ycyang.web.cern.ch/ycyang/cgi-bin/igprof-navigator/CMSSW_8_1_0_pre3_igprofCPU'

oldlink='https://jiwoong.web.cern.ch/jiwoong/cgi-bin/igprof-navigator/igprofCPU_CMSSW11_0_0_pre1'
newlink='https://jiwoong.web.cern.ch/jiwoong/cgi-bin/igprof-navigator/igprofCPU_CMSSW11_0_0_pre2'

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

###  step1 
total=columnlist[1]

print("### legacy modules CMSSW_11_0_0_pre1 --> CMSSW_11_0_0_pre2")

strs=["edm::WorkerT<edm::EDProducer>::implDo(",
"edm::WorkerT<edm::stream::EDProducerAdaptorBase>::implDo(",
"edm::WorkerT<edm::one::OutputModuleBase>::implDo("]


for str in strs:
    
    idx_old=old_df.loc[old_df['Symbol name'].str.startswith(str,na=False)].index
    idx_new=new_df.loc[new_df['Symbol name'].str.startswith(str,na=False)].index

    if(idx_old.size !=0 and idx_new.size!=0):
        result_old=old_df.loc[idx_old[0]][total]
        result_new=new_df.loc[idx_new[0]][total]
        print("{0:<5} ====> {1:<10}   {2:>30}".format(old_df.loc[idx_old[0]][total],new_df.loc[idx_new[0]][total],str))
    elif(idx_old.size!=0 and idx_new.size==0):
        print("{0:<5} ====> {1:<10}   {2:>30}".format(old_df.loc[idx_old[0]][total],"None",str))
    elif(idx_old.size==0 and idx_new.size!=0):
        print("{0:<5} ====> {1:<10}   {2:>30}".format("None",new_df.loc[idx_new[0]][total],str))
    elif(idx_old.size==0 and idx_new.size==0):
        print("{0:<5} ====> {1:<10}   {2:>30}".format("None","None",str))
#display(old_df[old_df['Symbol name'].str.startswith('edm::WorkerT<edm::EDProducer>::implDo(',na=False)][total])
#display(new_df[new_df['Symbol name'].str.startswith('edm::WorkerT<edm::EDProducer>::implDo(',na=False)][total])

### step2

str2="edm::stream::EDProducerAdaptorBase::doEvent("

link_list=[]
for link in old_soup.findAll("a"):
    if 'href' in link.attrs:
        name=link.text
        if name.startswith(str2):
            link_list.append(link.attrs['href'])
            #print(link.attrs['href'])
            
old_str2_link="https://jiwoong.web.cern.ch"+link_list[0]

link_list=[]
for link in new_soup.findAll("a"):
    if 'href' in link.attrs:
        name=link.text
        if name.startswith(str2):
            link_list.append(link.attrs['href'])
            #print(link.attrs['href'])
            
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

old_str2_df=pd.DataFrame(columns=columnlist, data=alldfcontents)

contents = new_str2_soup.select('tr')
dfcontent=[]
alldfcontents=[]

for content in contents:
    tds=content.find_all("td")
    for td in tds:
        dfcontent.append(td.text)
    alldfcontents.append(dfcontent)
    dfcontent=[]

new_str2_df=pd.DataFrame(columns=columnlist, data=alldfcontents)

str2_list = list(old_str2_df[4:24]['name'])
print("### top 20 ::stream ED producers Rank and Cost [CMSSW_11_0_0_pre1 --> CMSSW_11_0_0_pre2]")

for str2 in str2_list:
    idx_new=new_str2_df.loc[new_str2_df['name']==str2].index 
    idx_old=old_str2_df.loc[old_str2_df['name']==str2].index  # 1 2 3 4 5... 20
    print("[{0:<2} -> {1:<2}] [{2:<2} -> {3:<2}] {4:>40}".format(idx_old[0]-3, idx_new[0]-3, old_str2_df.loc[idx_old[0]]['total'],new_str2_df.loc[idx_new[0]]['total'],str2))

str3=["EcalUncalibRecHitProducer::produce(edm::Event&, edm::EventSetup const&)",
"MultiTrackSelector::run(edm::Event&, edm::EventSetup const&) const",
"cms::CkfTrackCandidateMakerBase::produceBase(edm::Event&, edm::EventSetup const&)",
"SeedGeneratorFromRegionHitsEDProducer::produce(edm::Event&, edm::EventSetup const&)",
"MuonIdProducer::produce(edm::Event&, edm::EventSetup const&)",
"CosmicsMuonIdProducer::produce(edm::Event&, edm::EventSetup const&)",
"HcalHitReconstructor::produce(edm::Event&, edm::EventSetup const&)"]

Cumulative=old_df.columns[2]

oldAll=list(old_df.loc[old_df['Symbol name']=="<spontaneous>"][Cumulative])[0]
oldAll=float(oldAll.replace(',','').strip())

print("### Delta Check : [CMSSW_11_0_0_pre2 - CMSSW_11_0_0_pre1 / total * 100% = delta]")

for str in str3:
    
    idx_old=old_df.loc[old_df['Symbol name']==str].index
    idx_new=new_df.loc[new_df['Symbol name']==str].index
    
    if(idx_old.size ==0 or idx_new.size==0): continue;
    
    
    oldVal=float(old_df.loc[idx_old[0]][Cumulative].replace(',','').strip())
    newVal=float(new_df.loc[idx_new[0]][Cumulative].replace(',','').strip())
    delta= round((newVal - oldVal) / oldAll * 100.0,2)
    
    print("{0:7}  - {1:7} / {2} *100% = {3:5}%  {4:<30}".format(newVal,oldVal,oldAll,delta,str))
    
    
