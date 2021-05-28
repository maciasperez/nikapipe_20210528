#
import read_nika_data as rnd
import matplotlib.pyplot as plt
import plot_nika_toi as pnt
import numpy as np
import power_spectrum as pws
# data from Martino

## DATA FROM 
file ="/Users/macias/NIKAdocuments/dataAMC_vs_USB/20151104/X_2015_11_04_16h30m12_A0_balayage_NIKELRF_allPixs_56dbm_ADC35_dac33446_tone4_attInj2_20dBonCryoIn_mes22_ADC33"


file='/Users/macias/NIKAdocuments/dataAMC_vs_USB/20151104/X_2015_11_04_17h30m35_A0_balayage_NIKELUSB_allPixs_56dbm_ADC35_dac2020202535_tone3_ADC33_b'


silent = 0

list_data='retard 0 sample I  RF_didq F_tone DF_tone k_flag'

data =  rnd.read_nika_data(file,silent,list_data)


print 'Total number of samples read %d \n' %(data.nb_samples)



print 'Common data : '
print data.name_data_c
print 'Detector data'
print data.name_data_d



sample = rnd.get_nikavar_data(data,'sample')
rfdidq = rnd.get_nikavar_data(data,'RF_didq')

nkids, nsamples = rfdidq.shape

#check if we have problems with some of the pixels !!!
# This is mainly for lab data
okpix = []
for ikid in range(nkids):
    if (rfdidq[ikid,:].min() != rfdidq[ikid,:].max()):
        okpix.append(ikid)

print  "We find ", len(okpix), " good detectors"

# Select main data
mdata = rfdidq[np.array(okpix),0:data.nb_samples]

pnt.plot_nika_toi(sample,mdata)


begidx = 18
show_ps(mdata,timet=None, sampfreq=1.0)

plt.figure()
plt.xlabel ='Sample'
plt.ylabel ='RF_DIDQ'

for idx in range(okpix[0].size-1):
    pos = okpix[0][idx]
    plt.plot(sample,mdata[idx,0:]-np.median(mdata[idx,100:]))


plt.show()


#plt.plot()



