
import astropy.io.fits as fits
import matplotlib.pyplot as plt
from read_nika_data import *


file ="/home/nika2/NIKA/Data/run13_X/X24_2015_10_31/X_2015_10_31_22h17m03_A0_0255_P_Uranus"
silent = 1

list_data='subscan scan El retard 0 ofs_Az ofs_El Az paral scan_st MJD LST sample I Q dI dQ RF_didq F_tone DF_tone A_masq B_masq k_flag c_position c_synchro A_t_utc B_t_utc antxoffset antyoffset anttrackaz anttrackel'

data =  read_nika_data(file,silent,list_data)



file = '/home/nika2/NIKA/Data/NIKAIMBFITS/iram30m-NIKA-20151031s255-imb.fits'
hdulist = fits.open(file)

hdulist.info()
#0    PRIMARY     PrimaryHDU      25   ()
#1    IMBF-scan   BinTableHDU    118   1R x 3C      [15A, E, E]
#2    IMBF-frontend  BinTableHDU     22   1R x 2C      [20A, 1D]
#3    IMBF-backend  BinTableHDU     20   1R x 2C      [20A, 400J]
#4    IMBF-subreflector  BinTableHDU     56   1208R x 9C   [J, D, D, D, D, D, D, D, D]
#5    IMBF-antenna-s  BinTableHDU     64   2423R x 12C   [J, D, D, D, D, D, D, D, D, D, J, J]
#6    IMBF-antenna-f  BinTableHDU     63   2423R x 8C   [J, 16D, 16D, 16D, 16D, 16D, 16J, 16J]
#7    IMBF-backendNIKA  BinTableHDU     46   10138R x 10C   [J, D, 2400D, 2400D, 2400D, 2400D, 2400D, 2400J, 2400D, J]

cols = hdulist[1].columns
cols.info()
tbdata = hdulist[1].data
sysoff = (tbdata.field(0))[0]
xoff = (tbdata.field(1))[0]
yoff = (tbdata.field(2))[0]
print sysoff, xoff, yoff

cols = hdulist[2].columns
#cols.info()
tbdata = hdulist[2].data
recname = (tbdata.field(0))[0]
print recname

cols = hdulist[3].columns
#cols.info()
colnames = cols.names
tbdata = hdulist[3].data
backend = (tbdata.field(0))[0]
par = (tbdata.field(1))[0,0:,0]


cols = hdulist[4].columns
#cols.info()
colnames = cols.names
print colnames
tbdata = hdulist[4].data

data_c ={}
for index in range(len(colnames)): data_c[colnames[index]]=tbdata.field(index)


cols = hdulist[5].columns
#cols = hdulist[5].columns
#cols.info()
colnames = cols.names
print colnames
tbdata = hdulist[5].data
data_c2 ={}
for index in range(len(colnames)): data_c2[colnames[index]]=tbdata.field(index)


cols = hdulist[6].columns
colnames = cols.names
print colnames
tbdata = hdulist[6].data
data_cfast ={}
for index in range(len(colnames)): data_cfast[colnames[index]]=tbdata.field(index)



cols = hdulist[7].columns
colnames = cols.names
print colnames
tbdata = hdulist[7].data
data_det ={}
for index in range(len(colnames)): data_det[colnames[index]]=tbdata.field(index)


nsamp, ndets,dum = data_det['I'].shape

i_imb = (data_det['I'].reshape(nsamp,ndets)).T
i_raw = data.data_detector[0,:,:]

r_imb = (data_det['R'].reshape(nsamp,ndets)).T
r_raw = data.data_detector[4,:,:]


plt.clf()
plt.plot(r_raw[10,100:])
plt.plot(r_imb[10,:])












