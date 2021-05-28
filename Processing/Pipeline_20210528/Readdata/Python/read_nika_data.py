# NIKA_READ_DATA module
# Main routines to read nika raw data directly from binary files
# and transform into python arrays

import numpy as np
import ctypes
#import gc
import os
import string

# Use debugging mode when needed, see furhter instructions below
import pdb
#from matplotlib.pylab import *

class nika_data:
    pass

class Param_c:
    """
    Simple class to store param_c values
    """
    def __init__(self, namearr, valarr):
        """
        Init method for param_c class

        Parameters
        ----------
        namearr: list
                 list containing the name of the parameters
        valarr: list
                 list containing the value of the parameters
        """
        for name,val in zip(namearr,valarr):
            exec("self.%s = %s" % (name,val))
                


# Transform byte into string
# Use to retrieve names of parameters, detectors and data
def charvect2string(nbchar,vect_char):
    """ Transform byte variable into string format """
    str=""
    for idx in range(nbchar):
        if (vect_char[idx] < 0):
            print( "Problems with names")
        if (vect_char[idx]==0):
            break
        else:    
            dummy = "%c" %(vect_char[idx]) 
#        if dummy != '\x00' and dummy != '\x7f':
            str+=dummy 
    return str


#Construct kidpar definition of the detectors from raw detector parameters

def param_d2kidpar(name_param_d, val_param_d,listdet,namedet):
    """ Construct kidpar definition using information in the raw data file """
    nparams = len(name_param_d)
#    ndetectors = val_param_d.size/nparams
#    newnparams = nparams + 3
#    nval_param_d = np.zeros([newnparams,ndetectors])

    ndet = listdet[0]
    ndetindex = np.array(listdet[1:ndet+1].astype(np.int))
    
    kidpar = {}
    kidpar['name'] = (np.array(namedet))[ndetindex]
    kidpar['num']  = ndetindex
    
#   new_name=[]
#   index = 0
    for ipar in range(nparams):

# Adding new parameters encoded in type
        if (name_param_d[ipar] == 'type'):
#            new_name.append('acqbox')
#            nval_param_d[index,0:ndetectors] = (val_param_d[ipar,0:ndetectors]/65536) % 256
            kidpar['acqbox']  = (val_param_d[ipar,ndetindex]/65536) % 256
#            index += 1 
#            new_name.append('array')
#            nval_param_d[index,0:ndetectors] = val_param_d[ipar,0:ndetectors]/(65536 * 256)
            kidpar['array']  = val_param_d[ipar,ndetindex]/(65536 * 256)
#            index += 1 
#            new_name.append(name_param_d[ipar])
            kidpar[name_param_d[ipar]]= val_param_d[ipar,ndetindex] % 65536
#            nval_param_d[index,0:ndetectors] = val_param_d[ipar,0:ndetectors] % 65536
#            index += 1 
# Adding new parameters encoded in res_lg
        elif (name_param_d[ipar] == 'res_lg'):
#            new_name.append('k_flag')
            kidpar['k_flag']= val_param_d[ipar,ndetindex]/2**24
#            nval_param_d[index,0:ndetectors] = val_param_d[ipar,0:ndetectors]/2**24
#            index += 1
#            new_name.append('width')
            dummy =val_param_d[ipar,ndetindex] 
            width = dummy % (2**24)
            kidpar['width']=  width
#            nval_param_d[index,0:ndetectors] = val_param_d[ipar,0:ndetectors] % (2**24)
#            index += 1
        elif (name_param_d[ipar] == 'res_frq' or name_param_d[ipar] == 'frequency'):
#            new_name.append('frequency')
            kidpar['frequency']=  val_param_d[ipar,ndetindex] * 10
#            nval_param_d[index,0:ndetectors] = val_param_d[ipar,0:ndetectors] * 10
#            index += 1
        else:
#            new_name.append(name_param_d[ipar])
            kidpar[name_param_d[ipar]]= val_param_d[ipar,ndetindex] 
#            nval_param_d[index,0:ndetectors] = val_param_d[ipar,0:ndetectors]
#            index += 1
 
#    pdb.set_trace()
         
