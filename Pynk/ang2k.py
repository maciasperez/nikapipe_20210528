import numpy as np
import matplotlib.pyplot as plt

def panco_k(nx,ny,reso):
    """
    Compute k as in PANCO scripts, which is compatible with IDL version

    Inputs
    ------
        nx  : number of pixels in x direction 
        ny  : number of pixels in y direction
        reso: resolution in arcsec

    Outputs
    -------
        k  : wavenmuber in astropy.units("arcsec-1"), 
    """
    
    kx =  np.outer(np.fft.fftfreq(nx),np.zeros(ny).T+1.0)
    ky =  np.outer(np.zeros(nx).T+1.0,np.fft.fftfreq(ny))
    k = np.sqrt(kx*kx + ky*ky)
    kmax = 1./reso
    k = k/k.max() * kmax

    return k

def nyquist_k(nx,ny,reso):
    """
    Compute k from 1D nyquist definition

    Inputs
    ------
        nx  : number of pixels in x direction 
        ny  : number of pixels in y direction
        reso: resolution in arcsec

    Outputs
    -------
        k  : wavenmuber in astropy.units("arcsec-1"), 
    """
    
    kx =  np.outer(np.fft.fftfreq(nx,d=reso),np.zeros(ny).T+1.0)
    ky =  np.outer(np.zeros(nx).T+1.0,np.fft.fftfreq(ny,d=reso))
    k = np.sqrt(kx*kx + ky*ky)

    return k




def poker_k(nx,ny,reso):

    """
    Compute k using POKER definition (Ponthieu et al. 20)

    Inputs
    ------
        nx  : number of pixels in x direction 
        ny  : number of pixels in y direction
        reso: resolution in arcsec

    Outputs
    -------
        k  : wavenmuber 
    """

    reso_rad = reso/3600.0 * np.pi/180.0 
    kx =  np.outer(np.fft.fftfreq(nx),np.zeros(ny).T+1.0)
    ky =  np.outer(np.zeros(nx).T+1.0,np.fft.fftfreq(ny,d=reso))
    k =   np.sqrt(kx*kx + ky*ky)
    k *= (2.0*np.pi)/reso_rad
    # WARNING NOT FINISHED YET
    return k


def compute_cross_spec(reso, map1,map2=None,nbins=100,getk=panco_k):
    """
    Compute cross spectra

    Parameters
    ----------
    reso: double 
          resolution of maps in arcsec
    map1: np.ndarray 2d
          map for which the power spectrum will be computed
    map2: np.ndarray 2D, optional
          map to compute cross power spectrum with map1
    nbins: int , optional
          Number of bins in k space
    getk: function
          Function defining the k vector

    Returns
    -------
    kbin : np.ndarray 1D
           k values for the 1D power spectrum using getk function
    Pk:    np.ndarray 1D
           power spectrum or cross spectrum
    SPk:   np.ndarray 1D
           dispersion over the bin of k for cross or power spectrum

    """
    from  scipy.stats import  binned_statistic
    nx,ny = map1.shape

    k = getk(nx,ny, reso)

    fmap1 = np.fft.fft2(map1)
    if map2 is not None:
        fmap2= np.fft.fft2(map2)
        spec = fmap1*np.conjugate(fmap2)
    else:
        spec = fmap1*np.conjugate(fmap1)
    Pk,bintabk,bn = binned_statistic(k.ravel(),spec.real.ravel(),'mean',bins=nbins)
    SPk,bintabk,bn = binned_statistic(k.ravel(),spec.real.ravel(),'std',bins=nbins)

    kbin = ((bintabk  + np.roll(bintabk,-1))[0:nbins]/2.0)
        
    return kbin, Pk, SPk

def beam_nika2(fwhm,reso,npix):
    """
    Compute gaussian beam of fwhm for 
    (npix,npix) map of resolution reso

    Parameters
    ----------
    fhwm: double
          FWHM of the beam 
    reso: double 
          resolution of maps in arcsec
    npix: int
          number of pixels in the x, and y direction
          npix x npix map

    Returns
    -------
    beam : np.ndarray 2D
           beam map

    """

    x = np.arange(npix) - npix/2
    y = np.arange(npix) - npix/2
    xv, yv = np.meshgrid(x,y)
    dist = np.sqrt(xv**2 + yv**2)*reso
    sigma = fwhm/(2.0*np.sqrt(2.0*np.log(2)))
    beam = np.exp(- dist**2/2/sigma/sigma)
    beam /= np.sum(beam)

    return beam

