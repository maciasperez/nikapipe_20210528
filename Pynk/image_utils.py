import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
from astropy.io import fits
from astropy import wcs
from astropy import units as u
import astropy.coordinates as coord
import process_1d as u1d
import pdb



class container():
    pass

dummy = container()

class image2d(object):
    """A simple image class"""
    file = ""
    nx   = 0
    ny   = 0
    map  = []
    var = []
    tobs = []
    hdu = []
    wc  = []
    nika = 0
    mask = None
    
 
    def __init__(self,file='',nx=0,ny=0,map=[],hdu=[],wc=[],ra=[],dec=[]):
        self.file = file
        self.nx  =  nx
        self.ny  =  ny
        self.hdu = hdu
        self.map = map
        self.wc  = wc
        self.ra  = ra
        self.dec = dec
        self.nika = 0


    def read_image(self, file,nika=0):
        """
        Purpose:
                 Read image from fits file
        Inputs:
                 Image object
                 file : name of image file
        Comments:
                
        """
        self.file = file
        self.hdu = fits.open(file)
 #       try:
        try:
            self.map = self.hdu[0].data
            self.var = self.hdu[1].data
            self.tobs = self.hdu[2].data
            self.nika=1
            self.define_mask()
        except:
            try:
                self.map = self.hdu[0].data
            except:
                self.map = self.hdu[0].data
        self.wc = wcs.WCS(file)
  #       self.nx = self.wc.naxis1
 #       self.ny = self.wc.naxis2
        self.nx, self.ny = (self.map).shape
        ix =  np.outer(np.arange(self.nx),np.zeros(self.ny).T+1)
        iy =  np.outer(np.zeros(self.nx)+1,np.arange(self.ny).T)
        self.ra,self.dec = self.wc.all_pix2world(ix,iy,0)

    def read_nika_map(self, file,index=1):
        """
        Purpose:
                 Read image from nika combined fits file
        Inputs:
                 file : name of image file
                 index: index concerning the map you want to plot
        Comments:
                
        """
        self.file = file
        self.hdu = fits.open(file)
 #       try:
        try:
            self.map = self.hdu[index].data
            self.var = self.hdu[index+1].data
            self.tobs = self.hdu[index+2].data
            self.nika=1
            self.define_mask()
        except:
            print "Wrong index for nika map fits file"
            
        self.wc = (wcs.WCS(self.hdu[index].header)).celestial
  #       self.nx = self.wc.naxis1
 #       self.ny = self.wc.naxis2
        self.nx, self.ny = (self.map).shape
        ix =  np.outer(np.arange(self.nx),np.zeros(self.ny).T+1)
        iy =  np.outer(np.zeros(self.nx)+1,np.arange(self.ny).T)
        self.ra,self.dec = self.wc.all_pix2world(ix,iy,0)

        
    def define_mask(self):
        if self.nika:
            self.mask = np.where(self.var > 0.0)
            self.mask = self.mask[0]

    def get_galcoord(self):
        mycoord = coord.ICRS(ra=self.ra*u.degree,dec=self.dec*u.degree)
        return  mycoord.transform_to(coord.GalacticCoordinates)
        
    def set_data(self,arr):
        """
        Purpose: 
                 Replace map in the 2D image class
        Inputs:
                 arr :: matrix(nny,nnx)
        Comments:
                 Notice that arrays in the 2D image class are transposed 
                 with respect to the expected sizes
        """
 
        nnx,nny = arr.shape
        if self.ny == nnx and self.nx== nny: 
            self.map = arr
        else:
            print "Wrong size of image"

    def dispim_bar(self,cmap='rainbow',scale='linear',crange=[-1,-1],aspect=1):
        """
           Purpose:
                   
        """
        if crange[0] == crange[1] : self.crange = [self.map.min(),self.map.max()]
        self.cmap = cmap
        self.scale = scale
        self.aspect = aspect
        self.fig1 = plt.figure()
        try:
            self.ax1 = self.fig1.add_subplot(111,projection=self.wcs)
        except:
            self.ax1 = self.fig1.add_subplot(111)
            
        self.fig2 = plt.figure()

        # do a cross in x and y
        try:
            self.ax2 = self.fig2.add_subplot(111,projection=self.wcs)
        except:
            self.ax2 = self.fig2.add_subplot(111)
            

        self.ims =self.ax1.imshow(self.map,vmin=self.crange[0],vmax=self.crange[1],aspect=aspect,cmap=cmap)
        self.cb=self.fig1.colorbar(self.ims)
        self.fig1.canvas.draw()
        self.imscid=self.fig1.canvas.mpl_connect('button_press_event',self.onpress)
        self.imsmot=self.fig1.canvas.mpl_connect('motion_notify_event',self.onmotion)
        self.imsrel=self.fig1.canvas.mpl_connect('button_release_event',self.onrelease)
        self.rect=self.ax1.add_patch(Rectangle((0,1), 0.01, 0.01,alpha=1,facecolor='none'))

        self.im2 =self.ax2.imshow(self.map,vmin=self.crange[0],vmax=self.crange[1],aspect=aspect,cmap=cmap)
        self.cb2=self.fig2.colorbar(self.im2)
        self.fig2.canvas.draw()
        self.imscid2=self.fig2.canvas.mpl_connect('button_press_event',self.onpress2)


    def onpress2(self,event):
        if event.button!=1: return
        xz,yz = event.ydata, event.xdata
        self.rect_xlt, self.rect_ylt = event.xdata,event.ydata
        print xz,yz
        return

    def onpress(self,event):
        if event.button!=1: return
        self.onpress1 = 1
        self.rect_xlt, self.rect_ylt = event.xdata,event.ydata
        return
       
    def onmotion(self,event):
 #       print "on motion"
        if self.onpress1:
            self.rect_xrb, self.rect_yrb = event.xdata,event.ydata
            x0 =np.min(np.array([np.long(self.rect_xlt),np.long(self.rect_xrb)]))
            x1 =np.max(np.array([np.long(self.rect_xlt),np.long(self.rect_xrb)]))
            y0 =np.min(np.array([np.long(self.rect_ylt),np.long(self.rect_yrb)]))
            y1 =np.max(np.array([np.long(self.rect_ylt),np.long(self.rect_yrb)]))

            width  = np.abs(np.float(self.rect_xrb) -  np.float(self.rect_xlt))
            height = np.abs(np.float(self.rect_yrb) - np.float(self.rect_ylt) )
            self.rect.set_xy((x0,y0))
            self.rect.set_width(width)
            self.rect.set_height(height)
            self.fig1.canvas.draw()
