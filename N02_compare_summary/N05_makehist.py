
#######################################################
## First, run N02 using mode 2 and generate file1,file2
######################################################

# -------------- Load files

evt_list=[]
time_list=[]
VSIZE_list=[]
RSS_list=[]
column=[]

file1='SUM_CMSSW_11_0_0_pre1.txt'
file2='SUM_CMSSW_11_0_0_pre6.txt'
file3='SUM_CMSSW_11_0_0_pre2.txt'

print("Load files")
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
		#print('evt',list_line[10])
		#print('time',list_line[12])
		#print('VSIZE',list_line[4])
		#print('RSS',list_line[7])

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
		#print(list_line)


evt_list3=[]
time_list3=[]
VSIZE_list3=[]
RSS_list3=[]
column=[]

with open(file3) as f:
	for line in f:
		line=line.strip()
		#print(line)
		list_line1=line.split()
		
		nextline=next(f)
		nextline=nextline.strip()
		#print(nextline)
		list_line2=nextline.split()
		list_line= list_line1 + list_line2

		evt_list3.append(list_line[10])
		time_list3.append(list_line[12])
		VSIZE_list3.append(list_line[4])
		RSS_list3.append(list_line[7])
		#print(list_line)



# --------------Define Hist variables
def sort_obj(evt_list,obj_list):
	hist = zip(evt_list,obj_list)
	hist = sorted(hist)
	return zip(*hist)


evt_list	= list(map(float,evt_list))
time_list	= list(map(float,time_list))
VSIZE_list	= list(map(float,VSIZE_list))
RSS_list	= list(map(float,RSS_list))
_,time_list  = sort_obj(evt_list,time_list)
_,VSIZE_list = sort_obj(evt_list,VSIZE_list)
evt_list,RSS_list	 = sort_obj(evt_list,RSS_list)



evt_list2=list(map(float,evt_list2))
time_list2 =list(map(float,time_list2))
VSIZE_list2=list(map(float,VSIZE_list2))
RSS_list2=list(map(float,RSS_list2))
_,time_list2  = sort_obj(evt_list2,time_list2)
_,VSIZE_list2 = sort_obj(evt_list2,VSIZE_list2)
evt_list2,RSS_list2	  = sort_obj(evt_list2,RSS_list2)

evt_list3=list(map(float,evt_list3))
time_list3 =list(map(float,time_list3))
VSIZE_list3=list(map(float,VSIZE_list3))
RSS_list3=list(map(float,RSS_list3))
_,time_list3  = sort_obj(evt_list3,time_list3)
_,VSIZE_list3 = sort_obj(evt_list3,VSIZE_list3)
evt_list3,RSS_list3	  = sort_obj(evt_list3,RSS_list3)

# -------------- Make plots


print("Makes plots")
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy

plt.rc('xtick',labelsize=20)
plt.rc('ytick',labelsize=20)


print("Evt after map distribution ####")
print("### X1 ###")
print(evt_list)
print("### Y1 ###")
print(RSS_list)
print("### X2 ###")
print(evt_list2)
print("### Y2 ###")
print(RSS_list2)


fig,axs = plt.subplots(2,3,figsize=(30,20))
axs[0,0].plot(evt_list,RSS_list,'-o',color='r',alpha=0.7)
axs[0,0].plot(evt_list2,RSS_list2,'-o')
axs[0,0].plot(evt_list3,RSS_list3,'-o',color='g',alpha=0.7)
axs[0,0].set_title('(RSS)Memory Profile',fontsize=30)
axs[0,0].set_xlim([0,101])
axs[0,0].set_ylim([2000,6000])
axs[0,0].set_xlabel('ith event',fontsize=25)
axs[0,0].set_ylabel('Memory(MB)',fontsize=25)
axs[0,0].legend(['CMSSW_11_0_0_pre1','CMSSW_11_0_0_pre6','CMSSW_11_0_0_pre2'],prop={'size' :20})


axs[0,1].plot(evt_list,VSIZE_list,'-o',color='r',alpha=0.7)
axs[0,1].plot(evt_list2,VSIZE_list2,'-o')
axs[0,1].plot(evt_list3,VSIZE_list3,'-o',color='g',alpha=0.7)
axs[0,1].set_title('(VSIZE)Memory Profile',fontsize=30)
axs[0,1].set_xlim([0,101])
axs[0,1].set_xlabel('ith event',fontsize=25)
axs[0,1].set_ylabel('Memory(MB)',fontsize=25)


axs[0,2].plot(evt_list,time_list,'-o',color='r',alpha=0.7)
axs[0,2].plot(evt_list2,time_list2,'-o')
axs[0,2].plot(evt_list3,time_list3,'-o',color='g',alpha=0.7)
axs[0,2].set_title('CPU Time Profile',fontsize=30)
axs[0,2].set_xlim([0,101])
#axs[0,2].set_yscale('log')
axs[0,2].set_xlabel('ith event',fontsize=25)
axs[0,2].set_ylabel('time (seconds)',fontsize=25)




bins = numpy.linspace(3500,5000,100)
axs[1,0].hist(RSS_list,bins=bins,color='r',alpha=0.7)
axs[1,0].hist(RSS_list2,bins=bins,color='b',alpha=0.7)
axs[1,0].hist(RSS_list3,bins=bins,color='g',alpha=0.7)
axs[1,0].set_title('(RSS)Memory Profile',fontsize=30)
axs[1,0].set_ylabel('ith event',fontsize=25)
axs[1,0].set_xlabel('Memory(MB)',fontsize=25)

bins = numpy.linspace(5000,8000,100)
axs[1,1].get_xaxis().get_major_formatter().set_useOffset(False)
axs[1,1].hist(VSIZE_list2,bins=bins,color='b',alpha=0.7)
axs[1,1].hist(VSIZE_list,bins=bins,color='r',alpha=0.7)
axs[1,1].hist(VSIZE_list3,bins=bins,color='g',alpha=0.7)
axs[1,1].set_title('(VSIZE)Memory Profile',fontsize=30)
axs[1,1].set_ylabel('ith event',fontsize=25)
axs[1,1].set_xlabel('Memory(MB)',fontsize=25)
axs[1,1].ticklabel_format(useOffset=False)

bins = numpy.linspace(0,1500,100)
axs[1,2].hist(time_list,bins=bins,color='r',alpha=0.7)
axs[1,2].hist(time_list2,bins=bins,color='b',alpha=0.7)
axs[1,2].hist(time_list3,bins=bins,color='g',alpha=0.7)
axs[1,2].set_xscale('log')
#axs[1,2].set_yscale('log')
axs[1,2].set_title('CPU Time Profile',fontsize=30)
axs[1,2].set_ylabel('ith event',fontsize=25)
axs[1,2].set_xlabel('time (seconds)',fontsize=25)



plt.tight_layout()
plt.show()
fig = plt.gcf()
plt.savefig('Summary_new.png')