def cc_pattern(size,reso,npix):
    """
    Compute circular cosine
    (npix,npix) map of resolution reso

    Parameters
    ----------
    fhwm: double
          FWHM of the beam 
    reso: double 
          resolution of maps in arcsec
    npix: int
          number of pixels in the x, and y direction
          npix x npix map

    Returns
    -------
    ncos: np.ndarray 2D
          circular cosine pattern map

    """

    x = np.arange(npix) - npix/2
    y = np.arange(npix) - npix/2
    xv, yv = np.meshgrid(x,y)
    dist = np.sqrt(xv**2 + yv**2)*reso
    
    mcos = np.cos(2.0*np.pi*dist/size)
    
    return mcos

def k2map(kval, reso,npix,deltak=None,getk=panco_k):
    """
    Compute gaussian beam of fwhm for 
    (npix,npix) map of resolution reso

    Parameters
    ----------
    kval: double
          value of k that we want to study
           
    reso: double 
          resolution of map in arcsec
    npix: int
          number of pixels in the x, and y direction
          npix x npix map

    deltak: double, optional, default None
           precision adopted for single out k value in Fourier space
           if None set to twice the minimum k difference

    getk: function, optional default panco_k
          Function defining the k vector

    Returns
    -------
    mmapnew: np.ndarray 2D
             random map for which only the signal for kval+-deltak is
             preserved

    """

    k = getk(npix,npix, reso)
    np.random.seed(2)
    mmap = np.random.normal(0,1.,(npix,npix))
    fmap = np.fft.fft2(mmap)
    if deltak is None:
        deltak = np.median(np.abs(np.gradient(k))) 
    pos = np.where(np.abs(k-kval) > deltak)
    fmap[pos] = np.complex(0.0,0.0)
    mmapnew =  np.fft.ifft2(fmap).real
    
    
    return mmapnew

if __name__ == "__main__":

    """

    Testing how diffent k values give different
    size in real space

    """

    fwhm_2mm = 18.
    reso = 3.0
    npix = 200
    
    beam_2mm = beam_nika2(fwhm_2mm,reso,npix)
    kbin, PkB, SPkB =  compute_cross_spec(reso, beam_2mm,nbins=150,getk=panco_k)
    bell_2mm = np.sqrt(PkB)
    bell_2mm /= bell_2mm.max()


    
   

    map2arcm = k2map(1./2./60.0, reso,npix,deltak=0.8e-3,getk=panco_k)
    map4arcm = k2map(1./4./60.0, reso,npix,deltak=0.8e-3,getk=panco_k)
    map6arcm = k2map(1./6./60.0, reso,npix,deltak=0.8e-3,getk=panco_k)

    fig,ax = plt.subplots(nrows=1,ncols=3,figsize=(12,5))
    ax[0].imshow(map2arcm,extent=(0,npix*reso,0,npix*reso))
    ax[1].imshow(map4arcm,extent=(0,npix*reso,0,npix*reso))
    ax[2].imshow(map6arcm,extent=(0,npix*reso,0,npix*reso))
    ax[0].set_title('2arcm-1')
    ax[1].set_title('4arcm-1')
    ax[2].set_title('6arcm-1')
    ax[0].set_xlabel('[arcsec]')
    ax[0].set_ylabel('[arcsec]')
    
    kbin, Pk2, SPk2 =  compute_cross_spec(reso, map2arcm,nbins=150,getk=panco_k)
    kbin, Pk4, SPk4 =  compute_cross_spec(reso, map4arcm,nbins=150,getk=panco_k)
    kbin, Pk6, SPk6 =  compute_cross_spec(reso, map6arcm,nbins=150,getk=panco_k)
    C2E = np.sqrt(Pk2)
    C2E /= np.max(C2E)
    C4E = np.sqrt(Pk4)
    C4E /= np.max(C4E)
    C6E = np.sqrt(Pk6)
    C6E /= np.max(C6E)
    
    fig, ax = plt.subplots()
    ax.plot(kbin,bell_2mm,label='BEAM 2mm')
    ax.plot(kbin,C2E,label='2 arcmin$^{-1}$')
    ax.plot(kbin,C4E,label='4 arcmin$^{-1}$')
    ax.plot(kbin,C6E,label='6 arcmin$^{-1}$')
    ax.semilogx()
    ax.semilogy()
    ax.legend()
    ax.set_xlabel(r'k [arcsec$^{-1}$]')
    ax.set_ylabel('Normalized Power')
