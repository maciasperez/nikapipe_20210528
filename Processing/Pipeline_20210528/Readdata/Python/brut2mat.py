"""
Small code to transfrom NIKA brute data into matlab format files

"""
import read_nika_data as rnd
import scipy.io as sio


# define file you want to read
file  ='/home/nika2/NIKA/Data/run22_X/X36_2017_02_26/X_2017_02_26_09h47m01_AA_0180_O_Neptune'

# decide if you want to read KID only or also offline and dark detectors
det2read = 'KID' # for reading KIDs only
# det2read = 'KOD' # for reading KID, off resonance & dark pixels

# do a a first reading to know what it is inside the file

data = rnd.read_nika_data(file,det2read=det2read,list_data='all',nodata=True)
print "-------------------------------------------"
print "Common variables"
print "-------------------------------------------"
mstr =''
for var in data.name_data_c:
	mstr= mstr +'  ' + var
print mstr
print "-------------------------------------------"
print "Detector variables"
print "-------------------------------------------"
mstr = ''
for var in data.name_data_d:
	mstr= mstr +'  ' + var
print mstr

# Select list data
list_data = 'sample RF_didq'

data = rnd.read_nika_data(file,det2read=det2read,list_data=list_data)

# save selected data to FILE
file_out = '/home/nika2/Neptune0180.mat'
outvarname ='RF_didq'
outdata = data.RF_didq
sio.savemat(file_out, {'sample':data.sample,outvarname:outdata})
