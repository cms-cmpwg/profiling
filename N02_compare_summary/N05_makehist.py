
#######################################################
## First, run N02 using mode 2 and generate file1,file2
######################################################

# -------------- Load files

evt_list=[]
time_list=[]
VSIZE_list=[]
RSS_list=[]
column=[]

file1 ='SUM_CMSSW_11_0_0_pre1.txt'
file2 ='SUM_CMSSW_11_0_0_pre2.txt'
file3 ='SUM_CMSSW_11_0_0_pre3.txt'
file4 ='SUM_CMSSW_11_0_0_pre4.txt'
file5 ='SUM_CMSSW_11_0_0_pre5.txt'
file6 ='SUM_CMSSW_11_0_0_pre6.txt'
file7 ='SUM_CMSSW_11_0_0_pre7.txt'
file8 ='SUM_CMSSW_11_0_0_pre8.txt'
file9 ='SUM_CMSSW_11_0_0_pre9.txt'
file10='SUM_CMSSW_11_0_0_pre10.txt'
file11='SUM_CMSSW_11_0_0_pre11.txt'

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

evt_list4=[]
time_list4=[]
VSIZE_list4=[]
RSS_list4=[]
column=[]

with open(file4) as f:
	for line in f:
		line=line.strip()
		#print(line)
		list_line1=line.split()
		
		nextline=next(f)
		nextline=nextline.strip()
		#print(nextline)
		list_line2=nextline.split()
		list_line= list_line1 + list_line2

		evt_list4.append(list_line[10])
		time_list4.append(list_line[12])
		VSIZE_list4.append(list_line[4])
		RSS_list4.append(list_line[7])
		#print(list_line)

evt_list5=[]
time_list5=[]
VSIZE_list5=[]
RSS_list5=[]
column=[]

with open(file5) as f:
	for line in f:
		line=line.strip()
		#print(line)
		list_line1=line.split()
		
		nextline=next(f)
		nextline=nextline.strip()
		#print(nextline)
		list_line2=nextline.split()
		list_line= list_line1 + list_line2

		evt_list5.append(list_line[10])
		time_list5.append(list_line[12])
		VSIZE_list5.append(list_line[4])
		RSS_list5.append(list_line[7])
		#print(list_line)


evt_list6=[]
time_list6=[]
VSIZE_list6=[]
RSS_list6=[]
column=[]

with open(file6) as f:
	for line in f:
		line=line.strip()
		#print(line)
		list_line1=line.split()
		
		nextline=next(f)
		nextline=nextline.strip()
		#print(nextline)
		list_line2=nextline.split()
		list_line= list_line1 + list_line2

		evt_list6.append(list_line[10])
		time_list6.append(list_line[12])
		VSIZE_list6.append(list_line[4])
		RSS_list6.append(list_line[7])
		#print(list_line)



evt_list7=[]
time_list7=[]
VSIZE_list7=[]
RSS_list7=[]
column=[]

with open(file7) as f:
	for line in f:
		line=line.strip()
		#print(line)
		list_line1=line.split()
		
		nextline=next(f)
		nextline=nextline.strip()
		#print(nextline)
		list_line2=nextline.split()
		list_line= list_line1 + list_line2

		evt_list7.append(list_line[10])
		time_list7.append(list_line[12])
		VSIZE_list7.append(list_line[4])
		RSS_list7.append(list_line[7])
		#print(list_line)


evt_list8=[]
time_list8=[]
VSIZE_list8=[]
RSS_list8=[]
column=[]

with open(file8) as f:
	for line in f:
		line=line.strip()
		#print(line)
		list_line1=line.split()
		
		nextline=next(f)
		nextline=nextline.strip()
		#print(nextline)
		list_line2=nextline.split()
		list_line= list_line1 + list_line2

		evt_list8.append(list_line[10])
		time_list8.append(list_line[12])
		VSIZE_list8.append(list_line[4])
		RSS_list8.append(list_line[7])
		#print(list_line)

evt_list9=[]
time_list9=[]
VSIZE_list9=[]
RSS_list9=[]
column=[]

with open(file9) as f:
	for line in f:
		line=line.strip()
		#print(line)
		list_line1=line.split()
		
		nextline=next(f)
		nextline=nextline.strip()
		#print(nextline)
		list_line2=nextline.split()
		list_line= list_line1 + list_line2

		evt_list9.append(list_line[10])
		time_list9.append(list_line[12])
		VSIZE_list9.append(list_line[4])
		RSS_list9.append(list_line[7])
		#print(list_line)

evt_list10=[]
time_list10=[]
VSIZE_list10=[]
RSS_list10=[]
column=[]

with open(file10) as f:
	for line in f:
		line=line.strip()
		#print(line)
		list_line1=line.split()
		
		nextline=next(f)
		nextline=nextline.strip()
		#print(nextline)
		list_line2=nextline.split()
		list_line= list_line1 + list_line2

		evt_list10.append(list_line[10])
		time_list10.append(list_line[12])
		VSIZE_list10.append(list_line[4])
		RSS_list10.append(list_line[7])
		#print(list_line)


