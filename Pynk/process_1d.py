import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit
import pdb


def histo_make(arr,bins=10,plot=0,gfit=0):
    """  
      Histogram

    """
    if len(arr.shape) >1:
        yr, bins = np.histogram(arr.ravel(), bins=bins)
    else:
        yr, bins = np.histogram(arr, bins=bins)
 #   width = 0.7 * (bins[1] - bins[0])
    xr = (bins[:-1] + bins[1:]) / 2.0

    if (plot) :
#        plt.clf()
        plt.plot(xr, yr, drawstyle='steps-mid', label="Data")

    if (gfit):
        coeff,scoeff,yr_fit = gauss1d_fit(xr,yr)
        if (plot):
            plt.plot(xr, yr_fit, label="Gaussian fit")
    else:
        coeff  = -1
        scoeff = -1

    if (plot):
        plt.legend()
 #       plt.show()
    return xr,yr,coeff,scoeff


# Gausian fit
def gauss1d(x, *p):
    """ 
       Description:    simple gaussian 1d function
       Input:          
                       x:: array
                       p:: Gaussian parameters
                           A, mu, sigma = p
        
       Output:
                       A * exp(-(x-mu)^2/2.0/sigma^2)

       Authors:       J.F. Macias-Perez, 2016
    """
    A, mu, sigma = p
    return A*np.exp(-(x-mu)**2/(2.*sigma**2))

def gauss1d_fit(xr,yr,syr=None):
    """ 
       Description:    Fit gaussian 1D Gaussian to data

       Input:          
                       xr: data sampling array
                       yr: input time data
                       syr (optional) : error bars for yr
        
       Output:
                       coeff: parameters of the 1D Gaussian
                       var_matrix : correlation matrix for coeff
                       yr_bit: best-fit 1D Gaussian
        Authors:        J.F Macias-Perez, 2016
                    
    """

    A = np.max(yr)
    mu = xr[np.where(yr == A)]
    pos = np.where(yr >= A/2.0)
    sig = np.abs(xr[pos[0][0]]-mu)
    p0 = [A, mu, sig]
    coeff, var_matrix = curve_fit(gauss1d, xr, yr, p0=p0,sigma=syr)
    yr_fit = gauss1d(xr, *coeff)

    return coeff,var_matrix,yr_fit


# Copy of the IDL int_tabulated function !

def int_tabulated(x,y):
    from scipy.interpolate import interp1d
    xmin = np.double(x).min()
    xmax = np.double(x).max()

    nx = x.size
    xsegments = np.long((nx -1)/4)*4
    if xsegments < nx: xsegments +=4

    h = (xmax-xmin)/np.double(xsegments)
    xgrid = xmin + h * np.arange(xsegments+1)
   
    finterp = interp1d(x, y,kind='cubic')
    ygrid = finterp(xgrid)

    ii = (np.arange((ygrid.size-1)/4)+1)*4

    intab = np.sum(2.0 * h * (7.0 * (ygrid[ii-4] + ygrid[ii]) + 32.0 * (ygrid[ii-3] + ygrid[ii-1]) + 12.0 * ygrid[ii-2]) / 45.0)

    return intab


def sigma_mad(arr):
    """ 
        Description: 
                 Median Absolute Deviation: a "Robust" version of standard deviation.Indices variabililty of the sample. https://en.wikipedia.org/wiki/Median_absolute_deviation 
        Input : 1D array
    """
    sigma_mad = np.median(np.abs(arr.T - np.median(arr.T,axis=0)),axis=0)/0.6745
    return sigma_mad.T



def denoising_1d(data,threshold,mode='soft'):
    """ 
       Description:    Wavelet thresholding using pywt

       Input:          
                       data: multidimensional array
                       threshold: threshold use in the thresholding algorithm
       Keywords:
                       mode = denoising method 'soft','hard'
       Output:
                       

      Authors:        J.F Macias-Perez, aug 2016
    """
    import pywt
    wavelet = pywt.Wavelet('db1')
    levels  = np.long( np.floor( np.log2(data.shape[0]) ) )
    wavcoeff = pywt.wavedec(data,wavelet,level=levels)
    if pywt.version.version == '0.5.1':
      wavcoeffn = map (lambda x: pywt.threshold(x,threshold,mode=mode),wavcoeff)
    else:
      if mode == 'soft':
          wavcoeffn = map (lambda x: pywt.thresholding.soft(x,threshold),wavcoeff)
      elif mode == 'hard':
          wavcoeffn = map (lambda x: pywt.thresholding.hard(x,threshold),wavcoeff)

    ndata = pywt.waverec(wavcoeffn,wavelet) 
    return ndata

def contiguous_regions(condition):
    """Finds contiguous True regions of the boolean array "condition". Returns
    a 2D array where the first column is the start index of the region and the
    second column is the end index."""

    # Find the indicies of changes in "condition"
    d = np.diff(condition)
    idx, = d.nonzero() 

    # We need to start things after the change in "condition". Therefore, 
    # we'll shift the index by 1 to the right.
    idx += 1

    if condition[0]:
        # If the start of condition is True prepend a 0
        idx = np.r_[0, idx]

    if condition[-1]:
        # If the end of condition is True, append the length of the array
        idx = np.r_[idx, condition.size] # Edit

    # Reshape the result into two columns
    idx.shape = (-1,2)
    return idx