#        else:
#            continue
#            print "Current position"
#            print event.xdata,event.ydata

        return

    def onrelease(self, event):
        print "on realese"

        self.rect_xrb, self.rect_yrb = event.xdata,event.ydata
        x0 =np.min(np.array([np.long(self.rect_xlt),np.long(self.rect_xrb)]))
        x1 =np.max(np.array([np.long(self.rect_xlt),np.long(self.rect_xrb)]))
        y0 =np.min(np.array([np.long(self.rect_ylt),np.long(self.rect_yrb)]))
        y1 =np.max(np.array([np.long(self.rect_ylt),np.long(self.rect_yrb)]))

        width  = np.abs(np.float(self.rect_xrb) -  np.float(self.rect_xlt))
        height = np.abs(np.float(self.rect_yrb) - np.float(self.rect_ylt) )
        self.rect.set_xy((x0,y0))
        self.rect.set_width(width)
        self.rect.set_height(height)
        self.fig1.canvas.draw()
 
        # zoom on second window
        print "ZOOM"
        tmap =  self.map[x0:x1,y0:y1]
        print x0,x1,y0,y1
        print tmap.shape
        cr= (tmap.min(),tmap.max())
        self.im2.set_data(tmap)
        self.im2.set_clim(cr)
        self.fig2.canvas.draw()

        self.rect.set_xy((0,1))
        self.rect.set_width(0.01)
        self.rect.set_height(0.01)
        self.fig1.canvas.draw()
        self.onpress1 = 0
        return
 
         
    def extract_patch(self,ra_center,dec_center,ra_size,dec_size,inpixsize=0):
   
        """
           Purpose: extract patch from map
           
        """
        #center_coord =  coord.ICRS(ra=ra_center*u.degree,dec=dec_center*u.degree)
        #mycoord = coord.ICRS(ra=self.ra*u.degree,dec=self.dec*u.degree)
