
# general libraries
import numpy as np
import numpy.ma as ma
from scipy import signal
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import os
import datetime
#from joblib import Parallel, delayed

# my own librabries
import xmlrpclib
import scan2run as s2r
import read_nika_data as rnd
import string
from nika_flags import scanst_val
import decorr
import process_1d as p1d
import hfits
import power_spectrum as pws      

# debuging
import pdb
        
font = {'family': 'serif',  'color':  'k', 'weight': 'bold', 'size': 20}

def readdata(scan,darkdet=False,forced_file = ''):
    """
    Fast NIKA reading

    """ 
    det2read ='KID'
    if darkdet ==True:
        det2read = 'KOD'
    list_data='subscan scan scan_st retard 0  sample k_flag RF_didq I Q'
    file =  s2r.scan2rawfile(scan)
    if forced_file != '':
        file = forced_file
    print file
    dummy = os.popen('ls '+ file).read()
    if dummy == '':
        return -1
    try:
        data =  rnd.read_nika_data(file,silent=1,det2read =det2read,list_data=list_data)
    except:
        return -1
    return data


def plot_rms(kr, larr, tlabel='',phase=True,boxpos=None,boxname=None):

    figt = plt.figure(figsize=(20,9))
    axt = figt.add_subplot(111)
    axt.plot(kr['trmsraw'][larr],label='Raw')
    axt.plot(kr['trmsdcm'][larr],label='CM dec')        
    axt.plot(kr['trmsdpca'][larr],label='PCA dec')        
    axt.plot(kr['trmsdbc'][larr],label='BC dec')        
    axt.plot(kr['trmsps'][larr],label='PS') 
    if ((boxpos != None) & (boxname !=None)):
        for id in range(len(boxpos)):
            axt.text(40,boxpos[id]+10,boxname[id],fontdict=font)
            axt.vlines(boxpos[id],1,100,'k',lw=3)
          

    #axt.plot(kr['trmsda'][larr],label='All dec')
    axt.set_title(tlabel)
    axt.set_xlabel("Detector ID") 
    axt.set_ylabel("RF_didq rms")     
    axt.legend() 
    axt.set_ylim([3.0,80.0]) 
    axt.set_xlim([0,len(larr)-1]) 

#    axt.semilogy()
    if phase == True:
        figp = plt.figure(figsize=(20,9))
        axp = figp.add_subplot(111)
        axp.plot(kr['prmsraw'][larr],label='Raw')
        axp.plot(kr['prmsdcm'][larr],label='CM dec')        
        axp.plot(kr['prmsdpca'][larr],label='PCA dec')        
        axp.plot(kr['prmsdbc'][larr],label='BC dec')        
        axp.plot(kr['prmsps'][larr],label='PS')
        #axp.plot(kr['prmsda'][larr],label='All dec')
        axp.set_title(tlabel)
        axp.set_xlabel("Detector ID") 
        axp.set_ylabel("Phase rms")     
        axp.legend() 
        #axt.set_ylim([1.0,50.0])    
        axp.semilogy()
        return [figt,axt],[figp,axp]
    else:
        return [figt,axt]

def corr_matrix(data,plot=False,tlabel='',detid=None,detbox=None):
    corrmat = ma.corrcoef(data)
    if plot == True:

        fig = plt.figure(figsize=(20,20))
        ax  = fig.add_subplot(111)
        im  = ax.imshow(corrmat,interpolation='none')
        cb  = plt.colorbar(im,ax=ax)
        cb.set_label('Correlation Coefficient')
        ax.set_title(tlabel)
        ax.set_xlabel('Detector ID')
        ax.set_ylabel('Detector ID')
        if detid != None:
            im.set_extent([detid.min(),detid.max(),detid.max(),detid.min()])
            if detbox != None:
                dbox,nmbox = get_acqbox(detid,detbox)                
                for id in range(len(dbox)):
                    ax.text(detid.max(),dbox[id]+10,nmbox[id],fontdict=font)
                    ax.hlines(dbox[id],detid.min(),detid.max(),'k',lw=2)
                    ax.vlines(dbox[id],detid.min(),detid.max(),'k',lw=2)
                im.set_extent([detid.min(),detid.max(),detid.max(),detid.min()])
        else:
            if detbox != None:
                ndet=detbox.shape[0]
                detid = np.arange(ndet)
                dbox,nmbox = get_acqbox(detid,detbox,index=True)                
                for id in range(len(dbox)):
                    ax.text(ndet-1,dbox[id]+10,nmbox[id],fontdict=font)
                    ax.hlines(dbox[id],0,ndet-1,'k',lw=2)
                    ax.vlines(dbox[id],0,ndet-1,'k',lw=2)



        return corrmat,[fig,ax,im,cb]
    else:
        return corrmat,[]

