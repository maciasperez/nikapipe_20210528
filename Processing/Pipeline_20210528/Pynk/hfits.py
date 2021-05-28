'''
Module to write fits files from different data types

Modifications
-------------
JFMP, Oct 2017, first version
 
'''
from astropy.io import fits
import numpy as np
import types, itertools
import pdb


def type2colformat(arr):
    '''
    Defines format for FITS file from array dtype
    
    Parameters
    ----------
    arr: (N) array_like
         Array of data

    Returns
    -------
    fmt: str
         Python format for the array
    '''
    if arr.dtype.type==np.int8:
        fmt='I'
    elif arr.dtype.type==np.int16:
        fmt='I'
    elif arr.dtype.type==np.int32:
        fmt='J'
    elif arr.dtype.type==np.int64:
        fmt='K'
    elif arr.dtype.type==np.float32:
        fmt='E'
    elif arr.dtype.type==np.float64:
        fmt='D'
    elif arr.dtype.type==np.string_:
        fmt='%dA'%arr.dtype.itemsize
    else:
        raise Exception("Oops unknown datatype %s"%arr.dtype)

    return fmt

def arr2fits(arr,name,filename):
    '''
    Write array into fits file

    Parameters
    -----------
    arr: (N) array_like
         Array of data
    name: str
         Name to be given to the variable in the fits file
    filename: str
         Name of the file    
   '''
    fmt = type2colformat(arr)

    col = [fits.Column(name=name,format=fmt,array=arr)]        
    fcols = fits.ColDefs(col)
    tbhdu = fits.BinTableHDU.from_columns(fcols)
    tbhdu.writeto(filename,clobber=True)
 
    return


def dict2fits(mdict,filename,dtype=1,hduonly=False):
    """
    Write a python dictionary variable into a fits file

    Parameters
    ----------
    mdict: python dictionary
           Contains variables to write into fits file

    filename: string
            Name of the file
    
    
    """
    cols = []
    for k in mdict.keys():
        if dtype:
            if mdict[k].dtype.type==np.int8:
                fmt='I'
            elif mdict[k].dtype.type==np.int16:
                fmt='I'
            elif mdict[k].dtype.type==np.int32:
                fmt='J'
            elif mdict[k].dtype.type==np.int64:
                fmt='K'
            elif mdict[k].dtype.type==np.float32:
                fmt='E'
            elif mdict[k].dtype.type==np.float64:
                fmt='D'
            elif mdict[k].dtype.type==np.string_:
                fmt='%dA'%mdict[k].dtype.itemsize                
            else:
                raise Exception("Oops unknown datatype %s"%mdict[k].dtype)
                fmt=mdict[k].dtype.str[1:]
        else:
            fmt='E'
        #print fmt
        cols.append(fits.Column(name=k,format=fmt,array=np.array(mdict[k])))        
    fcols = fits.ColDefs(cols)
    tbhdu = fits.BinTableHDU.from_columns(fcols)
    if hduonly == True:
        return tbhdu
    else:
        tbhdu.writeto(filename,clobber=True)
        return


def fits2dict(filename):
    """
    Read fits file and transform into a dictionary
    """

    hdu = fits.open(filename)
    header = hdu[1].header

    dat = hdu[1].data

    mdict = {}
    for col in dat.columns:
        colname = np.str(col.name)
        mdict[colname] = dat[colname]
    return mdict


def mwrfits(filename, arraylist, namelist=None, header=None):
    """ 
    Writes the list of np.arrays arraylist as a FITS table filename
    using namelist as list of names. 
    Arraylist can be dictionary with arrays as values and names as keys. 
    Also Arraylist can be numpy-record-array.
    Example:
    mwrfits('/tmp/xx.fits',[arr,arr1],['X','Y'])
    Or :
    mwrfits('test.fits',{'X':arr,'Y':arr1})
    Or:
    data = np.zeros((4,),dtype=[('run','i4'),('rerun','f8'),('zz','b')])
    hfits.mwrfits('test1.fits',data)
    
    Keep in mind that when you used a dictionary, the order of columns in the
    fits file is not guaranteed
    """

    tmplist=[]
    if isinstance(arraylist,np.ndarray):
        if arraylist.dtype.type is np.void:
            iter=itertools.izip(arraylist.dtype.names, itertools.imap (arraylist.__getitem__ , arraylist.dtype.names))
    else:
        if isinstance(arraylist,types.ListType):
            iter= zip(namelist, arraylist)
        elif isinstance(arraylist,types.DictType):
            iter= arraylist.iteritems()

    for name, arr in iter:
        if arr.dtype.type==np.int8:
            format='I'
        elif arr.dtype.type==np.int16:
            format='I'
        elif arr.dtype.type==np.int32:
            format='J'
        elif arr.dtype.type==np.int64:
            format='K'
        elif arr.dtype.type==np.float32:
            format='E'
        elif arr.dtype.type==np.float64:
            format='D'
        elif arr.dtype.type==np.string_:
            format='%dA'%arr.dtype.itemsize
        else:
            raise Exception("Oops unknown datatype %s"%arr.dtype)
        tmplist.append(fits.Column(name=name, array=arr, format=format))
    hdu = fits.new_table(tmplist)
    hdu.writeto(filename,clobber=True)
