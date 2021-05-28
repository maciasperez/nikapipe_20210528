#
import numpy as np
import matplotlib.pylab as plt
import scan2run as s2r
import read_nika_data as rnd
#import kidreso as kr


file ="/home/nika2/NIKA/Data/run13_X/scan_24X/X_2015_10_23_A0_0074"
file ="/home/nika2/NIKA/Data/run14_X/X24_2015_11_29/X_2015_11_29_00h56m20_A0_0011_L_0820+560"

file = "/Users/macias/NIKA/Data/Raw_data/X_2016_09_25_20h30m05_AA_0451_P_Neptune"
file ="/home/nika2/NIKA/Data/run18_X/X12_2016_09_25/X_2016_09_25_20h30m05_AA_0451_P_Neptune"
#file ="/home/nika2/NIKA/Data/run13_X/X24_2015_10_23/X_2015_10_23_23h44m04_A0_0229_P_Uranus"

#file = '/home/nika2/NIKA/Data//run18_X//X36_2016_10_06/X_2016_10_06_21h23m35_AA_0199_O_Uranus'
file = '/home/nika2/NIKA/Data/run18_X/X36_2016_10_06/X_2016_10_06_22h39m01_AA_0201_P_Uranus'
silent = 0

list_data='subscan scan El retard 0 ofs_Az ofs_El Az paral scan_st MJD LST sample I Q dI dQ RF_didq F_tone DF_tone A_masq B_masq k_flag c_position c_synchro A_t_utc B_t_utc antxoffset antyoffset anttrackaz anttrackel'

# IDL COMMAND
#  print, READ_NIKA_BRUTE( file, param_c, kidpar, data, units, list_data=list_data)

scan ='20161026s4'
file =  s2r.scan2rawfile(scan)
data =  rnd.read_nika_data(file,silent=1,det2read = 'KID',list_data=list_data)

# notune pixels
notune_pix= [2172, 2330 ,2430, 2434, 2506 ,3146 ,3610 ,3611 ,3627 ,3771 ,4008, 4017 ,4088 ,4091 ,4109, 4167 ,4179 ,4182, 4351, 4496, 4662 ,4684]

pos = []
for pix in notune_pix:
    pos.append( np.where(data.kidpar['num'] == pix)[0][0])
    
I = rnd.get_nikavar_data(data,'I')

Ftone = rnd.get_nikavar_data(data,'F_tone')
figure(2)
plot(Ftone[pos,:].T)


    
print 'Total number of samples read %d \n' %(data.nb_samples)

print 'KIDPAR NAMES'
name_kidpar_var = data.kidpar['pname']

name_kidpar_var = data.kidpar['pname']
nkidparvar = len(name_kidpar_var)
for index in range(nkidparvar):
    print "NAME VAR", name_kidpar_var[index]
    print "DATA VAR", data.kidpar['pvalue'][index]



print 'Common data : '
print data.name_data_c
print 'Detector data'
print data.name_data_d



posmjd = np.where(data.name_data_c =='MJD')
posmjd = posmjd[0][0]
mjd =  data.data_common[posmjd,0:data.nb_samples]

#plt.plot(mjd-np.median(mjd))
#plt.show()

possam = np.where(data.name_data_c =='sample')
possam = possam[0][0]
sample =  data.data_common[possam,0:data.nb_samples]

possam = np.where(data.name_data_c =='El')
possam = possam[0][0]
el =  data.data_common[possam,0:data.nb_samples]


nb_detectors = data.data_detector.shape[1]
posrf = np.where(data.name_data_d =='RF_didq')
posrf = posrf[0][0]
rfdidq = data.data_detector[posrf,:,:]


posrf = np.where(data.name_data_d =='k_flag')
posrf = posrf[0][0]
kflag = data.data_detector[posrf,:,:]

posrf = np.where(data.name_data_d =='k_width')
posrf = posrf[0][0]
kwidth = data.data_detector[posrf,:,:]

#posrf = np.where(data.name_data_d =='k_angle')
#posrf = posrf[0][0]
#kangle = data.data_detector[posrf,:,:]




posrf = np.where(data.name_data_d =='I')
posrf = posrf[0][0]
I = data.data_detector[posrf,:,:]

posrf = np.where(data.name_data_d =='Q')
posrf = posrf[0][0]
Q = data.data_detector[posrf,0:nb_detectors,0:data.nb_samples]

posrf = np.where(data.name_data_d =='dI')
posrf = posrf[0][0]
dI = data.data_detector[posrf,0:nb_detectors,0:data.nb_samples]

posrf = np.where(data.name_data_d =='dQ')
posrf = posrf[0][0]
dQ = data.data_detector[posrf,0:nb_detectors,0:data.nb_samples]



pos = np.where(np.array(data.kidpar['pname']) =='array')
pos = pos[0][0]
dectarr = np.array(data.kidpar['pvalue'][pos])

pos = np.where(np.array(data.kidpar['pname']) =='type')
pos = pos[0][0]
typearr = np.array(data.kidpar['pvalue'][pos])
# or in one line
typearr = np.array(data.kidpar['pvalue'][ np.where(np.array(data.kidpar['pname']) =='type')[0][0] ])

okpix = np.where(np.logical_and(typearr == 1.0,dectarr == 2.0) ==  True)

mdata = rfdidq[np.array(okpix[0]),0:data.nb_samples]


#I = I[np.array(okpix[0]),0:data.nb_samples]
#Q = Q[np.array(okpix[0]),0:data.nb_samples]
#dI = dI[np.array(okpix[0]),0:data.nb_samples]
#dQ = dQ[np.array(okpix[0]),0:data.nb_samples]





#nkids,nsamples = I.shape
#delta_f=1.0
#kr.kidreso.rf_didq(delta_f,I, Q, dI,dQ, RF)


plt.figure(figsize=(10,10))
ax1=plt.subplot(211)
ax1.xaxis.set_label_text('Sample')
ax1.yaxis.set_label_text('RF_DIDQ')
ax1.plot(rfdidq[13])
#plt.xlim(6500,6700)
#plt.ylim(4350,4500)
plt.grid()

plt.subplot(212)
ax2=plt.plot(I[13,:])
ax2.xaxis.set_label_text('Sample')
ax2.yaxis.set_label_text('I')
#plt.xlim(6500,6700)
#plt.ylim(-4.02e6,-3.95e06)
plt.grid()


#for idx in range(okpix[0].size-1):
#    pos = okpix[0][idx]
#    plt.plot(sample,mdata[idx,0:]-np.median(mdata[idx,100:]))


plt.show()


#plt.plot()



# donnees labo Alessandro
mfile = '/home/macias/Documents/Data/NIKA2Labo/W_2018_05_24_09h36m41_A1_man'
data =  rnd.read_nika_data(file,silent=1,det2read = 'KID',list_data='all',nodata='True')