def get_acqbox(detid,detbox,index=False):
    nboxes  = 20
    if index == False:
        dbox    = detid[np.where(np.abs(detbox-np.roll(detbox,1)) > 0)[0]]
    else:
        dbox    = np.where(np.abs(detbox-np.roll(detbox,1)) > 0)[0]
    mbox    = np.unique(detbox)
    boxes =[]
    for box in mbox:
        boxes.append(string.uppercase[box])
    return dbox,boxes


def process_per_array(scan,dir_figs_base,darkdet = False,ffile=''):

    # Update figure repertories
    dir_figs = dir_figs_base+scan+'/'
    os.popen('mkdir -p '+dir_figs)

    # Read data 
    data=readdata(scan,darkdet=False,forced_file=ffile)

    # define few interesting values
    scanstval   = np.array(scanst_val)
    scanstflags = scanstval[data.scan_st.astype(np.int)]
    tsec = (data.sample - data.sample[0])/np.double(data.acqfreq)

    # Define maked arrays for work
    nkids, nsamples = data.RF_didq.shape
 
    toi = np.copy(data.RF_didq)
    phase = np.arctan2(data.I,data.Q)
        
    data.RF_didq[data.RF_didq == 0] = np.nan
    data.RF_didq[data.k_flag > 0] = np.nan
        
#    flagkid = np.sum(np.isfinite(data.RF_didq),1) == 0
    ## remove KIDs for which less than 10 % of the samples are valid
    flagkid = np.sum(np.isfinite(data.RF_didq),1) < np.long(0.1*nsamples)
    # remove fully flagged data

    wtoin = np.zeros((nkids,nsamples))
    wtoin[np.isfinite(data.RF_didq)] =  1

    # Select data for analysis
    toi = ma.array(toi,mask=np.abs(1-wtoin))
    toi = toi[flagkid == False,:]

    phase = ma.array(phase,mask=np.abs(1-wtoin))
    phase = phase[flagkid == False,:]

    kflag = data.k_flag[flagkid == False,:]

    nkids,nsamples = toi.shape

    toi   = toi - ma.dot((np.nanmean(toi,axis=1)).reshape(nkids,1),(ma.repeat([1],nsamples)).reshape(1,nsamples))
    phase = phase - ma.dot((np.nanmean(phase,axis=1)).reshape(nkids,1),(ma.repeat([1],nsamples)).reshape(1,nsamples))
 
    # Define dictionary for results
    rstr = ['trmsraw','prmsraw','trmsdcm','prmsdcm','trmsdpca','prmsdpca','trmsdbc','prmsdbc','trmsps','prmsps']
    #'trmsda','prmsda'
    kr = {}
    for istr in rstr:
        kr[istr] = np.zeros(nkids)

    # Do work per array

    for iarray in range(1,4):

        # select kids for array
        larr   = (np.where(data.kidpar['array'][flagkid == False] == iarray))[0]
        detid  = data.kidpar['num'][flagkid == False][larr]
        detbox = data.kidpar['acqbox'][flagkid == False][larr]
        pos_box, name_box = get_acqbox(detid,detbox,index=True)

        tdata  = toi[larr,:]
        pdata  = phase[larr,:]
        # find common mask
        wremove = np.where(np.sum(tdata.mask,0) > 0)[0]
        tdata.mask[:,wremove] = True
        pdata.mask[:,wremove] = True


        # get reference raw rms
        kr['trmsraw'][larr] = ma.std(tdata,1)
        kr['prmsraw'][larr] = ma.std(pdata,1)

        # compute power spectrum and rms
        print "Compute power spectrum"
        frmin = 2.0
        frmax = 7.0
        fr, tpw = pws.power_spec(tdata,sampling_freq = data.acqfreq,ax=1)   
        kr['trmsps'][larr] = pws.rms_from_band(fr,tpw,frmin,frmax)
        fr, ppw = pws.power_spec(pdata,sampling_freq = data.acqfreq,ax=1)   
        kr['prmsps'][larr] = pws.rms_from_band(fr,ppw,frmin,frmax)

       # compute correlationn matrix and plot
        print "Compute correlation matrix"

