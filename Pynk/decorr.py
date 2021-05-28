"""
Module including decorrelaion functions

"""
from __future__ import print_function
import numpy as np
import numpy.ma as ma
import pdb


def select_kids(toi,rmsth=5.0):
        """
        Select kids using simple statisti1d cals properties


        """
        from process_1d import sigma_mad
        rmsdet = ma.std(toi,1)
        okd = np.where(np.abs(rmsdet-np.median(rmsdet)) < rmsth *sigma_mad(rmsdet))     
        if len(okd) > 0:
                wdet = okd[0]
        else:
                print ("No good kid left ")
                return
        return wdet

def regress(data, temp):
        """
        Compute simple linear fit:
          data = A x temp 
        using least squares

        Parameters
        ----------
        data: masked array like
              Input data to fit

            temp: array like
        Input templates
        Keywords
        --------
        None
        Returns
        -------
        Linear fit coefficients
        """
        result = np.linalg.lstsq(temp.T, data.T)
        return result[0].T


def get_common_mode(toi, detref = 0,type='mean', rmsth=5.0):

        """
        Define simple common mode
        Parameters
        -----------
        toi:  masked array_like
                Input toi data. assume as a 2D arrray (ndetectorsxnsamples)
        Keywords
        --------
        detref: int
                reference detector
        type: string
                 'mean' : mean common mode
                 'median': median common mode
        rmsth: threshold for selecting bad detectors using rms

        Returns
        --------
        com:  array_like        
        Common mode 1D array of size nsamples
        corr_coeff: array_like
        Correlation coefficients
        """

        ndet,nsamples = toi.shape
        # check rms to find bad detectors
        wdet = select_kids(toi,rmsth=rmsth)
        nndet = len(wdet)
        # compute correlation between detectors
        corr_coeff = ma.inner(toi[wdet,:],toi[detref,:])
        corr_coeff /= corr_coeff[detref]

        if type == 'mean':
                com = ma.mean(toi[wdet,:]/ma.repeat(corr_coeff,nsamples).reshape(nndet,nsamples),axis=0)
        elif type == 'median':
                com = ma.median(toi[wdet,:]/ma.repeat(corr_coeff,nsamples).reshape(nndet,nsamples),axis=0)
        else:
                print("Wrong type")
                return None
        return corr_coeff, com


def cmdec(toi, overwrite=False,cmtype = 'mean',cmdetref=0,dark_pixels=None):
        """
        Decorrelate using simple common mode 
        Input
        """
        if (overwrite == False):
                toidec = ma.copy(toi)
        else:
                toidec = toi
        ndet,nsamples = toi.shape
        corr_coeff,commod = get_common_mode(toi, detref = cmdetref,type=cmtype, rmsth=5.0)

        if dark_pixels != None:
                        corr_coeff_dark,commod_dark = get_common_mode(dark_pixels, detref = 0,type=cmtype)

        for idet in range(ndet):
                if dark_pixels == None:
                        fit_coeff = regress(toidec[idet,:].reshape(nsamples), commod.reshape(1,nsamples))
                        toidec[idet,:]  -= (fit_coeff*commod)
                else:
                        temp = np.concatenate([[commod],[commod_dark]])
                        fit_coeff = regress(toidec[idet,:].reshape(nsamples), temp)
                        toidec[idet,:]  -= (fit_coeff[0]*commod)
                        toidec[idet,:]  -= (fit_coeff[1]*commod_dark)

        if (overwrite == False):
                return toidec,commod,fit_coeff