evt_list11=[]
time_list11=[]
VSIZE_list11=[]
RSS_list11=[]
column=[]

with open(file11) as f:
	for line in f:
		line=line.strip()
		#print(line)
		list_line1=line.split()
		
		nextline=next(f)
		nextline=nextline.strip()
		#print(nextline)
		list_line2=nextline.split()
		list_line= list_line1 + list_line2

		evt_list11.append(list_line[10])
		time_list11.append(list_line[12])
		VSIZE_list11.append(list_line[4])
		RSS_list11.append(list_line[7])
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

evt_list4=list(map(float,evt_list4))
time_list4 =list(map(float,time_list4))
VSIZE_list4=list(map(float,VSIZE_list4))
RSS_list4=list(map(float,RSS_list4))
_,time_list4  = sort_obj(evt_list4,time_list4)
_,VSIZE_list4 = sort_obj(evt_list4,VSIZE_list4)
evt_list4,RSS_list4	  = sort_obj(evt_list4,RSS_list4)

evt_list5=list(map(float,evt_list5))
time_list5 =list(map(float,time_list5))
VSIZE_list5=list(map(float,VSIZE_list5))
RSS_list5=list(map(float,RSS_list5))
_,time_list5  = sort_obj(evt_list5,time_list5)
_,VSIZE_list5 = sort_obj(evt_list5,VSIZE_list5)
evt_list5,RSS_list5	  = sort_obj(evt_list5,RSS_list5)

evt_list6=list(map(float,evt_list6))
time_list6 =list(map(float,time_list6))
VSIZE_list6=list(map(float,VSIZE_list6))
RSS_list6=list(map(float,RSS_list6))
_,time_list6  = sort_obj(evt_list6,time_list6)
_,VSIZE_list6 = sort_obj(evt_list6,VSIZE_list6)
evt_list6,RSS_list6	  = sort_obj(evt_list6,RSS_list6)

evt_list7=list(map(float,evt_list7))
time_list7 =list(map(float,time_list7))
VSIZE_list7=list(map(float,VSIZE_list7))
RSS_list7=list(map(float,RSS_list7))
_,time_list7  = sort_obj(evt_list7,time_list7)
_,VSIZE_list7 = sort_obj(evt_list7,VSIZE_list7)
evt_list7,RSS_list7	  = sort_obj(evt_list7,RSS_list7)

evt_list8=list(map(float,evt_list8))
time_list8 =list(map(float,time_list8))
VSIZE_list8=list(map(float,VSIZE_list8))
RSS_list8=list(map(float,RSS_list8))
_,time_list8  = sort_obj(evt_list8,time_list8)
_,VSIZE_list8 = sort_obj(evt_list8,VSIZE_list8)
evt_list8,RSS_list8	  = sort_obj(evt_list8,RSS_list8)

evt_list9=list(map(float,evt_list9))
time_list9 =list(map(float,time_list9))
VSIZE_list9=list(map(float,VSIZE_list9))
RSS_list9=list(map(float,RSS_list9))
_,time_list9  = sort_obj(evt_list9,time_list9)
_,VSIZE_list9 = sort_obj(evt_list9,VSIZE_list9)
evt_list9,RSS_list9	  = sort_obj(evt_list9,RSS_list9)

evt_list10=list(map(float,evt_list10))
time_list10 =list(map(float,time_list10))
VSIZE_list10=list(map(float,VSIZE_list10))
RSS_list10=list(map(float,RSS_list10))
_,time_list10  = sort_obj(evt_list10,time_list10)
_,VSIZE_list10 = sort_obj(evt_list10,VSIZE_list10)
evt_list10,RSS_list10	  = sort_obj(evt_list10,RSS_list10)

evt_list11=list(map(float,evt_list11))
time_list11 =list(map(float,time_list11))
VSIZE_list11=list(map(float,VSIZE_list11))
RSS_list11=list(map(float,RSS_list11))
_,time_list11  = sort_obj(evt_list11,time_list11)
_,VSIZE_list11 = sort_obj(evt_list11,VSIZE_list11)
evt_list11,RSS_list11	  = sort_obj(evt_list11,RSS_list11)




# -------------- Make plots


print("Makes plots")
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy

plt.rc('xtick',labelsize=20)
plt.rc('ytick',labelsize=20)


print("Evt after map distribution ####")
print("### Y3 ###")




## RSS
fig,axs = plt.subplots(2,3,figsize=(30,20))
axs[0,0].plot(evt_list,RSS_list,'-o',color='r',alpha=0.7)
axs[0,0].plot(evt_list2,RSS_list2,'-o',color='green')
axs[0,0].plot(evt_list3,RSS_list3,'-o',color='blue')
axs[0,0].plot(evt_list4,RSS_list4,'-o',color='orange')

axs[0,0].set_title('Top 4 (RSS)Memory Profile',fontsize=30)
#axs[0,0].set_title('(RSS)Memory Profile',fontsize=30)
axs[0,0].set_xlim([0,101])
axs[0,0].set_ylim([3000,7000])
axs[0,0].set_xlabel('ith event',fontsize=25)
axs[0,0].set_ylabel('Memory(MB)',fontsize=25)