#        ATTENTION COMMENTER POUR FAIRE UN TEST
        tcormat,tfigl = corr_matrix(tdata,plot=True,tlabel='TOI Array '+np.str(iarray),detbox=detbox)
        tfigl[0].savefig( dir_figs+'/corrmat_TOI_array_'+np.str(iarray)+'_'+scan+'.pdf')
#        pcormat,pfigl = corr_matrix(pdata,plot=True,tlabel='Phase Array '+np.str(iarray),detid=detid,detbox=detbox)
#        pfigl[0].savefig( dir_figs+'/corrmat_PHASE_array_'+np.str(iarray)+'_'+scan+'.pdf')


        # Do different decorrelation methods and compute rms

        # simple common mode 
        print "Doing decorr common mode"
        tdec,tcm,tcmfc = decorr.cmdec(tdata, overwrite=False,cmtype = 'median',cmdetref=0)
        pdec,pcm,pcmfc = decorr.cmdec(pdata, overwrite=False,cmtype = 'median',cmdetref=0)

        kr['trmsdcm'][larr] = ma.std(tdec,1)
        kr['prmsdcm'][larr] = ma.std(pdec,1)

        tcormatcm,tfiglcm = corr_matrix(tdec,plot=True,tlabel='TOI Array '+np.str(iarray),detbox=detbox)
        tfiglcm[0].savefig( dir_figs+'/corrmat_TOI_CM_array_'+np.str(iarray)+'_'+scan+'.pdf')
#        pcormat,pfigl = corr_matrix(pdata,plot=True,tlabel='Phase Array '+np.str(iarray),detid=detid,detbox=detbox)
#        pfigl[0].savefig( dir_figs+'/corrmat_PHASE_array_'+np.str(iarray)+'_'+scan+'.pdf')

        
        # PCA analysis within the array

        print "Doing decorr PCA"
        tfcpca,ttemppca,tdec = decorr.pcadecorr(tdata,nevalmax=10,overwrite=False)
        pfcpca,ptemppca,pdec = decorr.pcadecorr(pdata,nevalmax=10,overwrite=False)

        kr['trmsdpca'][larr] = ma.std(tdec,1)
        kr['prmsdpca'][larr] = ma.std(pdec,1)
    
        tcormatpca,tfiglpca = corr_matrix(tdec,plot=True,tlabel='TOI Array '+np.str(iarray),detbox=detbox)
        tfiglpca[0].savefig( dir_figs+'/corrmat_TOI_PCA_array_'+np.str(iarray)+'_'+scan+'.pdf')
       
        # Most correlated per detector
        print "Doing decorr best correlated pixels"
#       ATTENTION COMMENTER POUR FAIRE UN TEST 
        tdec=decorr.mostcorrdec(tdata, overwrite=False,ndetmin=15,corrth = 0.7,decmod='CM',cmtype='median',corrmat=tcormat)
#        pdec=decorr.mostcorrdec(pdata, overwrite=False,ndetmin=15,corrth = 0.7,decmod='CM',cmtype='median',corrmat=pcormat)

        kr['trmsdbc'][larr] = ma.std(tdec,1)
#        kr['prmsdbc'][larr] = ma.std(pdec,1)

        tcormatbc,tfiglbc = corr_matrix(tdec,plot=True,tlabel='TOI Array '+np.str(iarray),detbox=detbox)
        tfiglbc[0].savefig( dir_figs+'/corrmat_TOI_BC_array_'+np.str(iarray)+'_'+scan+'.pdf')

        # All detectors
        #print "Doing decorr using all detectors"
        #tdec = decorr.alldetdec(tdata, overwrite=False)
        #pdec = decorr.alldetdec(pdata, overwrite=False)

        #kr['trmsda'][larr] = ma.std(tdec,1)
        #kr['prmsda'][larr] = ma.std(pdec,1)

        # plot rms for different decorrelation values

        tfkr,pfkr = plot_rms(kr,larr,tlabel='Array '+np.str(iarray),phase=True,boxpos=pos_box,boxname=name_box)
        #pdb.set_trace()
        tfkr[0].savefig(dir_figs+'/rms_TOI_array_'+np.str(iarray)+'_'+scan+'.pdf')
        pfkr[0].savefig(dir_figs+'/rms_PHASE_array_'+np.str(iarray)+'_'+scan+'.pdf')

    filebase = dir_figs+scan+'_'
    #hfits.dict2fits(kidparn,filebase+'kidpar.fits',dtype=1)
    hfits.dict2fits(kr,filebase+'results.fits')

    return 