#    kidpar = {'pname':new_name,'pvalue':nval_param_d}
    return kidpar

## Define list of data to be read
def sel_listdata():
    import string
    list_data = 'sample subscan scan El retard 0 ofs_Az ofs_El Az Paral scan_st obs_st MJD LST flag k_flag k_angle k_width I Q dI dQ F_tone dF_tone RF_didq'
    boxes = string.ascii_uppercase[0:20]
    for box in boxes:
        list_data = list_data + ' '+box+'_o_pps'
        list_data = list_data + ' '+box+'_pps'
        list_data = list_data + ' '+box+'_t_utc'
        list_data = list_data + ' '+box+'_freq'
        list_data = list_data + ' '+box+'_masq'
        list_data = list_data + ' '+box+'_n_inf'
        list_data = list_data + ' '+box+'_n_mes'
        
    list_data = list_data + ' antxoffset anttrackAz'
    #anttrackAz anttrackEl antyoffset'     
    return list_data

## Select detectors to be read
def sel_detectors(det2red):
    """   
       Function defining the detectors to be read as a function of user input
    """
    
    if det2red == 'KID':
        codelistdet = 3
    elif det2red == 'KOD':
        codelistdet = 2
    elif det2red == 'ALL':
        codelistdet = 1
    elif det2red == 'A1':
        codelistdet = 4
    elif det2red == 'A2':
        codelistdet = 5
    elif det2red == 'A3':
        codelistdet = 6
    else:
        return -1
    return codelistdet

# ***************************************************
#  function: read_nika_data
#  input:
#            fichier  : name of file to read
#            silent   : 1 verbose mode, 0 non verbose
#            list_data: optional input defining the data we want to read
#  output:
#            nb_samples:
#            kidpar
#            param_c
#            data_common
#            data_detector,
#            name_data_c
#            name_data_d
# ******************************************************

def read_nika_data(fichier,silent=1,det2read = 'KID', list_data =sel_listdata(),nika2run2 = 0,nodata=False):
    """ 
    Description: Python wrapper to read nika raw data files  
    Function:    read_nika_data
    Input:
               fichier  : name of file to read
               det2read : Detectors to be read
                          'KID' only KID detectors
                          'KOD' KID, off-resonance and dark detectors
                          'ALL' everything in the file
                          'A1'  array 1 detectors
                          'A2'  array 2 detectors
                          'A3'  array 3 detectors
               silent   : 1 verbose mode, 0 non verbose
               list_data: optional input defining the data we want to read
               nika2run2: optional, 0 normal use, 1 if dealing with data from NIKA2RUN2 for which array1 and array 3 were using the same CRATE
    Output:
            nika_data class containing the following elements:
            nb_samples     :: total number of samples
            kidpar         :: kid parameters
            param_c        :: glogal parameters
            name_data_c    :: name of data variables in data_common, string array of nb_common_variables
            data_common    :: common data (see name_data_c for order), double array of [nb_common_variables,nb_samples] 
            name_data_d    :: name of data variables in data_detector, string array of nb_detector_variables
            data_detector  :: detector data  (see name_data_d for order), double array of [nb_detector_variables,nb_detectors,nb_samples] 
    """
# Uploading  Read NIKA data library
    
#    libpath = os.environ['PY_READ_NIKA']
#    if libpath == ' ':
    libpath = os.environ['HOME']+'/NIKA/Soft/Processing/Pipeline/Readdata/C/v1'
    readnikadata = ctypes.cdll.LoadLibrary(libpath+'/libreadnikadata.so')

# Init nika_data
    data = nika_data()

## Selecting data to be read

    codelistdet = sel_detectors(det2read)
    

    length_header = 130000
    buffer_header = np.zeros(length_header,dtype=np.long)
    nb_total_samples = np.zeros(1,dtype=np.int)
    nb_max_det = 8001
    listdet = np.zeros(nb_max_det,dtype=np.long)
    

#    pdb.set_trace()
    hptr = buffer_header.ctypes.data_as(ctypes.POINTER(ctypes.c_long))
    nbtsptr = nb_total_samples.ctypes.data_as(ctypes.POINTER(ctypes.c_int)) 
    ldptr = listdet.ctypes.data_as(ctypes.POINTER(ctypes.c_long))