#        reso = np.abs(self.wc.wcs.cdelt)
#        resodist = np.sqrt(reso[0]**2+reso[1]**2)*3600.0 
#        dist = gcirc(ra_center,dec_center,self.ra,self.dec,2)
#        mindist = np.min(dist)
#       pdb.set_trace()
#       if (mindist <= 2.0*resodist):
#            pos = np.where(dist == np.min(dist))
#            xcenter = pos[0]
#            ycenter = pos[1]

        # get position in the center of the map
        patch = []
        inmap = 0

        xcenter,ycenter  = self.wc.wcs_world2pix(ra_center,dec_center,0)
        xcenter = np.int(xcenter)
        ycenter = np.int(ycenter)
        xcenter -=1
        ycenter -=1
        if xcenter >= 0: 
         if  ycenter >=0:
          if xcenter < self.nx:
           if ycenter < self.ny:

            if inpixsize :
                px = ra_size
                py = dec_size
            else:
                print "Working on it "
                # need to correct for this, it is wrong so far
                #px = np.long(ra_size/reso[0])
                #py = np.long(dec_size/reso[1])
                
  
            oix = (xcenter - np.long(px/2)) 
            if oix < 0: 
                ix = 0
            else:
                ix = oix
                oix = 0
                
            oex = (xcenter + np.long(px/2)) 
            if oex > self.nx-1: 
                ex = self.nx-1
            else:
                ex = oex
            px = ex-ix

            oiy = ycenter - np.long(py/2) 
            if oiy < 0: 
                iy = 0
            else:
                iy = oiy
                oiy = 0

            oey = ycenter + np.long(py/2) 
            if oey > self.ny-1: 
                ey = self.ny-1
            else:
                ey = oey
            py = ey - iy 

 #           pdb.set_trace()
            pmap = (self.map.T)[ix:ex,iy:ey]
        
            wc = wcs.WCS(naxis=2)
            

            wc.wcs.crpix = np.array([np.long(px/2)+np.long(1)+oix,np.long(py/2)+np.long(1)+oiy])
            wc.wcs.cdelt = self.wc.wcs.cdelt
            wc.wcs.crval = np.array([ra_center,dec_center])
            wc.wcs.ctype = self.wc.wcs.ctype
            
            wc.naxis1 = px
            wc.naxis2 = py
  
            ix =  np.outer(np.arange(px),np.zeros(py).T+1)
            iy =  np.outer(np.zeros(px)+1,np.arange(py).T)
 #           pdb.set_trace()
            ra,dec = wc.all_pix2world(ix,iy,0)
            patch = image2d(file,px,py,pmap.T,[],wc,ra,dec)

            inmap = 1
#        pdb.set_trace()
        return inmap,patch


    def mappixel2coord(self,px,py):
        return self.ra.T[px,py],self.dec.T[px,py]
        
 # ADD astrometry to image if you do not have it yet
 
    def add_astrometry(self,cdelt,crpix,crval,ctype):
    
        wc = wcs.WCS(naxis=2)
        wc.wcs.crpix = crpix
        wc.wcs.cdelt = cdelt
        wc.wcs.crval = crval
        wc.wcs.ctype = ctype

        [py,px] = self.map.shape()
        wc.naxis1 = px
        wc.naxis2 = py

        ix =  np.outer(np.arange(px),np.zeros(py).T+1)
        iy =  np.outer(np.zeros(px)+1,np.arange(py).T)
        ra,dec = wc.all_pix2world(ix,iy,0)
        return
       
 # Compute radial profile       
    def radial_profile(self,ra_center,dec_center,rbintab=-1,deltar=-1,nrbintab = 10):
        
        """
            Purpose:
                      Compute radial profile of map at position ra_center, dec_center
            Input:
                      ra_center  :: center RA  (degrees) 
                      dec_center :: center DEC (degrees)
        
        """
        # compute distance in arcmin
        reso = np.abs(self.wc.wcs.cdelt)
        resodist = np.sqrt(reso[0]**2+reso[1]**2)*60.0 
        dist = gcirc(ra_center,dec_center,self.ra,self.dec,2)/60.0
        mindist = np.min(dist)
        # define parameters
        if (rbintab == -1) :
             if deltar == -1 :
                 deltar = 1.0

             rbintab = np.zeros(nrbintab)
             for ibin in range(nrbintab):
                 rbintab[ibin] = np.float(ibin) *  deltar
        else:
             if rbintab[0] !=0.0:
                 rbintab = np.concatenate([np.array([0.0]),rbintab])

        nbins = rbintab.size

        rad_pr = np.zeros(nbins-1)-1.0
        rad_pr_s = np.zeros(nbins-1)-1.0
        rcenter =  np.zeros(nbins-1)-1.0

        if (mindist <= 2.0*resodist):

            for ibin in range(nbins-1):
                rcenter[ibin] = (rbintab[ibin]+rbintab[ibin+1])/2.0
                pos = np.where(np.logical_and(dist >= rbintab[ibin], dist < rbintab[ibin+1]))
