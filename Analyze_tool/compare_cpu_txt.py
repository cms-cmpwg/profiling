#!/bin/env python
import pandas as pd
from IPython.display import display

import argparse
import re

def displaymatch(match):
    if match is None:
        return None
    return '<Match: %r, groups=%r>' % (match.group(), match.groups())

re_cumulative=re.compile(r"\s*(\d+\.?\d+)\s*(\d+[']?\d+\.?\d+)\s*(.*)(\[\d+\])")
m=re_cumulative.match("  100.0   2'597.60  <spontaneous> [1]\n")
assert(m)
n=re_cumulative.match('    1.8      46.74  Eigen::internal::TensorExecutor<Eigen::TensorAssignOp<Eigen::TensorMap<Eigen::Tensor<float, 4, 1, long>, 16, Eigen::MakePointer>, Eigen::TensorReshapingOp<Eigen::DSizes<long, 4> const, Eigen::TensorContractionOp<Eigen::array<Eigen::IndexPair<long>, 1ul> const, Eigen::TensorReshapingOp<Eigen::DSizes<long, 2> const, Eigen::TensorImagePatchOp<-1l, -1l, Eigen::TensorMap<Eigen::Tensor<float const, 4, 1, long>, 16, Eigen::MakePointer> const> const> const, Eigen::TensorReshapingOp<Eigen::DSizes<long, 2> const, Eigen::TensorMap<Eigen::Tensor<float const, 4, 1, long>, 16, Eigen::MakePointer> const> const, tensorflow::BiasAddOutputKernel<float, tensorflow::Relu> const> const> const> const, Eigen::ThreadPoolDevice, true, (Eigen::internal::TiledEvaluation)0>::run(Eigen::TensorAssignOp<Eigen::TensorMap<Eigen::Tensor<float, 4, 1, long>, 16, Eigen::MakePointer>, Eigen::TensorReshapingOp<Eigen::DSizes<long, 4> const, Eigen::TensorContractionOp<Eigen::array<Eigen::IndexPair<long>, 1ul> const, Eigen::TensorReshapingOp<Eigen::DSizes<long, 2> const, Eigen::TensorImagePatchOp<-1l, -1l, Eigen::TensorMap<Eigen::Tensor<float const, 4, 1, long>, 16, Eigen::MakePointer> const> const> const, Eigen::TensorReshapingOp<Eigen::DSizes<long, 2> const, Eigen::TensorMap<Eigen::Tensor<float const, 4, 1, long>, 16, Eigen::MakePointer> const> const, tensorflow::BiasAddOutputKernel<float, tensorflow::Relu> const> const> const> const&, Eigen::ThreadPoolDevice const&) [119]')
assert(n)

parser = argparse.ArgumentParser()

parser.add_argument('--old', type=str,
            help="old igprof text report file")
parser.add_argument('--new', type=str,
            help="new igprof text report file")

args = parser.parse_args()


columnlist=[]
dfcontent=[]
alldfcontents=[]
contents = []
inCumlBlock=False
cumulative_marker='----------------------------------------------------------------------'

with open(args.new) as f:
    for line in f:
        if inCumlBlock:
            if line.strip() == cumulative_marker:
                inCumlBlock = False
                break
            else:
                m=re_cumulative.match(line)
                if m:
                    dfcontent=[]
                    for grp in m.groups():
                        dfcontent.append(grp.strip())
                    alldfcontents.append(dfcontent)
        elif line.strip() == cumulative_marker:
            inCumlBlock=True


columnlist=['% total', 'Self',  'Function', 'Index']

new_df=pd.DataFrame(columns=columnlist, data=alldfcontents)


### old parsing
with open(args.old) as f:
    for line in f:
        if inCumlBlock:
            if line.strip() == cumulative_marker:
                inCumlBlock = False
                break
            else:
                m=re_cumulative.match(line)
                if m:
                    dfcontent=[]
                    for grp in m.groups():
                        dfcontent.append(grp.strip())
                    alldfcontents.append(dfcontent)
        elif line.strip() == cumulative_marker:
            inCumlBlock=True
