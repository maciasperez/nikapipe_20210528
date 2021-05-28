#+
# SOFTWARE:
#         NIKA SZ pipeline
#
# NAME: 
#         map_display
#
# CATEGORY:
#
# CALLING SEQUENCE:
#         map_display(file, *kwords)
# 
# PURPOSE: 
#        displays the map contained in a fits file and adds some information on it (beam, ruler, contours, ...)
# 
# INPUT: 
#        the name of the fits file and the file index to read
# 
# OUTPUT: 
#        a window with the map displayed and (if asked with the save keyword) a file (pdf, png, ...) containing the final image
# 
# KEYWORDS:
#        - smooth is the 2D Gaussian kernel FWHM in arcsec for the map
#        - file_cont is the path to a contour map
#        - smooth_cont is the 2D Gaussian kernel FWHM in arcsec for the contour map
#        - col_cont is the color of the contours
#        - range is the colorbar range
#        - conts is an array of values defining the contours
#        - xrange is an array defining the x-axis edges of the map to display in pixel value
#        - yrange is an array defining the y-axis edges of the map to display in pixel value
#        - scale is the number by which to multiply the input map
#        - title is the title of the map
#        - beam is the beam FWHM to display as a white disk on the map
#        - beam_offset is the shift to apply in arcsec to move the beam center toward the center of the map
#        - ruler is the length (in arcsec) of a ruler to display in the corner of the map
#        - ruler_label is the label to display next to the ruler (the equivalent distance in pc, kpc, Mpc, ...)
#        - col_ruler is the color of the ruler and its label
#        - region is a string containing the ds9 region file content
#        - Xcenter are the equatorial coordinates of a point to display on the map
#        - colorbar is set to 1 if you want to display a colorbar
#        - c_title is the label associate to the colorbar
#        - size_c_title is the size of the colorbar label
#        - colormap is the kind of colormap you want to use (either 'NIKA' or 'Planck')
#        - save is the name of the file (with its extansion) in which you want to save the final image
#        - show is set to 1 if you want to see a window open with the final map
# 
# MODIFICATION HISTORY: 
#        July 16th, 2016: Creation by F. Ruppin (ruppin@lpcs.in2p3.fr)
#        Oct,       2017: Modified to make it easier to user
#-

import matplotlib.pyplot as plt
import matplotlib.colors as col
import numpy as np
from astropy.io import fits
from matplotlib.colors import ListedColormap
from astropy.convolution import convolve
from astropy.convolution import Gaussian2DKernel
from math import sqrt
from astropy.wcs import WCS
from matplotlib.patches import Ellipse
from matplotlib.patches import Rectangle
import pyregion
import os
import matplotlib.cm as cm
import scipy.ndimage.filters
import pdb
from scipy import ndimage


