from __future__ import print_function  
import numpy as np
import matplotlib.pyplot as plt
from astropy import wcs
from astropy.io import fits



class n2map():
    """
    First class to store a simple square map
    This is just a simplified version to start working with Lab data
    """
    
    def __init__(self,xcenter,ycenter,pixsize,
                 nxpixels=-1,nypixels=-1,xmapsize=-1,ymapsize=-1, proj='CAR',lab=0):
        """
        
        """
        self.pixsize = pixsize
        self.xcenter = xcenter
        self.ycenter = ycenter
        self.lab = lab
        self.proj = proj
        if nxpixels != -1:
            self.nxpixels = nxpixels
            self.xmapsize = self.pixsize * self.nxpixels
            if nypixels ==-1:
                nypixels = nxpixels
            self.nypixels = nypixels
            self.ymapsize = self.nypixels * self.pixsize
        else:
            if nypixels != -1:
                nxpixels = nypixels
                self.nxpixels = nypixels
                self.nypixels = nypixels
                self.xmapsize = self.nxpixels*self.pixsize
                self.ymapsize = self.nypixels*self.pixsize
                
        if xmapsize != -1:
            self.xmapsize = xmapsize
            self.nxpixels = np.long(xmapsize/pixsize)
            if ymapsize != -1:
                self.nypixels = np.long(ymapsize/pixsize)
            else:
                self.nypixels = self.nxpixels
        if (self.nxpixels != -1) & (self.nypixels != -1):         
            self.map = np.zeros((self.nxpixels,self.nypixels),dtype=np.float)
            self.nhits = np.zeros((self.nxpixels,self.nypixels),dtype=np.float)
            self.set_wcs(nxpixels,nypixels,xcenter,ycenter,pixsize)
        else:
            print("Not correct data")
            return 

        return

    
    def set_wcs(self,nxpixels,nypixels,xcenter,ycenter,pixsize):
        """
        Create wcs object to describe map
        """
        self.WcS = wcs.WCS(naxis=2)        
        self.WcS.wcs.crpix = [self.nxpixels/2,self.nypixels/2]
        if self.lab == 1:
            self.WcS.wcs.cdelt = np.array([self.pixsize,self.pixsize])
            self.proj = 'CAR'
        else:
            self.WcS.wcs.cdelt = np.array([-self.pixsize,self.pixsize])
        self.WcS.wcs.crval = [self.xcenter, self.ycenter]
        self.WcS.wcs.ctype = ["RA---"+self.proj, "DEC--"+self.proj]
        #self.WcS.wcs.set_pv([(2, 1, 45.0)])

        return

    
class n2map_projector():
    """
    Define a simple TOD class to include pointing properties
    """

    def __init__(self,tod,pos_x, pos_y,mn2map):
        """
        Create a specific spectral TOD including spectrum 
        information and pointing 
        """
        self.spec_tod = spec_tod
        self.freq = freq
        self.n2map
        self.pos_x
        self.pos_y
        self.pointing2coord()
        return

    def pointing2coord(self):
        """
        Compute 
        """
        self.pixpos =  self.n2map.wcs.wcs_world2pix(self.pos_x, self.pos_y,0)
        return

    def coadd(self):

        
        okpix = np.unique()
        
            
        return
    
    