#
#  Read a first time in the data in order to obtain header containing the basic
#  data description
#

#    pdb.set_trace()
    readnikadata.Py_read_start(fichier,list_data,length_header,hptr,codelistdet,ldptr,nbtsptr,silent)

# set number of detectors from what we have read
    nb_detecteurs = listdet[0]
    nb_total_samples = nb_total_samples[0]
# Get a more comprenhensive view of the parameters


    nb_boites_mesure = buffer_header[6];
#    nb_detecteurs = buffer_header[7];
    nb_pt_bloc = buffer_header[8];
    nb_param_c = buffer_header[13];
    nb_param_d = buffer_header[14];
    nb_brut_periode =  buffer_header[18]
    nb_data_communs = buffer_header[19];
    nb_data_detecteurs = buffer_header[20];
    nb_champ_reglage = buffer_header[21];
    version_header  = buffer_header[12]/65536;

    indexdetecteurdebut=0
    nb_detecteurs_lu = nb_detecteurs
    buffer_header[2]= indexdetecteurdebut 
    buffer_header[3]= nb_detecteurs_lu    
#    buffer_header[7] = nb_detecteurs

    #print "Total number of detectors %d " %(nb_detecteurs)

#  Obtain common and detector data parameters

    nbtotdet =  buffer_header[7]
    idx_param_c= np.zeros(1,dtype=np.int)
    idxpcptr = idx_param_c.ctypes.data_as(ctypes.POINTER(ctypes.c_int))
    buffer_temp_length = np.zeros(1,dtype=np.int)
    btlptr = buffer_temp_length.ctypes.data_as(ctypes.POINTER(ctypes.c_int))
    nom_var_all= np.zeros(16*(nb_param_c+nb_param_d+nb_data_communs*2+nb_data_detecteurs*2+nbtotdet),dtype=np.uint8)

    nvaptr =  nom_var_all.ctypes.data_as(ctypes.POINTER(ctypes.c_char))
    nb_char_nom= np.zeros(1,dtype=np.int)
    nbcnptr = nb_char_nom.ctypes.data_as(ctypes.POINTER(ctypes.c_int))

#    pdb.set_trace()
    
#    print "Starting read_nika_infos"

    readnikadata.Py_read_infos(length_header,hptr,idxpcptr,btlptr,nvaptr,nbcnptr,silent)

    nb_char_nom = nb_char_nom[0]
    idx_param_c = idx_param_c[0]
    buffer_temp_length = buffer_temp_length[0]
    
# Reconstructing names of detectors, data and parameters
    idxinit= 0
    nom_param_c = nom_var_all[idxinit:idxinit+nb_char_nom*nb_param_c] 
    name_param_c = []
    val_param_c = np.zeros(nb_param_c,dtype=np.int)



    for idx in range(nb_param_c):
        name_param_c.append(charvect2string(nb_char_nom,nom_param_c[idx*nb_char_nom:idx*nb_char_nom+nb_char_nom]))
        val_param_c[idx] = buffer_header[idx_param_c+idx]

    #param_c = {'pname':name_param_c, 'pvalue':val_param_c}
    #pdb.set_trace()
    param_c = Param_c(name_param_c,val_param_c)
    
    idxinit += nb_char_nom*nb_param_c
    nom_param_d = nom_var_all[idxinit:idxinit+nb_char_nom*nb_param_d]
    name_param_d = []
