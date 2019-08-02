
#######################################################
## First, run N02 using mode 2 and generate file1,file2
######################################################

evt_list=[]
time_list=[]
VSIZE_list=[]
RSS_list=[]
column=[]

file1='SUM_CMSSW_10_6_0_pre3.txt'
file2='SUM_CMSSW_10_6_0_pre4.txt'

with open(file1) as f:
	for line in f:
		line=line.strip()
		#print(line)
		list_line1=line.split()
		
		nextline=next(f)
		nextline=nextline.strip()
		#print(nextline)
		list_line2=nextline.split()
		list_line= list_line1 + list_line2

		evt_list.append(list_line[10])
		time_list.append(list_line[12])
		VSIZE_list.append(list_line[4])
		RSS_list.append(list_line[7])
		print(list_line)

evt_list2=[]
time_list2=[]
VSIZE_list2=[]
RSS_list2=[]
column=[]

with open(file2) as f:
	for line in f:
		line=line.strip()
		#print(line)
		list_line1=line.split()
		
		nextline=next(f)
		nextline=nextline.strip()
		#print(nextline)
		list_line2=nextline.split()
		list_line= list_line1 + list_line2

		evt_list2.append(list_line[10])
		time_list2.append(list_line[12])
		VSIZE_list2.append(list_line[4])
		RSS_list2.append(list_line[7])
		print(list_line)

#print('evt:')
#print(evt_list2)
#print('time:')
#print(time_list2)
#print('VSIE:')
#print(VSIZE_list2)
#print('RSS:')
#print(RSS_list2)


import matplotlib
import matplotlib.pyplot as plt
matplotlib.use('Agg')
fig,axs = plt.subplots(2,3,figsize=(18,9))

axs[0,0].plot(evt_list,RSS_list,'o',color='r',alpha=0.7)
axs[0,0].plot(evt_list2,RSS_list2,'o')
axs[0,0].set_title('(RSS)Memory Profile')
axs[0,0].set_xlim([0,11])
axs[0,0].set_xlabel('ith event')
axs[0,0].set_ylabel('Memory(MB)')
axs[0,0].legend(['CMSSW_10_6_0_pre3','CMSSW_10_6_0_pre4'])

axs[0,1].plot(evt_list,VSIZE_list,'o',color='r',alpha=0.7)
axs[0,1].plot(evt_list2,VSIZE_list2,'o')
axs[0,1].set_title('(VSIZE)MEmory Profile')
axs[0,1].set_xlim([0,11])
axs[0,1].set_xlabel('ith event')
axs[0,1].set_ylabel('Memory(MB)')

axs[0,2].plot(evt_list,time_list,'o',color='r',alpha=0.7)
axs[0,2].plot(evt_list2,time_list2,'o')
axs[0,2].set_title('CPU Time Profile')
axs[0,2].set_xlim([0,11])
axs[0,2].set_xlabel('ith event')
axs[0,2].set_ylabel('time (seconds)')

axs[1,0].plot(RSS_list,evt_list,'o',color='r',alpha=0.7)
axs[1,0].plot(RSS_list2,evt_list2,'o')
axs[1,0].set_title('(RSS)Memory Profile')
axs[1,0].set_ylim([0,11])
axs[1,0].set_ylabel('ith event')
axs[1,0].set_xlabel('Memory(MB)')

axs[1,1].plot(VSIZE_list,evt_list,'o',color='r',alpha=0.7)
axs[1,1].plot(VSIZE_list2,evt_list2,'o')
axs[1,1].set_title('(VSIZE)MEmory Profile')
axs[1,1].set_ylim([0,11])
axs[1,1].set_ylabel('ith event')
axs[1,1].set_xlabel('Memory(MB)')

axs[1,2].plot(time_list,evt_list,'o',color='r',alpha=0.7)
axs[1,2].plot(time_list2,evt_list2,'o')
axs[1,2].set_title('CPU Time Profile')
axs[1,2].set_ylim([0,11])
axs[1,2].set_ylabel('ith event')
axs[1,2].set_xlabel('time (seconds)')


plt.tight_layout()




plt.savefig('Summary.png')