def map_display(file,index,smooth=0,file_cont='',smooth_cont=0,col_cont='black',file_cont2='',smooth_cont2=0,col_cont2='black',rangecol=0,conts=[-100,100],conts2=[-100,100],
                xrange=0,yrange=0,scale=1,title='',beam=0,beam_offset=0,ruler=0,ruler_label='',col_ruler='black',region='',Xcenter=0,colorbar=1,c_title='',size_c_title=12,
                colormap='NIKA',save='',show=1,linewidths=1,linewidths2=1,index_cont=0,index_cont2=0,grid=0,is_hdu=0,is_hdu_cont=0,noclose=0,figsize=(10,10)):
    
    """
    =====================================================================================================
    Parameters
    ----------
    - file:  the path to a fits file containing the map to display
    - index: the fits index to be read

    Keywords
    --------
    - smooth:       the 2D Gaussian kernel FWHM in arcsec for the map
    - file_cont:    the path to a contour map
    - smooth_cont:  the 2D Gaussian kernel FWHM in arcsec for the contour map
    - col_cont:     the color of the contours
    - rangecol:     the colorbar range
    - conts:        an array of values defining the contours
    - xrange:       an array defining the x-axis edges of the map to display in pixel value
    - yrange:       an array defining the y-axis edges of the map to display in pixel value
    - scale:        the number by which to multiply the input map
    - title:        the title of the map
    - beam:         the beam FWHM to display as a white disk on the map
    - beam_offset:  the shift to apply in arcsec to move the beam center toward the center of the map
    - ruler:        the length (in arcsec) of a ruler to display in the corner of the map
    - ruler_label:  the label to display next to the ruler (the equivalent distance in pc, kpc, Mpc, ...)
    - col_ruler:    the color of the ruler and its label
    - region:       a string containing the ds9 region file content
    - Xcenter:      the equatorial coordinates of a point to display on the map
    - colorbar:     set to 1 if you want to display a colorbar
    - c_title:      the label associate to the colorbar
    - size_c_title: the size of the colorbar label
    - colormap:     the kind of colormap you want to use (either 'NIKA', 'Planck', 'XMM_I' or 'Temperature')
    - save:         the name of the file (with its extansion) in which you want to save the final image
    - show:         set to 1 if you want to see a window open with the final map
    - index_cont:   the fits index to be read for the contour file
    - grid:         set to 1 if you want to display the coordinate grid on the map
    =====================================================================================================
    """

    if noclose ==0:
	plt.close("all")
    
    if colormap == 'NIKA':
        cmap = ListedColormap(np.loadtxt(os.environ['NIKA_PIPELINE']+"/Pynk/Colormaps/nika_cmap.txt")/255.)
    elif colormap == 'Planck':
        cmap = ListedColormap(np.loadtxt(os.environ['NIKA_PIPELINE']+"/Pynk/Colormaps/planck_cmap.txt")/255.)
    elif colormap == 'XMM_I':
        cmap = ListedColormap(np.loadtxt(os.environ['NIKA_PIPELINE']+"/Pynk/Colormaps/xmm_cmap.txt")/255.)
    elif colormap == 'Temperature':
        cmap = ListedColormap(np.loadtxt(os.environ['NIKA_PIPELINE']+"/Pynk/Colormaps/temperature_cmap.txt")/255.)
    elif colormap == 'Pointsource':
        cmap = ListedColormap(np.loadtxt(os.environ['NIKA_PIPELINE']+"/Pynk/Colormaps/pointsource.txt")/255.)
    elif colormap == 'GGM':
        cmap = ListedColormap(np.loadtxt(os.environ['NIKA_PIPELINE']+"/Pynk/Colormaps/ggm_cmap.txt")/255.)
    elif colormap == 'DoG':
        cmap = ListedColormap(np.loadtxt(os.environ['NIKA_PIPELINE']+"/Pynk/Colormaps/dog_cmap.txt")/255.)
    else:
        cmap = colormap
        
    if is_hdu == 0:
      hdulist = fits.open(file)
    else:
      hdulist = file
      
    wcs = (WCS(hdulist[index].header)).celestial
    image_data = hdulist[index].data
    
    if (np.asarray(image_data.shape)).size != 2:
        nx = hdulist[index].header['NAXIS2']
        ny = hdulist[index].header['NAXIS1']
        image_data = np.reshape(image_data,(nx,ny))
        
    fig = plt.figure(figsize=figsize)
    ax = fig.add_subplot(1, 1, 1, projection=wcs)
    
    if xrange == 0:
        xmin = -0.5
        xmax = image_data.shape[1] - 0.5
    else:
        xmin = xrange[0]
        xmax = xrange[1]
          
    if yrange == 0:
        ymin = -0.5
        ymax = image_data.shape[1] - 0.5
    else:
        ymin = yrange[0]
        ymax = yrange[1]
        
    ax.set_xlim(xmin,xmax)
    ax.set_ylim(ymin,ymax)
    
    if region != "":
        head_fits = wcs.to_fits()
        head = head_fits[0].header
        r2 = pyregion.parse(region).as_imagecoord(head)
        patch_list, artist_list = r2.get_mpl_patches_texts()
        for p in patch_list:
            ax.add_patch(p)
        for t in artist_list:
            ax.add_artist(t)
    
    if smooth != 0:
        pix_size = hdulist[index].header['CDELT2'] * 3600.
        pix_sigma = smooth/(pix_size * 2 * sqrt((2 * np.log(2))))
        kernel = Gaussian2DKernel(pix_sigma)
        image_plot = convolve(image_data, kernel)
    else:
        image_plot = image_data
        
    image_plot *= scale
    
    if rangecol != 0:
        vmin = rangecol[0]
        vmax = rangecol[1]
    else:
        vmin = image_plot.min()
        vmax = image_plot.max()
        
    plt.imshow(image_plot, cmap=cmap, origin='lower',vmin=vmin,vmax=vmax)

    plt.rc('text', usetex=True)

    if ((hdulist[index].header['CTYPE1'] == 'RA---TAN') & (hdulist[index].header['CTYPE2'] == 'DEC--TAN')) | ((hdulist[index].header['CTYPE1'] == 'RA---SIN') & (hdulist[index].header['CTYPE2'] == 'DEC--SIN')) | ((hdulist[index].header['CTYPE1'] == 'RA---SFL') & (hdulist[index].header['CTYPE2'] == 'DEC--SFL')):
        plt.xlabel(r'\textbf{Right Ascension (J2000)} [hr]')  
        plt.ylabel(r'\textbf{Declination (J2000)} [degree]')
        lon = ax.coords['ra']
        lat = ax.coords['dec']
        lon.set_major_formatter('hh:mm:ss')
        lat.set_major_formatter('dd:mm:ss')

    if ((hdulist[index].header['CTYPE1'] == 'GLON-TAN') & (hdulist[index].header['CTYPE2'] == 'GLAT-TAN')):
        plt.xlabel(r'\textbf{Galactic Longitude} [degree]')  
        plt.ylabel(r'\textbf{Galactic Latitude} [degree]')

    if title != '':
        plt.title(r'\textbf{%s}'%(title))
        
    if colorbar == 1:
        cbar = plt.colorbar(pad=0.02,aspect=26)
        cbar.set_label(r'%s'%(c_title),labelpad=10,size=size_c_title)
 
    if beam != 0:
        pix_size = hdulist[index].header['CDELT2'] * 3600.
        beam_plot = Ellipse((xmin + 0.65*beam/pix_size + beam_offset/pix_size, ymin + 0.65*beam/pix_size + beam_offset/pix_size), beam/pix_size, beam/pix_size, edgecolor='black', facecolor='white')
        ax.add_patch(beam_plot)
                
    if file_cont != '':
        if is_hdu_cont ==0:
	  hdulist_snr = fits.open(file_cont)
	else:
	  hdulist_snr = file_cont
        image_snr = hdulist_snr[index_cont].data
        wcs_snr = (WCS(hdulist_snr[index_cont].header)).celestial
        if smooth_cont != 0:
            pix_size_snr = hdulist_snr[index_cont].header['CDELT2'] * 3600.
            pix_sigma_snr = smooth_cont/(pix_size_snr * 2 * sqrt((2 * np.log(2))))
            kernel_snr = Gaussian2DKernel(pix_sigma_snr)
            image_snr_conv = convolve(image_snr, kernel_snr)
            ax.contour(image_snr_conv, transform=ax.get_transform(wcs_snr),levels=conts, colors=col_cont,zorder=1,linewidths=linewidths)
        else:
            ax.contour(image_snr, transform=ax.get_transform(wcs_snr),levels=conts, colors=col_cont,zorder=1,linewidths=linewidths)
    
    
            
    if grid == 1:
        ax.coords.grid(color='#00004d', alpha=0.5, linestyle='solid')
            
    if Xcenter != 0:  
        ax.scatter(Xcenter[0],Xcenter[1], transform=ax.get_transform('fk5'), s=30, edgecolor='white', facecolor='red', zorder=10000)

    if ruler != 0:
        pix_size = hdulist[index].header['CDELT2'] * 3600.
        Nx = hdulist[index].header['NAXIS1']
        r = Rectangle((xmax - 0.05*(xmax-xmin) - (ruler/pix_size), ymin + 0.05*(ymax-ymin)), ruler/pix_size, 0.0075*(ymax-ymin), edgecolor=col_ruler, facecolor=col_ruler)
        ax.add_patch(r)

    if ruler_label != '':
        ax.text(xmax - 0.05*(xmax-xmin) - (ruler/pix_size)/2., ymin + 0.025*(ymax-ymin),
                r'\textbf{%s}'%(ruler_label), ha="center", va="center",size=10,weight='bold',color=col_ruler)

    """fwhm2sig = 2.*np.sqrt(2.*np.log(2.))
    #file_NIKA2_SZ = '/Users/ruppin/Projects/NIKA/Soft/branch/Florian/FR/These/PSZ1G144/NIKA2/Final/PSZ2G144_MCMC_map_nosource.fits'
    file_NIKA2_SZ = '/Users/ruppin/Projects/NIKA/Soft/branch/Florian/FR/These/PSZ1G144/Paper_plots/PSZ2G144_model_GGM_subs.fits'
    file_NIKA2_SNR = '/Users/ruppin/Projects/NIKA/Soft/branch/Florian/FR/These/PSZ1G144/NIKA2/Final/PSZ2G144_SNR_map_nosource.fits'
    file_GGM_SNR = '/Users/ruppin/Projects/NIKA/Soft/branch/Florian/FR/These/PSZ1G144/NIKA2/Filter_maps/PSZ2G144_GGMmap_SNR.fits'
    hdusnr = fits.open(file_GGM_SNR)
    image_snr = hdusnr[0].data
    cut_GGM = 4.0
    radius_cut = 120.
    jump = 4
    power_spec_param = [86.27, -2.1, 1.15]
    Nsimu = 10000
    
    hdu = fits.open(file_NIKA2_SZ)
    nika2_map = hdu[0].data
    #rms_data = hdu[2].data
    
    hdusnr = fits.open(file_NIKA2_SNR)
    nika2_snr = hdusnr[0].data
    
    npix = nika2_map.shape[0]
    reso_arcmin = hdu[0].header['CDELT2']*60.
    reso_arcsec = hdu[0].header['CDELT2']*3600.
    nika2_map_smooth = 1000.*scipy.ndimage.filters.gaussian_filter(nika2_map,(18./reso_arcsec)/fwhm2sig)
    
    theta_tab = np.linspace(0.,npix*reso_arcsec,num=npix)
    xmap = (np.outer(theta_tab,np.ones(npix))).T - npix*reso_arcsec/2.
    ymap = (np.outer(theta_tab,np.ones(npix))) - npix*reso_arcsec/2.
    rmap = np.sqrt(xmap**2+ymap**2)

    kernel = np.array([[-1,0,1],[-2,0,2],[-1,0,1]])
    xggm = ndimage.convolve(scipy.ndimage.filters.gaussian_filter(1000.*nika2_map,(18./reso_arcsec)/fwhm2sig),(1./(8.*reso_arcmin))*kernel)
    yggm = ndimage.convolve(scipy.ndimage.filters.gaussian_filter(1000.*nika2_map,(18./reso_arcsec)/fwhm2sig),np.transpose((1./(8.*reso_arcmin))*kernel))
    
    GGMmap = scipy.ndimage.filters.gaussian_gradient_magnitude(1000.*nika2_map,(18./reso_arcsec)/fwhm2sig)/reso_arcmin
    
    X, Y = np.meshgrid(np.arange(0,npix,1), np.arange(0,npix,1))
    Xnew = X[::jump, ::jump]
    Ynew = Y[::jump, ::jump]
    wsig = np.where((image_snr[::jump, ::jump] > cut_GGM) & (rmap[::jump, ::jump] <= radius_cut) & (ymap[::jump, ::jump] <= 50.))
    #wsig = np.where((image_data[::jump, ::jump] > 1.4))
    ax.quiver(Xnew[wsig], Ynew[wsig], xggm[::jump, ::jump][wsig], yggm[::jump, ::jump][wsig],scale=65,headlength=0,headwidth = 1,pivot = 'middle',zorder=3,width=0.0025,color='#9e1434')"""

    




    if file_cont2 != '':
        hdulist_snr = fits.open(file_cont2)
        image_snr = hdulist_snr[index_cont2].data
        wcs_snr = (WCS(hdulist_snr[index_cont2].header)).celestial
        if smooth_cont2 != 0:
            pix_size_snr = hdulist_snr[index_cont2].header['CDELT2'] * 3600.
            pix_sigma_snr = smooth_cont2/(pix_size_snr * 2 * sqrt((2 * np.log(2))))
            kernel_snr = Gaussian2DKernel(pix_sigma_snr)
            image_snr_conv = convolve(image_snr, kernel_snr)
            ax.contour(image_snr_conv, transform=ax.get_transform(wcs_snr),levels=conts2, colors=col_cont2,zorder=2,linewidths=linewidths2)
        else:
            ax.contour(image_snr, transform=ax.get_transform(wcs_snr),levels=conts2, colors=col_cont2,zorder=4,linewidths=linewidths2)
            plt.imshow(image_snr, cmap=cmap, origin='lower', alpha=0.15)




    #ax.text(0.03, 0.93, r'\textbf{Iteration 1}',transform=ax.transAxes,color='#003E47', fontsize=16)

    
    #ax.arrow(80, 30, 23, 47, head_width=1, head_length=1, fc='#BA001F', ec='#BA001F')
    #ax.arrow(80, 30, 19, 42, head_width=1, head_length=1, fc='#BA001F', ec='#8AFFAD')
    #ax.text(70./201., 25./201., r'\textbf{shock}',transform=ax.transAxes,color='#BA001F', fontsize=12)
    #ax.text(60./201., 25./201., r'\textbf{compression}',transform=ax.transAxes,color='#8AFFAD', fontsize=12)

    #ax.arrow(140, 140, -20, -43, head_width=1, head_length=1, fc='#BA001F', ec='#BA001F')
    #ax.arrow(140, 140, -17, -40, head_width=1, head_length=1, fc='#BA001F', ec='#8AFFAD')
    #ax.arrow(140, 140, -20, -43, head_width=1, head_length=1, fc='#002942', ec='#002942')
    #ax.text(132./201., 143./201., r'\textbf{shock}',transform=ax.transAxes,color='#BA001F', fontsize=12)
    #ax.text(122./201., 143./201., r'\textbf{compression}',transform=ax.transAxes,color='#8AFFAD', fontsize=12)
    #ax.text(122./201., 143./201., r'\textbf{core extension}',transform=ax.transAxes,color='#002942', fontsize=12)

    #ax.arrow(160, 40, -30, 35, head_width=1, head_length=1, fc='#BA001F', ec='#BA001F')
    #ax.arrow(160, 40, -23, 28, head_width=1, head_length=1, fc='#BA001F', ec='#8AFFAD')
    #ax.text(145./201., 35./201., r'\textbf{sub-structure}',transform=ax.transAxes,color='#BA001F', fontsize=12)
    #ax.text(145./201., 35./201., r'\textbf{propagating~arc}',transform=ax.transAxes,color='#8AFFAD', fontsize=12)


    
    if save != '':
        plt.savefig(save)

    if show == 1:
        plt.show()

    if noclose == 0:
      plt.close("all")
    
    return 0