def mostcorrdec(toi, overwrite=False,ndetmin=15,corrth = 0.7,decmod='CM',cmtype='median',corrmat=None):
        """
        Decorrelate using as templates the most correlated detectors
     
        Parameters
         -----------

        Keywords
        --------

        Returns
        --------
        """
        ndet,nsamples = toi.shape
        if (overwrite == False):
                toidec = ma.copy(toi)
        else: 
                toidec = toi
 
        #compute detector correlation
        if corrmat == None:
                corr = ma.corrcoef(toi)
        else:
                corr = corrmat

        for idet in range(ndet):

                pos = np.argsort(corr[idet,:])[::-1][1:]
                if len(pos) == 0:
                        npos = 0
                else:
                        kpos =  np.where(corr[idet,pos] < corrth)[0]
                        if len(kpos) > 0:
                                npos = kpos[0]
                        else:
                                npos = len(pos)-1
                ndetcorr = np.max([npos,ndetmin])
                temp = toi[pos[0:ndetcorr],:]
                if (decmod == 'ADT'):
                        ntemp,dum = temp.shape
                        fit_coeff = regress(toi[idet,:].reshape(nsamples), temp)
                        for itemp in range(ntemp):
                                toidec[idet,:]-= (fit_coeff[itemp]*temp[itemp,:])
                elif(decmod == 'CM'):
                        corr_coeff,commod = get_common_mode(temp, detref = 0,type=cmtype, rmsth=100.0)
                        fit_coeff = regress(toi[idet,:].reshape(nsamples), commod.reshape(1,nsamples))
                        toidec[idet,:]  -= (fit_coeff*commod)
                else:
                        print ("Decorrelation mode not accepted")
                        print ("Use: CM (common mode), ADT ( use all detectors as templates)")
        if overwrite == False:
                if corrmat == None:
                        return toidec, corr
                else:
                        return toidec
        else:
                return corr

def alldetdec(toi,overwrite=False):
    """
    Decorrelate each toi using all the otehrs as templates
    """
    ndet,nsamples = toi.shape
    
    wdet = select_kids(toi,rmsth=5.0)
    toidec = toi
    if (overwrite == False): toidec = ma.copy(toi)
    for idet in range(ndet):
        pdet = np.where(idet != wdet)[0]
        temp = toi[wdet[pdet],:]
        ntemp,dum = temp.shape
        fit_coeff = regress(toi[idet,:].reshape(nsamples), temp)
        for itemp in range(ntemp):
            toidec[idet,:]  -= (fit_coeff[itemp]*temp[itemp,:])
    if (overwrite == False):
        return toidec


def pcadecomp(data,decpowerpc=0.80,nevalmax=None):
    """
    returns: data transformed in 2 dims/columns + regenerated original data
    pass in: data as 2D NumPy array
    Parameters
    -----------

    """
    from scipy import linalg as LA
    R = ma.cov(data)
    # calculate eigenvectors & eigenvalues of the covariance matrix
    # use 'eigh' rather than 'eig' since R is symmetric, 
    # the performance gain is substantial
    evals, evecs = LA.eigh(R.data)
    # sort eigenvalue in decreasing order
    idx = np.argsort(evals)[::-1]
    evecs = evecs[:,idx]
    # sort eigenvectors according to same index
    evals = evals[idx]
    decpower= np.cumsum(evals)/np.sum(evals)
    sel = np.where(decpower <= decpowerpc)
    if len(sel) > 0:
        sel =sel[0]
    else:
        print ("Wrong PCA decomposition; check results")
        return -1
    nsel = len(sel)
    if (nevalmax != None):
        if  (nevalmax < nsel):
                sel = sel[0:nevalmax] 
        else:
                sel = np.arange(nevalmax)

    # select the first n eigenvectors (n is desired dimension
    # of rescaled data array, or dims_rescaled_data)
    #   evecs = evecs[:, :dims_rescaled_data]
    # carry out the transformation on the data using eigenvectors
    # and return the re-scaled data, eigenvalues, and eigenvectors
    return ma.dot(evecs[:,sel].T, data), evals[sel]




def pcadecorr(toi,nevalmax=10,overwrite=False):

        """ 
        Use PCA decomposition to do decorrelation
        Parameters
        ----------


        Returns:
        --------
                
        """
        ndet,nsamples = toi.shape
        # check rms to find bad detectors
        wdet = select_kids(toi,rmsth=5.0)
        # compute PCA decomposition
        temp, evals = pcadecomp(toi[wdet,:],nevalmax = nevalmax)
        ntemp, dumm = temp.shape
        # do linear regression for all detectors including bad ones
        fit_coeff = regress(toi, temp)
        # get decorrelated data
        if (overwrite == False):
                toidec = ma.copy(toi)
                for idet in range(ndet):
                        for itemp in range(ntemp):
                                toidec[idet,:]  -= (fit_coeff[idet,itemp]*temp[itemp,:])
                return fit_coeff,temp,toidec
        else:
                for idet in range(ndet):
                                for itemp in range():
                                        toi[idet,:]     -= (fit_coeff[idet,itemp]*temp[itemp,:])
                                return fit_coeff,temp