#    pdb.set_trace()
    
    val_param_d = np.zeros((nb_param_d-2)*nbtotdet,dtype=np.int).reshape(nb_param_d-2,nbtotdet)
    for index in range(nb_param_d-2):
        idx = index + 2
        name_param_d.append(charvect2string(nb_char_nom,nom_param_d[idx*nb_char_nom:(idx+1)*nb_char_nom]))
        indexstart = idx_param_c +nb_param_c +idx*nbtotdet
        indexend = idx_param_c +nb_param_c+idx*nbtotdet+nbtotdet
        val_param_d[index,0:nbtotdet] = buffer_header[indexstart:indexend].reshape(1,nbtotdet)


    idxinit += nb_char_nom*nb_param_d
    if (nb_data_communs > 0): 
        nom_data_c = nom_var_all[idxinit:idxinit+nb_char_nom*nb_data_communs]
        name_data_c=[]
        for idx in range(nb_data_communs):
            name_data_c.append(charvect2string(nb_char_nom,nom_data_c[idx*nb_char_nom:(idx+1)*nb_char_nom]))
        idxinit += nb_char_nom*nb_data_communs
        unites_data_c = nom_var_all[idxinit:idxinit+nb_char_nom*nb_data_communs]
        units_data_c=[]
        for idx in range(nb_data_communs):
            units_data_c.append(charvect2string(nb_char_nom,unites_data_c[idx*nb_char_nom:(idx+1)*nb_char_nom]))
        idxinit += nb_char_nom*nb_data_communs

    if (nb_data_detecteurs > 0):
        nom_data_d = nom_var_all[idxinit:idxinit+nb_char_nom*nb_data_detecteurs]
        name_data_d=[]
        for idx in range(nb_data_detecteurs):
            name_data_d.append(charvect2string(nb_char_nom,nom_data_d[idx*nb_char_nom:(idx+1)*nb_char_nom]))
        name_data_d.append('flag')
        idxinit += nb_char_nom*nb_data_detecteurs
        unites_data_d = nom_var_all[idxinit:idxinit+nb_char_nom*nb_data_detecteurs]
        units_data_d=[]
        for idx in range(nb_data_detecteurs):
            units_data_d.append(charvect2string(nb_char_nom,unites_data_d[idx*nb_char_nom:(idx+1)*nb_char_nom]))
        units_data_d.append('')
        idxinit += nb_char_nom*nb_data_detecteurs

    nom_detecteurs = nom_var_all[idxinit:idxinit+8 * nbtotdet]
    name_detectors = []

    #print np.array(name_data_c)
    data.param_c = param_c
    data.name_data_c = np.array(name_data_c)
    data.name_data_d = np.array(name_data_d)

    
    for idx in range(nbtotdet):
        name_detectors.append(charvect2string(8,nom_detecteurs[idx*8:(idx+1)*8]))
    
    nb_samples = 0
# Convert detector parameters into kidpar like parameters
# I use as much as possible the definition from the IDL code
    indexdectbeg = 0
    nb_detectors_read = nb_detecteurs
    data.kidpar =  param_d2kidpar(name_param_d, val_param_d,listdet,name_detectors)                                          

## Fix for data acquisition problems on NIKA2RUN2
## Notice this is just a temporary fix before we have an stable NIKA2 electronic configuration     
    if nika2run2:
#        parray = (np.where(np.array(data.kidpar['pname']) =='array'))[0][0]
#        pbox   = (np.where(np.array(data.kidpar['pname']) =='acqbox'))[0][0]
#        array = np.array(data.kidpar['pvalue'][parray])
#        box = np.array(data.kidpar['pvalue'][pbox])
        array = np.array(data.kidpar['array'])
        box = np.array(data.kidpar['acqbox'])
        warr1 = np.where((box >=8) & (box <= 10))
        array[warr1] = 1
        data.kidpar['array'] = array
            
## Adding detector name to data structure
##    data.name_detectors = name_detectors
    if nodata == True:
        return data


## remove buffer_header


#   ----------------------------------------
#    READING DATA
#   ------------------------------------------

# Define vectors out
    
    data.data_common = np.zeros((nb_data_communs,nb_total_samples))
    data.data_detector = np.zeros((nb_data_detecteurs+1,nb_detecteurs,nb_total_samples))

#    data_common = np.zeros((nb_data_communs,nb_total_samples))
#    data_detector = np.zeros((nb_data_detecteurs+1,nb_detecteurs,nb_total_samples))

    #periode = np.zeros(nb_brut_periode*nb_detecteurs_lu*nb_total_samples/nb_pt_bloc).reshape(nb_brut_periode,nb_detecteurs_lu,nb_total_samples/nb_pt_bloc)

# Read data by chuncks 
    length_bufferdata = 1000000000
    length_data_per_sample = nb_data_communs + nb_data_detecteurs*nb_detectors_read
    
    maxsample = length_bufferdata / length_data_per_sample
    length_bufferperiode = (2 + maxsample/nb_pt_bloc) * nb_brut_periode*nb_detectors_read 


