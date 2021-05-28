# -*- coding: utf-8 -*-
"""
Functions for creating and manipulating graphics, colormaps and plots.
@author: Joseph Barraud, Geophysics Labs.
Update:
         Juan Macias-Perez, Nov 2017
"""
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.cm as cm
from skimage import exposure

#===============================================================================
# cmap_to_array
#===============================================================================
def cmap_to_array(cmap,N=256):
    """
    Return a Nx3 array of RGB values generated from a colormap.
    """
    return cmap(np.linspace(0, 1, N))[:,:3] # remove alpha column


#===============================================================================
# equalizeColormap
#===============================================================================
def equalizeColormap(cmap,bins,cdf,name='EqualizedMap'):
    '''
    Re-map a colormap according to a cumulative distribution. This is used to 
    perform histogram equalization of an image by changing the colormap 
    instead of the image. *This is not strickly speaking the equalization of the 
    colormap itself*.
    The cdf and bins should be calculated from an input image, as if carrying out
    the histogram equalization of that image. In effect, the cdf becomes integrated  
    to the colormap as a mapping function by redistributing the indices of the
    input colormap.
    
    Parameters
    ----------
    cmap : string or colormap object
        Input colormap to remap.
    bins : array
        Centers of bins.
    cdf : array
        Values of cumulative distribution function.
    '''
    
    # first retrieve the color table (lists of RGB values) behind the input colormap
#    if cmap in colors.datad: # one of the additional colormaps in colors module
#        cmList = colors.datad[cmap]
#    elif cmap in cm.cmap_d: # matplotlib colormaps + plus the new ones (viridis, inferno, etc.)

    cmList = cmap_to_array(cm.cmap_d[cmap])
#   else:
#       try:
#           # in case cmap is a colormap object
#           cmList = cmap_to_array(cmap) 
#        except:
#            raise ValueError('Colormap {} has not been recognised'.format(cmap))
    
    # normalize the input bins to interval (0,1)
    bins_norm = (bins - bins.min())/np.float(bins.max() - bins.min())
    
    # calculate new indices by applying the cdf as a function on the old indices
    # which are initially regularly spaced. 
    old_indices = np.linspace(0,1,len(cmList))
    new_indices = np.interp(old_indices,cdf,bins_norm)
    
    # make sure indices start with 0 and end with 1
    new_indices[0] = 0.0
    new_indices[-1] = 1.0
    
    # remap the color table
    cdict = {'red': [], 'green': [], 'blue': []}
    for i,n in enumerate(new_indices):
        r1, g1, b1 = cmList[i]
        cdict['red'].append([n, r1, r1])
        cdict['green'].append([n, g1, g1])
        cdict['blue'].append([n, b1, b1])
        
    return mcolors.LinearSegmentedColormap(name, cdict)
   
#===============================================================================
# normalizeColormap
#===============================================================================
def normalizeColormap(cmapName,norm='autolevels',**kwargs):
    '''
    Apply a normalising function to a colormap. Only "autolevels" is implemented
    for the moment.
    
    **kwargs are passed to the normalising function.
    '''
    try:
        cmap = cm.get_cmap(cmapName) # works even if cmapName is already a colormap
    except:
        # colormap is one of the extra ones added by the colors module 
        cmap = load_cmap(cmapName)
        
    # convert cmap to array for normalisation
    cmList = cmap_to_array(cmap)
    
    # normalise
    if norm == 'autolevels':
        cmList_norm = autolevels(cmList,**kwargs)
    else:
        cmList_norm = cmList
        
    # create new colormap
    new_cm = mcolors.LinearSegmentedColormap.from_list(cmap.name + '_n', cmList_norm)
    
    return new_cm

def cmap_equalize(data,cmap):
    cdf, bins = exposure.cumulative_distribution(data[~np.isnan(data)].flatten(),nbins=256)
    my_cmap = equalizeColormap(cmap,bins,cdf)
    return my_cmap
