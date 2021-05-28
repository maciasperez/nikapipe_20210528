import numpy as np
import matplotlib.pyplot as plt
from scipy import signal


def power_spec(toi,time=None,sampling_freq = 1,ax=1):

    """
       Compute the poewr spectrum density of a given TOI
       Wrapper to periodogram function

       Parameters
       ----------
       toi : array like, might be multiple dimensions eg. (ndet,nsamples)
             Input TOI
       time: array_like, optional
             time array from which we can compute sampling frequency
       sampling_freq:  double, optional
             sampling frequency
       ax: integer
           axis along which the power spectrum is computed

       Returns
       ------
       fr: array_like
           frequency array
       pw: array_like
           power spectrum
       
       See also
       ---------
       show_ps: display power spectrum 

       Notes
       -----

       References
       ----------

       Examples
       --------

       >>> from power_spectrum import power_spec
       >>> import numpy as np
       >>> toi = np.random.normal(0.,1.0,size=(10,1000))
       >>> fr, pw = power_spec(toi)
    """
    if len(toi.shape) == 1: ax = 0
    freq, pw = signal.periodogram(toi, sampling_freq,scaling='density',axis=ax)
    return freq,pw


def cross_spec(toi):

    if len(toi.shape)  < 2:
        print "Assuming multiple detectors TOI"
        return

    ndet,nsamp = toi.shape
    
    fr,cs = signal.csd(toi[0,:],toi[0,:])
    nnsamp= cs.size
    crs = np.zeros((ndet,ndet,nnsamp))
    crs[0,0,:] = np.double(cs)
    for idx in np.arange(ndet-1)+1:
        for jdx in np.arange(ndet-idx)+idx:
            fr, cs = signal.csd(toi[idx,:],toi[jdx,:])
            crs[idx,jdx,:] = np.double(cs)
            crs[jdx,idx,:] = np.double(cs)
            
            
    return fr, crs


def show_ps(toi,timet=None, sampfreq=1.0):
    
     
    fr,pw = power_spec(toi,time=timet,sampling_freq=sampfreq)
    plot_power_spectrum(fr,pw)
    

def plot_power_spectrum(fr,pw,multi=0):

    nsamp = fr.size
    
    if len(pw.shape) >1:
        ndet,nsamp2 = pw.shape
    else: 
       ndet = 1
       nsamp2 = pw.size

# IF frequency array is not the same size than power spectrum
    if nsamp != nsamp2: return -1

    if ndet > 1:
        
        if multi:
            # need to think how to do this !
            pass
        else:    
            plt.plot(fr,pw.T)
    else:
        plt.plot(fr,pw)
        
    plt.loglog()
    plt.grid()
    plt.xlabel('Frequency [Hz]')
    plt.xlabel('PSD [$Hz/Hz^{1/2}$]')
    plt.axis([fr.min(),fr.max(),pw.min(),pw.max()])
    return


def rms_from_ps(fr,pw):

    
    from process_1d import int_tabulated
    if len(pw.shape) > 1:
        ndet,nsamp = pw.shape
        sigma=[]
        for idx in range(ndet):
            sigma.append(int_tabulated(fr,pw[idx,:]))
        sigma = np.sqrt(np.array(sigma))
    else:
        sigma = np.sqrt(int_tabulated(fr,pw))
    return sigma



def rms_from_band(fr,pw,frmin,frmax):

    sigma = -1  
    wfreq = np.where((fr >= frmin) & (fr <= frmax))[0]
    if len(wfreq) > 0:
      if len(pw.shape) > 1:
          ndet,nsamp = pw.shape
          sigma=[]
          for idx in range(ndet):
              sigma.append(np.mean(pw[idx,wfreq])*fr.max())             
          sigma = np.sqrt(np.array(sigma))
      else:
          sigma = np.sqrt(np.mean(pw[wfreq])*fr.max())
    return sigma

def noise_from_band(fr,pw,frmin,frmax):
    sigma = -1  
    wfreq = np.where((fr >= frmin) & (fr <= frmax))[0]
    if len(wfreq) > 0:
      if len(pw.shape) > 1:
          ndet,nsamp = pw.shape
          sigma=[]
          for idx in range(ndet):
              sigma.append(np.mean(pw[idx,wfreq]))             
          sigma = np.array(sigma)
      else:
          sigma = np.mean(pw[wfreq])*fr.max()
    return sigma
