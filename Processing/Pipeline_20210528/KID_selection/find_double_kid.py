from scipy import signal
import numpy as np

from astropy.io import fits
import astropy.units as u
import os
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib import ticker
import numdifftools as nd
from scipy.interpolate import interp1d
import scipy.optimize as optimization
import scipy.constants as spconst
import astropy.constants as const
import pdb
import scipy.ndimage.filters
import time


def double_finder(maptemplate,mapKID,thresh=250,noise=None,calibrate=0):

    
    corr = np.correlate(maptemplate.flatten(),mapKID.flatten(),'full')
    #box = np.ones(193)/193
    #y_smooth = np.convolve(corr, box, mode='same')

    #pdb.set_trace()

    if calibrate:
        if noise is not None:
            #wpeak = np.where(np.abs(np.gradient(y_smooth)) > noise)
            #wpeak = np.where(y_smooth > noise)
            #gradsmooth = np.convolve(np.abs(np.gradient(y_smooth)), box, mode='same')
            #wpeak = np.where(gradsmooth > noise)
            
            wpeak = np.where(corr > noise)
            
            return len(wpeak[0])
        else:
            #wnonzero = np.where(y_smooth > 1e-8)
            #noise_lev = np.median(y_smooth[wnonzero])
            #return 5.*np.mean(np.abs(np.gradient(y_smooth)))

            #gradsmooth = np.convolve(np.abs(np.gradient(y_smooth)), box, mode='same')
            #wnonzero = np.where(np.abs(np.gradient(y_smooth)) > 1e-8)
            #noise_lev = 5.*np.median(gradsmooth[wnonzero])

            wnonzero = np.where(corr > 1e-8)
            noise_lev = 5.*np.mean(corr[wnonzero])
            
            return noise_lev
    else:
        #wpeak = np.where(np.abs(np.gradient(y_smooth)) > noise)
        #wpeak = np.where(y_smooth > noise)

        #gradsmooth = np.convolve(np.abs(np.gradient(y_smooth)), box, mode='same')
        #wpeak = np.where(gradsmooth > noise)

        wpeak = np.where(corr > noise)

        if len(wpeak[0]) > thresh:
            return 1
        else:
            return 0
        
    