axs[0,0].legend(['CMSSW_11_0_0_pre1','CMSSW_11_0_0_pre2','CMSSW_11_0_0_pre3','CMSSW_11_0_0_pre4'],prop={'size' :20})
#axs[0,0].legend(['CMSSW_11_0_0_pre9','CMSSW_11_0_0_pre10','CMSSW_11_0_0_pre11'],prop={'size' :20})
axs[0,0].grid()

## Vsize
axs[0,1].plot(evt_list,VSIZE_list,'-o',color='r',alpha=0.7)
axs[0,1].plot(evt_list2,VSIZE_list2,'-o',color='green')
axs[0,1].plot(evt_list3,VSIZE_list3,'-o',color='blue')
axs[0,1].plot(evt_list8,VSIZE_list8,'-o',color='orange')

axs[0,1].set_title('Top 4 (VSIZE)Memory Profile',fontsize=30)
#axs[0,1].set_title('(VSIZE)Memory Profile',fontsize=30)
axs[0,1].set_xlim([0,101])
axs[0,1].set_ylim([4000,9000])
axs[0,1].set_xlabel('ith event',fontsize=25)
axs[0,1].set_ylabel('Memory(MB)',fontsize=25)
axs[0,1].legend(['CMSSW_11_0_0_pre1','CMSSW_11_0_0_pre2','CMSSW_11_0_0_pre3','CMSSW_11_0_0_pre8'],prop={'size' :20})
#axs[0,1].legend(['CMSSW_11_0_0_pre9','CMSSW_11_0_0_pre10','CMSSW_11_0_0_pre11'],prop={'size' :20})
axs[0,1].grid()

# Time
axs[0,2].plot(evt_list,time_list,'-o',color='r',alpha=0.7)
axs[0,2].plot(evt_list2,time_list2,'-o',color='green')
axs[0,2].plot(evt_list5,time_list5,'-o',color='b')
axs[0,2].plot(evt_list8,time_list8,'-o',color='orange')

axs[0,2].set_title('Top 4 average CPU Time Profile',fontsize=30)
#axs[0,2].set_title('average CPU Time Profile',fontsize=30)
axs[0,2].set_xlim([0,101])
#axs[0,2].set_yscale('log')
axs[0,2].set_xlabel('ith event',fontsize=25)
axs[0,2].set_ylabel('time (seconds)',fontsize=25)
axs[0,2].legend(['CMSSW_11_0_0_pre1','CMSSW_11_0_0_pre2','CMSSW_11_0_0_pre5','CMSSW_11_0_0_pre8'],prop={'size' :20})
#axs[0,2].legend(['CMSSW_11_0_0_pre9','CMSSW_11_0_0_pre10','CMSSW_11_0_0_pre11'],prop={'size' :20})
axs[0,2].grid()


## RSS
bins = numpy.linspace(3000,7000,100)
axs[1,0].hist(RSS_list,bins=bins,color='r',alpha=0.9)
axs[1,0].hist(RSS_list2,bins=bins,color='g',alpha=0.9)
axs[1,0].hist(RSS_list3,bins=bins,color='b',alpha=0.9)
axs[1,0].hist(RSS_list4,bins=bins,color='orange',alpha=0.9)
axs[1,0].set_yscale('log')
axs[1,0].set_title('(RSS)Memory Profile',fontsize=30)
axs[1,0].set_ylabel('ith event',fontsize=25)
axs[1,0].set_xlabel('Memory(MB)',fontsize=25)
axs[1,0].grid()

## Vsize
bins = numpy.linspace(4000,9000,100)
axs[1,1].get_xaxis().get_major_formatter().set_useOffset(False)
axs[1,1].hist(VSIZE_list,bins=bins,color='r',alpha=0.9)
axs[1,1].hist(VSIZE_list2,bins=bins,color='g',alpha=0.9)
axs[1,1].hist(VSIZE_list3,bins=bins,color='b',alpha=0.9)
axs[1,1].hist(VSIZE_list8,bins=bins,color='orange',alpha=0.9)
axs[1,1].set_title('(VSIZE)Memory Profile',fontsize=30)
axs[1,1].set_ylabel('ith event',fontsize=25)
axs[1,1].set_xlabel('Memory(MB)',fontsize=25)
axs[1,1].ticklabel_format(useOffset=False)
axs[1,1].grid()

## Time
bins = numpy.linspace(0,2000,100)
axs[1,2].hist(time_list,bins=bins,color='r',alpha=0.9)
axs[1,2].hist(time_list2,bins=bins,color='g',alpha=0.9)
axs[1,2].hist(time_list5,bins=bins,color='b',alpha=0.9)
axs[1,2].hist(time_list8,bins=bins,color='orange',alpha=0.9)
axs[1,2].set_xscale('log')
#axs[1,2].set_yscale('log')
axs[1,2].set_title('CPU Time Profile',fontsize=30)
axs[1,2].set_ylabel('ith event',fontsize=25)
axs[1,2].set_xlabel('time (seconds)',fontsize=25)
axs[1,2].grid()



plt.tight_layout()
plt.show()
fig = plt.gcf()
plt.savefig('SummaryStep3.png')