columnlist=['% total', 'Self',  'Function', 'Index']

old_df=pd.DataFrame(columns=columnlist, data=alldfcontents)

total = columnlist[0]
comul = columnlist[1]
rank  = columnlist[3]


old_df[comul] = old_df[comul].str.replace("'",'').astype('float')
new_df[comul] = new_df[comul].str.replace("'",'').astype('float')


### step2

old_df_for_str2  = old_df.dropna()
indexes_for_str2 = old_df['Function'].str.contains('doEvent').dropna()
list_str2 = old_df_for_str2[indexes_for_str2]['Function'].values.tolist()

columnlist=['Rank', 'PercentageTotal', 'SelfTotal', 'SelfCumulative', 'ChildrenCumulative', 'Function']
cnt=0 # cnt for print different str2 initialzed info
global_old_df = pd.DataFrame(columns=columnlist)
global_new_df = pd.DataFrame(columns=columnlist)

self_marker='- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'

re_selftime=re.compile(r"(\[\d+\])\s*((\d+['])?\d+\.?\d+)\s*((\d+['])?\d+\.?\d+)\s*((\d+['])?\d+\.?\d+)\s/\s((\d+['])?\d+\.?\d+)\s*(.*)")
m=re_selftime.match('[19]        9.8     254.59       0.12 / 254.47     TrackstersProducer::produce(edm::Event&, edm::EventSetup const&)')
#print(displaymatch(m))
assert(m)
re_parentfunc=re.compile(r"(\s*)((\d+['])?\d+\.?\d+)\s*(.........)\s*((\d+['])?\d+\.?\d+)\s/\s((\d+['])?\d+\.?\d+)\s*(.*)\s*(\[\d+\])")
n=re_parentfunc.match("            4.9  .........     127.31 / 2'361.48     edm::stream::EDProducerAdaptorBase::doEvent(edm::EventPrincipal const&, edm::EventSetupImpl const&, edm::ActivityRegistry*, edm::ModuleCallingContext const*) [15]")
#print(displaymatch(n))
assert(n)
o=re_selftime.match("[1]       100.0   2'597.60       0.00 / 2'597.60   <spontaneous>\n")
#print(displaymatch(o))
assert(o)

inBlock=False
parentSeen=False
alldfcontents=[]
with open(args.old) as f:
    for line in f:
        if inBlock:
            n=re_parentfunc.match(line.strip())
            if n and not parentSeen:
                dfcontent=[n.groups()[9],n.groups()[1],n.groups()[2],n.groups()[4],n.groups()[6],n.groups()[8].strip()]
                alldfcontents.append(dfcontent)
                parentSeen=n.groups()[8].strip()
            m=re_selftime.match(line.strip())
            if m and parentSeen in list_str2:
                dfcontent=[m.groups()[0],m.groups()[1],m.groups()[3],m.groups()[5],m.groups()[7],m.groups()[9].strip()]
                alldfcontents.append(dfcontent)
            if line.strip() == self_marker:
                parentSeen=False
            if line.strip() == 'Rank    % total       Self       Self / Children   Function':
                parentSeen=True

        elif line.strip() == self_marker:
            inBlock=True
            parentSeen=False
            

old_str2_df = pd.DataFrame(columns=columnlist, data=alldfcontents)
old_str2_df = old_str2_df.dropna()

inBlock=False
parentSeen=False
alldfcontents=[]
with open(args.new) as f:
    for line in f:
        if inBlock:
            n=re_parentfunc.match(line.strip())
            if n and not parentSeen:
                dfcontent=[n.groups()[9],n.groups()[1],n.groups()[2],n.groups()[4],n.groups()[6],n.groups()[8].strip()]
                parentSeen = n.groups()[8].strip()
            m=re_selftime.match(line.strip())
            if m and parentSeen in list_str2:
                dfcontent=[m.groups()[0],m.groups()[1],m.groups()[3],m.groups()[5],m.groups()[7],m.groups()[9].strip()]
                alldfcontents.append(dfcontent)
            if line.strip() == self_marker:
                parentSeen=False
            if line.strip() == 'Rank    % total       Self       Self / Children   Function':
                parentSeen=True
        elif line.strip() == self_marker:
            inBlock = True
            parentSeen = False