def process_scan(scan,dir_figs_base):
        dir_figs = dir_figs_base+scan+'/'
        os.popen('mkdir -p '+dir_figs)
        file =  s2r.scan2rawfile(scan)
        dummy = os.popen('ls '+ file).read()
        if dummy == '':
            return
        try:
            data =  rnd.read_nika_data(file,silent=1,det2read ='KID',list_data=list_data)
        except:
            return

        nboxes = 20
        ACQBOX = string.uppercase[0:nboxes]

        acq_box = data.kidpar['acqbox']
        k_flag = rnd.get_nikavar_data(data,'k_flag')
        scan_st = rnd.get_nikavar_data(data,'scan_st')
        scanstval   = np.array(scanst_val)
        scanstflags = scanstval[scan_st.astype(np.int)]

        scanr = rnd.get_nikavar_data(data,'scan')
        subscan = rnd.get_nikavar_data(data,'subscan')
        sample = rnd.get_nikavar_data(data,'sample')

        # compute sampling frequency from data        
        div_kid = (data.param_c['pvalue'])[np.where(np.array(data.param_c['pname']) ==  'div_kid')[0][0]]
        acqfreq = 5.0e8/2.0**19/div_kid
        tsec = (sample - sample[0])/np.double(acqfreq)
        #endscan = np.max(np.where(scanstflags == 'scandone')[0])
        toi = rnd.get_nikavar_data(data,'RF_didq')
        I = rnd.get_nikavar_data(data,'I')
        Q = rnd.get_nikavar_data(data,'Q')
   # Deal with flags to first order

        nkids, nsamples = toi.shape
        toin = np.copy(toi)
        phase = np.arctan2(I,Q)
        
        toi[toi == 0] = np.nan
        toi[k_flag > 0] = np.nan
        
        #toi[:,endscan:] = np.nan
#        flagkid = np.isnan(np.nansum(toi,1))
        flagkid = np.sum(np.isfinite(toi),1) == 0
        # remove fully flagged data

        wtoin = np.zeros((nkids,nsamples))
        wtoin[np.isfinite(toi)] =  1



        toin = ma.array(toin,mask=np.abs(1-wtoin))
        toin = toin[flagkid == False,:]

        phase = ma.array(phase,mask=np.abs(1-wtoin))
        phase = phase[flagkid == False,:]
                                           
        nkids,nsamples = toin.shape
        toin = toin - ma.dot((np.nanmean(toin,axis=1)).reshape(nkids,1),(ma.repeat([1],nsamples)).reshape(1,nsamples))
        phase = phase - ma.dot((np.nanmean(phase,axis=1)).reshape(nkids,1),(ma.repeat([1],nsamples)).reshape(1,nsamples))
        k_flagn=  k_flag[flagkid == False,:]
       

    # plot all data after flagging to check

        
        kidparn = data.kidpar
        #kidpar[flagkid == False]
        nbox = 20

        savedata   = 1
        dotoiplots = 1
        if dotoiplots:
            pdf = PdfPages(dir_figs+'noise_figs_'+scan+'.pdf')

        figc  = plt.figure(figsize=(20,20))
        figh  = plt.figure(figsize=(20,20))
        figf  = plt.figure(figsize=(20,20))
        figcd  = plt.figure(figsize=(20,20))
        fighd  = plt.figure(figsize=(20,20))
        figfd  = plt.figure(figsize=(20,20))
        figcp  = plt.figure(figsize=(20,20))
        fighp  = plt.figure(figsize=(20,20))
        figfp  = plt.figure(figsize=(20,20))
        figcdp  = plt.figure(figsize=(20,20))
        fighdp  = plt.figure(figsize=(20,20))
        figfdp  = plt.figure(figsize=(20,20))
        figfit  = plt.figure(figsize=(20,20))

        
        sigma_box = []
        sigma_boxd = []
        rms_box = []
        rms_boxd = []
        kfreq  = kidparn['frequency'][flagkid == False]
        kname  = kidparn['name'][flagkid == False]

        nkids = len(kname)
        kresults = {}
        kresults['rms'] = np.zeros(nkids)-1.0
        kresults['rms_dec'] = np.zeros(nkids)-1.0
        kresults['rms_sp'] = np.zeros(nkids)-1.0
        kresults['rms_sp_dec'] = np.zeros(nkids)-1.0
        kresults['noise_sp'] = np.zeros(nkids)-1.0
        kresults['noise_sp_dec'] = np.zeros(nkids)-1.0
        kresults['rms_p'] = np.zeros(nkids)-1.0
        kresults['rms_dec_p'] = np.zeros(nkids)-1.0
        kresults['rms_sp_p'] = np.zeros(nkids)-1.0
        kresults['rms_sp_dec_p'] = np.zeros(nkids)-1.0
        kresults['noise_sp_p'] = np.zeros(nkids)-1.0
        kresults['noise_sp_dec_p'] = np.zeros(nkids)-1.0
        kresults['corr'] = np.zeros(nkids)-1.0
        kresults['corr_p'] = np.zeros(nkids)-1.0
        kresults['cfit'] = np.zeros(nkids)-1.0
        kresults['cfit_p'] = np.zeros(nkids)-1.0
        
        for ibox in range(nbox):
            if dotoiplots:
                figt  = plt.figure(figsize=(15,10))
                figs  = plt.figure(figsize=(15,10))
                axt = figt.add_subplot(111)
                axs = figs.add_subplot(111)
                
            lbox = (np.where(kidparn['acqbox'][flagkid == False] == ibox))[0]
            tdata = toin[lbox,:]
            pdata = phase[lbox,:]
 
            # plot toi and spectra kids
            
            
            sigma_kids = []
            rms_kids = []
            sigma_kids_p =[]
            rms_kids_p=[]
            for idx in lbox:
#                pos = np.isfinite(toin[lbox[pkid],:])
                f, Pxx_den = signal.periodogram(toin[idx,:],acqfreq)
                sigma_kids.append(np.median(Pxx_den[f > 1.0]))
                rms_kids.append(ma.std(toin[idx,:]))
                if dotoiplots:
                    axt.plot(tsec,toin[idx,:],label=kname[idx])
                    axs.plot(f,np.sqrt(Pxx_den),label=kname[idx])
                f, Pxx_den_p = signal.periodogram(phase[idx,:],acqfreq)
                sigma_kids_p.append(np.median(Pxx_den_p[f > 1.0]))
                rms_kids_p.append(ma.std(phase[idx,:]))

            rms_kids_sp = np.sqrt(np.array(sigma_kids)*acqfreq/2.0)
            rms_kids_sp_p = np.sqrt(np.array(sigma_kids_p)*acqfreq/2.0)
            kresults['rms'][lbox] = np.array(rms_kids)
            kresults['rms_sp'][lbox] = np.array(rms_kids_sp)
            kresults['noise_sp'][lbox] = np.array(sigma_kids)
            kresults['rms_p'][lbox] = np.array(rms_kids_p)
            kresults['rms_sp_p'][lbox] = np.array(rms_kids_sp_p)
            kresults['noise_sp_p'][lbox] = np.array(sigma_kids_p)
            
            if dotoiplots:
                axt.legend(ncol=20,fontsize=5)
                axt.set_title('Box '+ACQBOX[ibox])
                axt.set_xlabel('Time [sec]'  )
                axt.set_ylabel('Flux [Hz]')
                axt.set_xlim([tsec.min(),tsec.max()])

                axs.legend(ncol=20,fontsize=5)
                axs.set_ylim([1e-2,1e5])
                axs.set_xlim([1e-3,acqfreq/2.0])
                axs.semilogx()
                axs.semilogy()
                axs.set_title('Box '+ACQBOX[ibox])
                axs.set_xlabel('Frequency [Hz]'  )
                axs.set_ylabel(r'PSD [Hz/$\sqrt{Hz}$]')

                figt.savefig(pdf,format='pdf')
                figs.savefig(pdf,format='pdf')
                #figt.savefig( dir_figs+'/toi_box_'+ACQBOX[ibox]+'_'+scan+'.jpeg')     
                plt.close(figt)
                #figs.savefig( dir_figs+'/spec_box_'+ACQBOX[ibox]+'_'+scan+'.jpeg')     
                plt.close(figs)

            sigma_box.append(rms_kids_sp)
            rms_box.append(rms_kids)
            covmat = ma.cov(toin[lbox,:])
            axc = figc.add_subplot(5,4,ibox+1)
            imc = axc.imshow(covmat/covmat[0,0],interpolation='nearest',vmin=-2,vmax=2)
            cbc = figc.colorbar(imc,ax=axc)
            
            axf = figf.add_subplot(5,4,ibox+1)
            axf.plot(kfreq[lbox]/1.0e9,kresults['rms_sp'][lbox],label='SP',color='g')
            axf.plot(kfreq[lbox]/1.0e9,kresults['rms'][lbox],label='RMS',color='b')
            axf.legend(fontsize=8)
            axf.set_title(ACQBOX[ibox])
            axf.set_xlabel('Frequency [GHz]')
            axf.set_ylabel('rms [Hz]')


            axh = figh.add_subplot(5,4,ibox+1)
            n, bins, patches = axh.hist(kresults['rms_sp'][lbox], bins=20, facecolor='green', alpha=0.75,label='SP')
            n, bins, patches = axh.hist(kresults['rms'][lbox], bins=20, facecolor='blue', alpha=0.75,label='RMS')
            axh.set_title('Box '+ ACQBOX[ibox])
            axh.set_xlabel('rms [Hz]')
            axh.legend(fontsize=8)

            covmatp = ma.cov(phase[lbox,:])
            axcp = figcp.add_subplot(5,4,ibox+1)
            imcp=axcp.imshow(covmatp/covmatp[0,0],interpolation='nearest',vmin=-2,vmax=2)
            cbcp = figcp.colorbar(imcp,ax=axcp)

            axfp = figfp.add_subplot(5,4,ibox+1)
            #axfp.plot(kfreq[lbox]/1.0e9,kresults['rms_sp_p'][lbox],label='SP',color='g')
            axfp.plot(kfreq[lbox]/1.0e9,kresults['rms_p'][lbox],label='RMS',color='b')
            axfp.legend(fontsize=8)
            axfp.set_title(ACQBOX[ibox])
            axfp.set_xlabel('Frequency [GHz]')
            axfp.set_ylabel('Phase rms [rad]')


            axhp = fighp.add_subplot(5,4,ibox+1)
            n, bins, patches = axhp.hist(kresults['rms_sp_p'][lbox], bins=20, facecolor='green', alpha=0.75,label='SP')
            n, bins, patches = axhp.hist(kresults['rms_p'][lbox], bins=20, facecolor='blue', alpha=0.75,label='RMS')
            axhp.set_title('Box '+ ACQBOX[ibox])
            axhp.set_xlabel('Phase rms [rad]')
            axhp.legend(fontsize=8)
            
            
            

            # Do decorrelation and recompute
            corr_coeff, commod, fit_coeff = decorr.get_common_mode(tdata,type='median')
            corr_coeff_p, commod_p, fit_coeff_p = decorr.get_common_mode(pdata,type='median')

            kresults['corr'][lbox]   = corr_coeff
            kresults['corr_p'][lbox] = corr_coeff_p
            kresults['cfit'][lbox]   = fit_coeff
            kresults['cfit_p'][lbox] = fit_coeff_p

            axfit = figfit.add_subplot(5,4,ibox+1)
            axfit.plot(kfreq[lbox]/1.0e9,corr_coeff,label='Corr Coeff',color='g')
            axfit.plot(kfreq[lbox]/1.0e9,fit_coeff,label='CM Fit Coeff',color='b')
            axfit.legend(fontsize=8)
            axfit.set_title(ACQBOX[ibox])
            axfit.set_xlabel('Frequency [GHz]')
            axfit.set_ylabel('Gain')
            
            nkidbox = len(lbox)
            sigma_kids_dec = []
            rms_kids_dec = []
            sigma_kids_dec_p = []
            rms_kids_dec_p = []


            if dotoiplots:
                figtd  = plt.figure(figsize=(15,10))
                figsd  = plt.figure(figsize=(15,10))
                axtd = figtd.add_subplot(111)
                axsd = figsd.add_subplot(111)

            for ikid in range(nkidbox):
                #jumps = p1d.canny_jump_find(tdata[ikid,:],nkernel=3,nsigma=6.0)
                tdata[ikid,:] -= (fit_coeff[ikid]*commod)
                f, Pxx_den = signal.periodogram(tdata[ikid,:], acqfreq)
                sigma_kids_dec.append(np.mean(Pxx_den[f > 1.0]))
                rms_kids_dec.append(ma.std(tdata[ikid,:]))
                if dotoiplots:
                    axtd.plot(tsec,tdata[ikid,:],label=kname[lbox[ikid]])
                    #axtd.plot(tsec[jumps],tdata[idx,jumps],'ro')
                #jumps_p = p1d.canny_jump_find(pdata[ikid,:],nkernel=3,nsigma=6.0)
                pdata[ikid,:] -= (fit_coeff_p[ikid]*commod_p)
                f, Pxx_den_p = signal.periodogram(pdata[ikid,:], acqfreq)
                sigma_kids_dec_p.append(np.mean(Pxx_den_p[f > 1.0]))
                rms_kids_dec_p.append(ma.std(pdata[ikid,:]))
            rms_kids_sp_dec = np.sqrt(np.array(sigma_kids_dec)*acqfreq/2.0)
            rms_kids_sp_dec_p = np.sqrt(np.array(sigma_kids_dec_p)*acqfreq/2.0)

            kresults['rms_dec'][lbox] = np.array(rms_kids)
            kresults['rms_sp_dec'][lbox] = np.array(rms_kids_sp)
            kresults['noise_sp_dec'][lbox] = np.array(sigma_kids)
            kresults['rms_dec_p'][lbox] = np.array(rms_kids_p)
            kresults['rms_sp_dec_p'][lbox] = np.array(rms_kids_sp_p)
            kresults['noise_sp_dec_p'][lbox] = np.array(sigma_kids_p)
            
            if dotoiplots:
                axsd.plot(f,np.sqrt(Pxx_den),label=kname[lbox[ikid]])
                axtd.set_title('Box '+ACQBOX[ibox])
                axtd.set_xlabel('Time [sec]'  )
                axtd.set_ylabel('Flux [Hz]')
                axtd.set_xlim([tsec.min(),tsec.max()])
                axsd.set_ylim([1e-2,1e3])
                axsd.set_xlim([1e-3,acqfreq/2.0])
                axsd.semilogx()
                axsd.semilogy()
                axsd.set_title('Box '+ACQBOX[ibox])
                axsd.set_xlabel('Frequency [Hz]'  )
                axsd.set_ylabel(r'PSD [Hz/$\sqrt{Hz}$]')           
                axtd.legend(ncol=20,fontsize=5)
                axsd.legend(ncol=20,fontsize=5)

                figtd.savefig(pdf,format='pdf')
                figsd.savefig(pdf,format='pdf')

                #figtd.savefig( dir_figs+'/toi_perbox_dec_'+ACQBOX[ibox]+'_'+scan+'.jpeg')     
                plt.close(figtd)
                #figsd.savefig( dir_figs+'/spec_perbox_dec_'+ACQBOX[ibox]+'_'+scan+'.jpeg')     
                plt.close(figsd)

            
            sigma_boxd.append(rms_kids_sp_dec)    
            rms_boxd.append(rms_kids_dec)
            
            covmatdec = ma.cov(tdata)
            axcd = figcd.add_subplot(5,4,ibox+1)
            axcd.set_title('Box '+ ACQBOX[ibox])
            imcd=axcd.imshow(covmatdec/covmatdec[0,0],interpolation='nearest',vmin=-2,vmax=2)
            cbcd = figcd.colorbar(imcd,ax=axcd)

            axfd = figfd.add_subplot(5,4,ibox+1)
            axfd.plot(kfreq[lbox]/1.0e9,kresults['rms_sp_dec'][lbox],label='SP',color='g')
            axfd.plot(kfreq[lbox]/1.0e9,kresults['rms_dec'][lbox],label='RMS',color='b')
            axfd.legend(fontsize=8)
            axfd.set_title(ACQBOX[ibox])
            axfd.set_xlabel('Frequency [GHz]')
            axfd.set_ylabel('rms [Hz]')

            axhd = fighd.add_subplot(5,4,ibox+1)
            n, bins, patches = axhd.hist(kresults['rms_dec'][lbox], bins=20, facecolor='blue', alpha=0.75,label='TOI')
            n, bins, patches = axhd.hist(kresults['rms_sp_dec'][lbox], bins=20, facecolor='green', alpha=0.75,label='SP')
            axhd.set_title('Box '+ ACQBOX[ibox])
            axhd.set_xlabel('rms [Hz]')
            axhd.legend()

            covmatdecp = ma.cov(pdata)
            axcdp = figcdp.add_subplot(5,4,ibox+1)
            axcdp.set_title('Box '+ ACQBOX[ibox])
            imcdp=axcdp.imshow(covmatdecp/covmatdecp[0,0],interpolation='nearest',vmin=-1,vmax=2)
            cbcdp = figcdp.colorbar(imcdp,ax=axcdp)

            axfdp = figfdp.add_subplot(5,4,ibox+1)
            #axfdp.plot(kfreq[lbox]/1.0e9,kresults['rms_sp_dec_p'][lbox],label='SP',color='g')
            axfdp.plot(kfreq[lbox]/1.0e9,kresults['rms_dec_p'][lbox],label='RMS',color='b')
            axfdp.legend(fontsize=8)
            axfdp.set_title(ACQBOX[ibox])
            axfdp.set_xlabel('Frequency [GHz]')
            axfdp.set_ylabel('Phase rms [rad]')

            axhdp = fighdp.add_subplot(5,4,ibox+1)
            n, bins, patches = axhdp.hist(kresults['rms_dec_p'][lbox], bins=20, facecolor='blue', alpha=0.75,label='TOI')
            n, bins, patches = axhdp.hist(kresults['rms_sp_dec_p'][lbox], bins=20, facecolor='green', alpha=0.75,label='SP')
            axhd.set_title('Box '+ ACQBOX[ibox])
            axhd.set_xlabel('Phase rms [rad]')
            axhd.legend()


        figc.savefig( dir_figs+'/covmat_perbox_'+scan+'.pdf')     
        plt.close(figc)
        figh.savefig( dir_figs+'/histsigma_perbox_'+scan+'.pdf')     
        plt.close(figh)
        figf.savefig( dir_figs+'/rms_perbox_'+scan+'.pdf')     
        plt.close(figf)

        figcp.savefig( dir_figs+'/covmat_perbox_phase_'+scan+'.pdf')     
        plt.close(figcp)
        fighp.savefig( dir_figs+'/histsigma_perbox_phase_'+scan+'.pdf')     
        plt.close(fighp)
        figfp.savefig( dir_figs+'/rms_perbox_phase_'+scan+'.pdf')     
        plt.close(figfp)
        
        figcd.savefig( dir_figs+'/covmat_perbox_dec_'+scan+'.pdf')     
        plt.close(figcd)
        fighd.savefig( dir_figs+'/histsigma_perbox_dec_'+scan+'.pdf')     
        plt.close(fighd)
        figfd.savefig( dir_figs+'/rms_perbox_dec_'+scan+'.pdf')     
        plt.close(figfd)

        figcdp.savefig( dir_figs+'/covmat_perbox_dec_phase_'+scan+'.pdf')     
        plt.close(figcdp)
        fighdp.savefig( dir_figs+'/histsigma_perbox_dec_phase_'+scan+'.pdf')     
        plt.close(fighdp)
        figfdp.savefig( dir_figs+'/rms_perbox_dec_phase_'+scan+'.pdf')     
        plt.close(figfdp)

        figfit.savefig( dir_figs+'/corrfit_coeff_perbox_'+scan+'.pdf')     
        plt.close(figfit)

        if dotoiplots:
            d = pdf.infodict()
            d['Title'] = 'Noise statistics'
            d['Author'] = u'Juan Francisco Macias Perez'
            d['Subject'] = ''
            d['Keywords'] = ''
            d['CreationDate'] = datetime.datetime.today()
            d['ModDate'] = datetime.datetime.today()
            pdf.close()

        if savedata:
            filebase = dir_figs+scan+'_'
            #hfits.dict2fits(kidparn,filebase+'kidpar.fits',dtype=1)
            hfits.dict2fits(kresults,filebase+'results.fits')
            
        return

if __name__ == '__main__':

    """
    ## ______________________________________________
    ## To launch:
    ## 1) compile just once code in Processing/Pipeline/Readdata/C
    ##      >> make
    ## 2) source config file
    ##      >> source Processing/Pipeline/Scr/Reference/nika_python.bash
    ## 3) modify script (see below) and launch
    ##      >> ipython
    ##      ipython>> %run dark_test
    ##
    ##      or :
    ##      >> python dark_test.py
    ##
    """
    ## --------------------------------------------------
    ## ATTENTION
    ## Informations sur scan and dir to modify
    ## ---------------------------------------------------
    dir_figs_base ='/home/macias/NIKA/Plots/Run19/Darktests/'
    scan ='20161211s299'
    ## -----------------------------------------------------

    os.popen('mkdir -p '+dir_figs_base)
    print "Working on scan: "+scan
    process_per_array(scan,dir_figs_base)

    ## --------------------------------------
    ## To launch scan_list decomment next
    ##scan_list = ['20161211s299']
    ##print scan_list
    ##for scan in scan_list:
    ##    Parallel(n_jobs=8)(delayed(process_per_array)(scan,dir_figs_base) for scan in scan_list)
    

    
     
 
    
    