#                pdb.set_trace()
                if pos[0].size > 0 :
                    if pos[1].size > 0:
                        arr = self.map.T[pos[0][:],pos[1][:]]
                        rad_pr[ibin]   = np.mean(arr)
                        rad_pr_s[ibin] = np.std(arr)/np.sqrt(np.double(pos[0].size))
 
        return rcenter,rad_pr,rad_pr_s


    def histo1d(self, tplot=0,tbins=10,tgfit=0):
        arr = self.map.reshape(self.nx*self.ny)
        xr,yr,gc,sgc = u1d.histo_make(arr,bins=tbins,plot=tplot,gfit=tgfit)
        return xr,yr

    def clip(self,threshold=5.0,pos=1,neg=1,tbins=100):
        """
           Clip image to a given threshold
        """
        arr = self.map.reshape(self.nx*self.ny)
        xr,yr,gc,sgc = u1d.histo_make(arr,bins=tbins,plot=0,gfit=1)
        if pos:
            p = np.where((self.map-gc[1]) > threshold * gc[2])
            if p[0].size > 0:
                self.map[p[0],p[1]] = gc[1] + gc[2] * np.random.normal(0.0,1.0)
        if neg:
            p = np.where((self.map-gc[1]) < (-1.0*threshold * gc[2]))
            if p[0].size > 0:
                self.map[p[0],p[1]] = gc[1] + gc[2] * np.random.normal(0.0,1.0,p[0].size)
        return


### EXTERNAL FUNCTIONS 

def load_image(filename):
    im = image2d()
    im.read_image(filename)
    return im



def gcirc(ra1,dc1,ra2,dc2,tunits):
    """
       Comments: Updated from IDL gcirc routine in astron
       Purpose: 
       Input:
       Output:
    """
    d2r    = np.pi/180.0
    as2r   = np.pi/648000.0
    h2r    = np.pi/12.0

# Convert input to double precision radians
    # radians
    if (tunits == 0) : 
          rarad1 = double(ra1)
          rarad2 = double(ra2)
          dcrad1 = double(dc1)
          dcrad2 = double(dc2)
    # decimal hours
    if (tunits == 1) :
          rarad1 = ra1*h2r
          rarad2 = ra2*h2r
          dcrad1 = dc1*d2r
          dcrad2 = dc2*d2r
    #decimal degrees
    if (tunits == 2) :
          rarad1 = ra1*d2r
          rarad2 = ra2*d2r
          dcrad1 = dc1*d2r
          dcrad2 = dc2*d2r

    deldec2 = (dcrad2-dcrad1)/2.0
    delra2 =  (rarad2-rarad1)/2.0
    sindis = np.sqrt( np.sin(deldec2)*np.sin(deldec2) + np.cos(dcrad1)*np.cos(dcrad2)*np.sin(delra2)*np.sin(delra2) )
    dis = 2.0*np.arcsin(sindis) 

    if tunits != 0:
        dis = dis/as2r
    return dis