new_str2_df = pd.DataFrame(columns=columnlist, data=alldfcontents)
new_str2_df = new_str2_df.dropna()

#for str2 in list_str2:
#    stIdx_new	= new_str2_df.loc[new_str2_df['Function'] == str2].index[0] -1
#    new_str2_df = new_str2_df[stIdx_new:]

global_old_df = pd.concat([global_old_df,old_str2_df],ignore_index=True)
global_new_df = pd.concat([global_new_df,new_str2_df],ignore_index=True)

global_old_df['PercentageTotal'] =global_old_df['PercentageTotal'].astype('float')
global_new_df['PercentageTotal'] =global_new_df['PercentageTotal'].astype('float')
	
global_old_df['SelfTotal'] =global_old_df['SelfTotal'].str.replace("'",'').astype('float')
global_new_df['SelfTotal'] =global_new_df['SelfTotal'].str.replace("'",'').astype('float')

global_old_df['SelfCumulative'] =global_old_df['SelfCumulative'].str.replace("'",'').astype('float')
global_new_df['SelfCumulative'] =global_new_df['SelfCumulative'].str.replace("'",'').astype('float')

global_old_df['ChildrenCumulative'] =global_old_df['ChildrenCumulative'].str.replace(",",'').astype('float')
global_new_df['ChildrenCumulative'] =global_new_df['ChildrenCumulative'].str.replace(",",'').astype('float')

global_old_df = global_old_df.sort_values(by=['PercentageTotal'],axis=0,ascending=False)
global_new_df = global_new_df.sort_values(by=['PercentageTotal'],axis=0,ascending=False)

global_old_df = global_old_df.reset_index(drop=True)
global_new_df = global_new_df.reset_index(drop=True)

sorted_df = global_old_df


Tot_strs  = sorted_df['Function']

oldAll_=list(old_df[old_df['Function']=="<spontaneous>"][comul])
if oldAll_:
	oldAll=list(old_df.loc[old_df['Function']=="<spontaneous>"][comul])[0]
	newAll=list(old_df.loc[old_df['Function']=="<spontaneous>"][comul])[1]
elif newAll_:
	oldAll=list(new_df.loc[new_df['Function']=="<spontaneous>"][comul])[0]
	newAll=list(new_df.loc[new_df['Function']=="<spontaneous>"][comul])[0]
	


print("==================================================================================================================================================================================")
print("Rank			Total%	 		Cumulative					Delta						Symbol name")
print("==================================================================================================================================================================================")


oldVal_sum=0
newVal_sum=0

for Tot_str in Tot_strs:
	idx_new = global_new_df.loc[global_new_df['Function']==Tot_str].index
	idx_old = global_old_df.loc[global_old_df['Function']==Tot_str].index
	
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
	
	oldVal=global_old_df.loc[idx_old[0]]["SelfTotal"]
	newVal=global_new_df.loc[idx_new[0]]["SelfTotal"]
        #print(oldVal, newVal)	
	oldVal_sum += oldVal
	newVal_sum += newVal
	
	delta	  = round((newVal/newAll - oldVal/oldAll) * 100.0,2)	
	#delta_sum = round((newVal_sum - oldVal_sum) / oldAll * 100.0,2)	

	print("[{0:<4} -> {1:<4}] [{2:<6} -> {3:<6}]  [{4:<9} -> {5:<9}]         [ {6:<9}/{7:<9} - {8:<9}/{9:<9} *100% ] = [{10:<6}% ]         {11:<50}".format(idx_old[0],idx_new[0], global_old_df.loc[idx_old[0]]['PercentageTotal'],global_new_df.loc[idx_new[0]]['PercentageTotal'],global_old_df.loc[idx_old[0]]['SelfTotal'],global_new_df.loc[idx_new[0]]['SelfTotal'],newVal,newAll,oldVal,oldAll,delta,out_name))


print("\n")

print(">> Total Cumulative(old->new): {0:<5} -> {1:<5}".format(oldVal_sum,newVal_sum))


print(" ")