def find_index_blocks(index):
    """ 
       Description:    Find blocks in indeces, assuming a distance of 1

       Input:          
                       index: np.array index array
        
       Output:
                       block: list containing array blocks 

      Authors:        J.F Macias-Perez,aug,  2016
    """

    if len(index) == 1:
        block = index
    pos = (np.where(np.diff(index) > 1))[0]
    npos = len(pos)
    if npos == 0:
        block = index
    else:
        block=[]
        if npos == 1:
            block.append(index[0:pos[0]+1])
            block.append(index[pos[0]+1:])
        else:
            block.append(index[0:pos[0]+1])
            for idx in range(0,npos-1):
                block.append(index[pos[idx]+1:pos[idx+1]+1])        
            block.append(index[pos[npos-1]+1:])

    return block


def canny_jump_find(data,nkernel=3,nsigma=6.0):

    """ 
       Description:    Find jumps in the data using the Canny algorithm

       Input:          
                       data: multidimensional array
        
       Output:
                      edges: position of jumps in the data

      Authors:        J.F Macias-Perez 2016
    """
    from scipy.ndimage import gaussian_filter1d
    
    ny = -1
    nx = data.shape
    if len(nx) >1:
        ny = nx[1]
        nx = nx[0]
    else:
        nx = nx[0]

#   Filter data with the derivative of a Gaussian
    ax = -1 
    if ny > 0:
        ax = 1

    
    data_filt = gaussian_filter1d(data, nkernel, order=1,axis = ax)
    
    sigma = sigma_mad(data_filt)
    if ny > 0:
        data_th = []
        for idx in range(nx):
           threshold = sigma[idx]/2.0
           data_th.append(denoising_1d(data_filt[idx,:],threshold))
        data_th = np.array(data_th)
    else:
        threshold = sigma/2.0
        data_th = denoising_1d(data_filt,threshold)

#    data_th = data_filt    
    sigma = sigma_mad(data_th)
    if ny > 0:
        peaks = []
        for idx in range(nx):
            npeaks = []
            index = (np.where(abs(data_th[idx,:]) > nsigma * sigma[idx]))[0]
            block = find_index_blocks(index)
            for bc in block:
                npeaks.append(bc[np.argmax(np.abs(data_th[idx,bc]))])
            peaks.append(np.array(npeaks))
    else:
        peaks = []
        index = (np.where(abs(data_th) > nsigma * sigma))[0]
        block = find_index_blocks(index)
        if len(block) > 0:
            for bc in block:
                peaks.append(bc)
#                peaks.append(bc[np.argmax(np.abs(data_th[bc]))])
        if len(peaks) > 0:
            peaks = np.array(peaks)    
    
    return peaks


def jump_correct(data,jumpos):
    """ 
       Description:  Correct multiple detector time series from jumps

       Input:          
                       data: multidimensional array
                       jumppos : jump position array
        
       Output:
                      corrdata: jumps corrected time series

      Authors:        J.F Macias-Perez, aug 2016
    """
    
    s = data.shape    
    
    if len(s) > 1:
        corrdata = []
        nx = s[0]
        for idx in range(nx):
            corrdata.append(jump_correct_sub(data[idx,:],jumpos[idx]))
        corrdata = np.array(corrdata)
    else:
        corrdata = jump_correct_sub(data,jumpos)

    return
    
def jump_correct_sub(data, jumpos,nbloc=30):
    """ 
       Description:   correct data from jumps

       Input:          
                       data: multidimensional array
                       jumppos : jump position array
        
       Output:
                      corrdata: jump corrected array

      Authors:        J.F Macias-Perez, aug 2016
    """

    corrdata = np.array(data)
    ndata = data.size
    for pos in jumpos:
        bi,ei = assert_index(pos-nbloc, pos, ndata)
        mb = np.median(corrdata[bi:ei])
        bi,ei = assert_index(pos+1, pos+nbloc, ndata)
        ma = np.median(corrdata[bi:ei])
        corrdata[pos+1:]+= (mb-ma)
        
    return corrdata

def assert_index(bind,eind,nmax):
    """ 
       Description:   check begin and end index of array block are compatible with array size

       Input:          
                       bind: init index
                       eind: end index
                       nmax: array maximum number of samples
        
       Output:
                      mbind, eind: corrected (if necessary) init and end index

      Authors:        J.F Macias-Perez, 2016
    """
    
    if bind < 0:
        mbind = 0
    else:
        mbind = bind

    if eind > nmax-1:
        meind = nmax-1
    else:
        meind = eind


    if eind < 0 or bind > nmax-1:
        return -1,-1


    return mbind,meind


def smooth(data,lsm):
    """
      Description: smooth 1D data
      Input:
              data: nD array
              lsm: size of smoothing kernel
      Output:
              smooth data: nD array
    """
    from scipy.ndimage.filters import uniform_filter

    return uniform_filter(data, size=lsm, output=None, mode='reflect')
    

def despike(data,threshold = 8,step=300):
    """ 
      Description: 
        Function to find glitches on input data by computing a rolling stddev
      Input:
        data : nD array
        threshold
        step
      Output:
    """

    
