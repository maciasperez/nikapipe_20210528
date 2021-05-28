#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Tue Mar 17 09:27:37 2020

@author: macias
"""

import numpy as np
from aplpy import FITSFigure
from astropy.convolution import convolve
from astropy.convolution import Gaussian2DKernel
import astropy.units as u

class map_plot(FITSFigure):
  
  def __init__(self,data, vmin=None, vmax=None, cmap = 'jet', hdu=0, figure=None, subplot=(1, 1, 1), downsample=False, north=False, 
          convention=None, dimensions=[0, 1], slices=[], auto_refresh=None, **kwargs):
    FITSFigure.__init__(self,data, hdu, figure, subplot, downsample, north, 
          convention, dimensions, slices, auto_refresh, **kwargs)
    self._dataorg = np.copy(self._data)
    if vmin == None:
      vmin = np.min(self._data)
    if vmax == None:
      vmax = np.max(self._data)
    self.show_colorscale(vmin=vmin,vmax=vmax,cmap = cmap)
    self.add_colorbar()
    self.add_grid()
    self.grid.set_color('black')
    self.grid.set_linewidth(2)
  
    return
  
  def rescale_image(self,rfact):
    self._data = rfact * self._dataorg
    
    return
  
  def back2org(self):
    vmin, vmax = self.image.get_clim()
    self._data = self._dataorg
    return
  
  def clim(self,lims):
    """
    Set limits for figure
  
    """
    if isinstance(lims,list):
      if len(lims) != 2: return
    elif isinstance(lims,np.ndarray):
      if (len(lims) != 2) or (lims.ndim !=1): return   
    else:
      return
    
    self.image.set_clim(lims)
    return

  def gsmooth(self, fwhm, units=u.arcsec):
    """
    Smear out map using Gaussian kernel
    
    Parameters:
    -----------
    - fwhm (double)
      FWHM in arcsecs if units not given
      
    - units: atropy units optional
    
    """
    fwhm2sigma = 1.0/(2.0 * np.sqrt((2 * np.log(2))))
    deg_sigma = fwhm*fwhm2sigma*units.to(u.deg)
    pix_sigma = deg_sigma / self._wcs.wcs.cdelt[1]
    self.filter_image(pix_sigma)
    
    return
 
  def filter_image(self,par_filter,method='GAUSSIAN'):
    """
    This filter the image as asked.
    We can use different methods for filtering
    
    Parameters
    ----------
    - par_filter ()
      paramters for the different filters
      
    - method: optional, default GAUSSIAN
      
    Output
    ------
    Modify directly the internal class data
    """
    vmin, vmax = self.image.get_clim()    
    cmap = self.image.get_cmap()

    if method == 'GAUSSIAN':
      pix_sigma = par_filter
      kernel = Gaussian2DKernel(pix_sigma)
      self._data = convolve(self._dataorg, kernel)
      self.show_colorscale(vmin=vmin,vmax=vmax,cmap=cmap)
     
    return
  
  # 15, 99, 211, 213
  # param 