#    print length_data_per_sample
    
    buffer_data = np.zeros(length_bufferdata,dtype=np.double)
    buffertemp = np.zeros(buffer_temp_length,dtype=np.int8)
    bufferperiode = np.zeros(length_bufferperiode,dtype=np.int)

#  set pointers to numpy vectors
    bfd_ptr = buffer_data.ctypes.data_as(ctypes.POINTER(ctypes.c_double))
    bfdp_ptr = bufferperiode.ctypes.data_as(ctypes.POINTER(ctypes.c_int))
    bft_ptr = buffertemp.ctypes.data_as(ctypes.POINTER(ctypes.c_char))
    
    nb_samples_lu = 1
    nb_sample_total = long(0)
    nb_bloc_total = long(0)
    isample = 0
    indiceboucle=0                  ;
    buffertemp[0] = 1
  

# ------------  LOOP on samples --------------


    while (nb_samples_lu >0):
#        pdb.set_trace()     

        nb_samples_lu = readnikadata.Py_read_data(fichier,length_header,hptr,ldptr,length_bufferdata,bfd_ptr,bfdp_ptr,bft_ptr,silent)

#        if (silent > 0):
#            print 'Nb_samples_lu %d' %(nb_samples_lu)
        indextake = np.arange(0,nb_samples_lu,dtype=long)*length_data_per_sample

        if (nb_samples_lu >0) :
            indiceboucle +=1
            nb_bloc_lu = nb_samples_lu/nb_pt_bloc


#      Reorder data properly
            # solve problems with missing blocks
            # it works but not sure that the data are fully correct
            if nb_total_samples < isample+nb_samples_lu:
                nlsamp = nb_total_samples-isample
            else:
                nlsamp = len(indextake)
                
            for idx in range(nb_data_communs):
               data.data_common[idx,isample:isample+nb_samples_lu] = buffer_data[indextake[0:nlsamp]+idx]
#                data_common[idx,isample:isample+nb_samples_lu] = buffer_data[indextake+idx]
               
            for idx in range(nb_data_detecteurs):
                for idet in range(nb_detecteurs_lu):
                    ipos = np.long(nb_data_communs) + np.long(idx*nb_detecteurs_lu) + np.long(idet)
                    data.data_detector[idx,idet,isample:isample+nb_samples_lu] = buffer_data[indextake[0:nlsamp]+ipos]
#                    data_detector[idx,idet,isample:isample+nb_samples_lu] = buffer_data[indextake+ipos]
                   

#      Update index to read next chunck of data
            isample += nb_samples_lu
            nb_sample_total += nb_samples_lu
            nb_bloc_total += nb_bloc_lu

# ADD common and KID data to class

    data.nb_samples = nb_sample_total

#   shift RF_didq if needed
    posrf = np.where(data.name_data_d =='RF_didq')
    if len(posrf[0]) > 0:
        posrf = posrf[0][0]
        shift_rf_didq = -49
        rfdidq = np.roll(data.data_detector[posrf,0:nb_detecteurs,0:nb_total_samples],shift_rf_didq,axis=1)
        data.data_detector[posrf,:,:] = rfdidq

    expand(data)
    #div_kid = (data.param_c['pvalue'])[np.where(np.array(data.param_c['pname']) ==  'div_kid')[0][0]]
    data.acqfreq = 5.0e8/2.0**19/data.param_c.div_kid


    # add pps_time and pps_time difference to the data
    
    boxes = string.ascii_uppercase[0:20]
    
    pps =   get_nikavar_data(data,'A_o_pps')
    if pps != None:
        pps_diff = []
        for box in boxes[1:]:
            varname = box+'_o_pps'
            var =  get_nikavar_data(data,varname)
            if var != None:
                pps_diff.append((pps-var)*1.0e6)
        pps_diff = np.asarray(pps_diff)
        pps_diff = np.max(pps_diff,axis =0)

        # Correct pps if necessary
        dummy = pps -np.roll(pps,1)
        pos = np.where(np.abs(dummy-1.0/data.acqfreq) < 0.02)
        apar,bpar=np.polyfit(data.sample[pos[0]],pps[pos[0]],1)
        pos = np.where(np.abs(dummy-1.0/data.acqfreq) > 0.02)
        if len(pos[0]) >1:
            pps[pos[0]]= apar*data.sample[pos[0]]+bpar
        #
        data.pps = pps
        data.pps_diff = pps_diff

    # free memory in buffer_data
    buffer_data = None
    buffer_header = None
    #print 'Total number of samples read %d \n' %(nb_sample_total)
    return data


### FUNCTION GET data for a given required variable



def expand(nika_data):

    #nika_data.data={}
    index = 0
    for vname in nika_data.name_data_c:
        exec("nika_data.%s = nika_data.data_common[index,:]" % (vname))

        #nika_data.data[vname] = nika_data.data_common[index,:]
        index=index+1
    index = 0
    for vname in nika_data.name_data_d:
        exec("nika_data.%s = nika_data.data_detector[index,:,:]" % (vname))
        #nikadata.data[vname] = nika_data.data_detector[index,:,:]
        index = index+1
    return

def get_nikavar_data(nika_data,var_name):
    """ 
       Purpose: 
                 extract data for a given needed variable
       
       Input:
                 nika_data :: nika_data object
                 var_name  :: name of variable to be extracted

       Output:
                 output_data :: extracted data
    """
    # check if common data
    index =0
    for vname in nika_data.name_data_c:
        if vname == var_name:
            outdata = nika_data.data_common[index,:]
            return outdata
        else:
            index=index+1
    index = 0
    for vname in nika_data.name_data_d:
        if vname == var_name:
            outdata = nika_data.data_detector[index,:,:]
            return outdata
        else:
            index = index+1
    return None


def get_nikavar_pos(nika_data,var_name):
    """ 
       Purpose: 
                 extract position for a given needed variable
       
       Input:
                 var_name :: name of the variable
 
       Output:
                 type, pos  :: type (common - 0 , kid -1), vector position
   """
    # check if common data
    index =0
    for vname in nika_data.name_data_c:
        if vname == var_name:
            type = 0
            pos = index
            return type, pos
        else:
            index=index+1
    index = 0
    for vname in nika_data.name_data_d:
        if vname == var_name:
            type = 1
            pos = index
            return type,pos
        else:
            index = index+1



# Function to obtain kidpar var from nikadata
            
def get_kidpar_var(nikadata,var):
    """ 
       Purpose: 
                 extract kidpar data for a given variable
                 'acqbox','array','type','voie','frequency','level',width','flag','tune_angle'
       
       Input:
                 nikadata :: nika_data object
                 var      :: name of the requested variable to be extracted

       Output:
                 output_data :: extracted data
    """

#    pos = np.where(np.array(nikadata.kidpar['pname']) ==var)
#    if len(pos[0]):
#        pos = pos[0][0]
#        return np.array(nikadata.kidpar['pvalue'][pos])
#    else:
#        print var + " is not a kidpar variable"
#        return -1
    return nikadata.kidpar[var]    


    
if __name__ == '__main__':

    # READ data script
    import read_nika_data as rnd
    import matplotlib.pyplot as plt
    import numpy as np

    plt.ion()
    
    mfile = '/mnt/NewData/NIKA/Data/run31_X/X36_2018_05_27/X_2018_05_27_22h12m04_AA_0141_P_1253-055'
    mfile = '/mnt/NewData/NIKA/Data/run31_X/X36_2018_05_26/X_2018_05_26_22h30m06_AA_0153_P_1226+023'
    mfile = '/mnt/NewData/NIKA/Data/run31_X/X36_2018_05_24/X_2018_05_24_20h50m19_AA_0143_O_1253-055'
    silent = 0
    datas =  rnd.read_nika_data(mfile,silent=silent,list_data='all', nodata=True)
    #data =  rnd.read_nika_data(mfile,silent=silent,list_data='all')
    data =  rnd.read_nika_data(mfile,silent=silent,list_data='sample ofs_X ofs_Y I Q RF_didq')
    print('Total number of samples read %d \n' %(data.nb_samples))
