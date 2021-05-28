# USAGE
# python convnet_kid_selection2.py --load-model 1 --weights output/lenet_weights_iter1.hdf5 --beam_dir ./Beams/ --beammap 20171022s158 --ncpu 16 --iter 2 --kidpar_dir ./Kidpars/

# import the necessary packages
from pyimagesearch.cnn.networks import LeNet
from sklearn.cross_validation import train_test_split
from sklearn import datasets
from keras.optimizers import SGD
from keras.utils import np_utils
import numpy as np
from astropy.io import fits
import argparse
import cv2
import pdb
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
from matplotlib.backends.backend_pdf import PdfPages
from nk_icm_progress import progress_bar
import os
import scipy.io
import time
import pdb
from astropy.table import Table, Column
import find_double_kid
import warnings
from joblib import Parallel, delayed
import selection_title
selection_title.title()

with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    # construct the argument parse and parse the arguments
    ap = argparse.ArgumentParser()
    ap.add_argument("-s", "--save-model", type=int, default=-1,
            help="(optional) whether or not model should be saved to disk")
    ap.add_argument("-l", "--load-model", type=int, default=-1,
            help="(optional) whether or not pre-trained model should be loaded")
    ap.add_argument("-w", "--weights", type=str,
            help="(optional) path to weights file")
    ap.add_argument("-bd", "--beam_dir", type=str,
            help="(optional) path to fitted beams file")
    ap.add_argument("-m", "--beammap", type=str,
            help="(optional) beammap scan number")
    ap.add_argument("-n", "--ncpu", type=int,
            help="(optional) number of cpu used for preprocessing")
    ap.add_argument("-ni", "--iter", type=int,
            help="(optional) iteration considered")
    ap.add_argument("-kd", "--kidpar_dir", type=str,
            help="(optional) path to kidpar files")
    ap.add_argument("-p", "--plot", type=int, default=0,
            help="(optional) set to 1 if you want to make a pdf of the discarded KID maps")
    args = vars(ap.parse_args())
    os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

    cmap = ListedColormap(np.loadtxt(os.environ["SZ_PIPE"]+"/Colormaps/nika_cmap.txt")/255.)
    hdub1 = fits.open('/home/ruppin/Trunck/Processing/Labtools/FR/Neural_network/Data_beammap/template_beam1mmbis.fits')
    hdub2 = fits.open('/home/ruppin/Trunck/Processing/Labtools/FR/Neural_network/Data_beammap/template_beam2mmbis.fits')
    
    maptemplate_1mm = hdub1[0].data[53:170,14:207]
    maptemplate_2mm = hdub2[0].data[53:170,14:207]

    print "==============================================================="
    print "Calibration of the parameters for double KIDs identification..."
    print "==============================================================="

    ncpu = args["ncpu"]
    def Calibrate_noise(i):
        opt = SGD(lr=0.01)
        model = LeNet.build(width=221, height=221, depth=1, classes=3,
                            weightsPath=args["weights"] if args["load_model"] > 0 else None)
        model.compile(loss="categorical_crossentropy", optimizer=opt,
                      metrics=["accuracy"])

        beam_dir = args["beam_dir"]
        beammap = args["beammap"]
        ncpu = args["ncpu"]
        iteration = args["iter"]

        maps = scipy.io.readsav(beam_dir+'map_lists_'+beammap+'_sub_'+str(i)+'.save')
        dataset = np.abs(maps['map_list_azel'])
        data = np.transpose(dataset)[:, np.newaxis, :, :]
        kidpar = maps['kidpar']

        mean = [[],[]]
        
        if i == 0:
            mybar = progress_bar()
            mybar.start()
        for j in range(kidpar['type'].size/2):
            if i == 0:
                mybar.update((mybar.maxval/(kidpar['type'].size/2))*j)
            data[j,0,:,:] /= np.max(data[j,0,:,:])
            probs = model.predict(data[np.newaxis, j])
            prediction = probs.argmax(axis=1)

            if ((prediction[0] == 1) | (prediction[0] == 2)):
                kidpar['type'][j] = 5

            if kidpar['type'][j] != 5:
                if ((kidpar['array'][j] == 1) | (kidpar['array'][j] == 3)):
                    #if A1 or A3 then match with 2D Gaussian of 12.5" FWHM
                    m1 = find_double_kid.double_finder(maptemplate_1mm,np.transpose(data[j,0,14:207,53:170]),calibrate=1)
                    mean[0].append(m1)
                else:
                    #if A2 then match with 2D Gaussian of 18.5" FWHM
                    m2 = find_double_kid.double_finder(maptemplate_2mm,np.transpose(data[j,0,14:207,53:170]),calibrate=1)
                    mean[1].append(m2)
        if i == 0:
            mybar.finish()
        
        return mean

    dumb = Parallel(n_jobs=ncpu)(delayed(Calibrate_noise)(i) for i in range(ncpu))

    results_calib = np.asarray(dumb)
    mean_arr_1mm = []
    mean_arr_2mm = []
    
    for i in range(ncpu):
        mean_arr_1mm += results_calib[i][0]
        mean_arr_2mm += results_calib[i][1]


    #pdb.set_trace()

    values1, base1 = np.histogram(mean_arr_1mm, bins=200)
    cumulative1 = np.cumsum(values1)
    noise_1mm = np.max(base1[np.where((cumulative1/np.double(np.max(cumulative1))) < 0.98)])

    values2, base2 = np.histogram(mean_arr_2mm, bins=200)
    cumulative2 = np.cumsum(values2)
    noise_2mm = np.max(base2[np.where((cumulative2/np.double(np.max(cumulative2))) < 0.98)])
        
    #centered_mean_1mm = mean_arr_1mm-np.median(mean_arr_1mm)
    #wneg1 = np.where(centered_mean_1mm < 0)
    #sym_mean_1mm = np.concatenate((centered_mean_1mm[wneg1],-1.*centered_mean_1mm[wneg1]))
    #noise_1mm = np.median(mean_arr_1mm) + 10.*np.std(sym_mean_1mm)
    #noise_1mm = np.max(mean_arr_1mm)

    #centered_mean_2mm = mean_arr_2mm-np.median(mean_arr_2mm)
    #wneg2 = np.where(centered_mean_2mm < 0)
    #sym_mean_2mm = np.concatenate((centered_mean_2mm[wneg2],-1.*centered_mean_2mm[wneg2]))
    #noise_2mm = np.median(mean_arr_2mm) + 10.*np.std(sym_mean_2mm)
    #noise_2mm = np.max(mean_arr_2mm)

    
    def Calibrate_width(i):
        opt = SGD(lr=0.01)
        model = LeNet.build(width=221, height=221, depth=1, classes=3,
                            weightsPath=args["weights"] if args["load_model"] > 0 else None)
        model.compile(loss="categorical_crossentropy", optimizer=opt,
                      metrics=["accuracy"])
        
        beam_dir = args["beam_dir"]
        beammap = args["beammap"]
        ncpu = args["ncpu"]
        iteration = args["iter"]

        maps = scipy.io.readsav(beam_dir+'map_lists_'+beammap+'_sub_'+str(i)+'.save')
        dataset = np.abs(maps['map_list_azel'])
        data = np.transpose(dataset)[:, np.newaxis, :, :]
        kidpar = maps['kidpar']

        width = [[],[]]
        
        if i == 0:
            mybar = progress_bar()
            mybar.start()
        for j in range(kidpar['type'].size/2):
            if i == 0:
                mybar.update((mybar.maxval/(kidpar['type'].size/2))*j)
            data[j,0,:,:] /= np.max(data[j,0,:,:])
            probs = model.predict(data[np.newaxis, j])
            prediction = probs.argmax(axis=1)

            if ((prediction[0] == 1) | (prediction[0] == 2)):
                kidpar['type'][j] = 5

            if kidpar['type'][j] != 5:
                if ((kidpar['array'][j] == 1) | (kidpar['array'][j] == 3)):
                    #if A1 or A3 then match with 2D Gaussian of 12.5" FWHM
                    w1 = find_double_kid.double_finder(maptemplate_1mm,np.transpose(data[j,0,14:207,53:170]),calibrate=1,noise=noise_1mm)
                    width[0].append(w1)
                else:
                    #if A2 then match with 2D Gaussian of 18.5" FWHM
                    w2 = find_double_kid.double_finder(maptemplate_2mm,np.transpose(data[j,0,14:207,53:170]),calibrate=1,noise=noise_2mm)
                    width[1].append(w2)
        if i == 0:
            mybar.finish()
        
        return width

    dumb = Parallel(n_jobs=ncpu)(delayed(Calibrate_width)(i) for i in range(ncpu))

    results_calib = np.asarray(dumb)
    width_arr_1mm = []
    width_arr_2mm = []
    
    for i in range(ncpu):
        width_arr_1mm += results_calib[i][0]
        width_arr_2mm += results_calib[i][1]

    """thresh_1mm_i = 0.
    thresh_1mm_f = np.max(width_arr_1mm)/5.

    while (np.abs(thresh_1mm_i - thresh_1mm_f) > 1e-1):
        thresh_1mm_i = thresh_1mm_f
        values1, base1 = np.histogram(width_arr_1mm, bins=1000, range=[0,5.*thresh_1mm_i])
        cumulative1 = np.cumsum(values1)
        thresh_1mm_f = np.max(base1[np.where((cumulative1/np.double(np.max(cumulative1))) < 0.98)])


    thresh_2mm_i = 0.
    thresh_2mm_f = np.max(width_arr_2mm)/5.

    while (np.abs(thresh_2mm_i - thresh_2mm_f) > 1e-1):
        thresh_2mm_i = thresh_2mm_f
        values2, base2 = np.histogram(width_arr_2mm, bins=1000, range=[0,5.*thresh_2mm_i])
        cumulative2 = np.cumsum(values2)
        thresh_2mm_f = np.max(base2[np.where((cumulative2/np.double(np.max(cumulative2))) < 0.98)])

    thresh_1mm = thresh_1mm_f
    thresh_2mm = thresh_2mm_f"""

    #pdb.set_trace()

    centered_width_1mm = width_arr_1mm-np.median(width_arr_1mm)
    wneg1 = np.where(centered_width_1mm < 0)
    sym_width_1mm = np.concatenate((centered_width_1mm[wneg1],-1.*centered_width_1mm[wneg1]))
    thresh_1mm = np.median(width_arr_1mm) + 6.*np.std(sym_width_1mm)

    centered_width_2mm = width_arr_2mm-np.median(width_arr_2mm)
    wneg2 = np.where(centered_width_2mm < 0)
    sym_width_2mm = np.concatenate((centered_width_2mm[wneg2],-1.*centered_width_2mm[wneg2]))
    thresh_2mm = np.median(width_arr_2mm) + 6.*np.std(sym_width_2mm)

    print "==============================================================="
    print "A1&3 threshold: "+str(noise_1mm)
    print "         width: "+str(thresh_1mm)
    print "A2   threshold: "+str(noise_2mm)
    print "         width: "+str(thresh_2mm)
    print "==============================================================="

    beam_dir = args["beam_dir"]
    beammap = args["beammap"]
    filename = 'Double_criteria_'+beammap+'.pdf'
    fullpath = os.path.join(beam_dir, filename)
    with PdfPages(fullpath) as pdf:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            fig, ax = plt.subplots(nrows=1, sharex=True)
            ax.xaxis.set_tick_params(width=1.5)
            ax.yaxis.set_tick_params(width=1.5)
            ax.xaxis.set_tick_params(which=u'minor',width=1.5)
            ax.yaxis.set_tick_params(which=u'minor',width=1.5)
            plt.rc('text', usetex=True)
            plt.rcParams['text.latex.preamble'] = [r'\boldmath']
            plt.xlabel(r'$\mathbf{\mathrm{threshold}}$',fontsize=14)
            plt.xticks(fontsize=14,weight=10)
            plt.yticks(fontsize=14,weight=10)
            plt.grid(alpha=0.3)
            plt.hist(mean_arr_1mm,range=[min(mean_arr_1mm),3.*noise_1mm],bins=200)
            plt.plot(np.asarray([noise_1mm,noise_1mm]),np.asarray([0,100]),color='red',lw=2)
            pdf.savefig()  
            plt.close()

            fig, ax = plt.subplots(nrows=1, sharex=True)
            ax.xaxis.set_tick_params(width=1.5)
            ax.yaxis.set_tick_params(width=1.5)
            ax.xaxis.set_tick_params(which=u'minor',width=1.5)
            ax.yaxis.set_tick_params(which=u'minor',width=1.5)
            plt.rc('text', usetex=True)
            plt.rcParams['text.latex.preamble'] = [r'\boldmath']
            plt.xlabel(r'$\mathbf{\mathrm{threshold}}$',fontsize=14)
            plt.xticks(fontsize=14,weight=10)
            plt.yticks(fontsize=14,weight=10)
            plt.grid(alpha=0.3)
            plt.hist(mean_arr_2mm,range=[min(mean_arr_2mm),3.*noise_2mm],bins=200)
            plt.plot(np.asarray([noise_2mm,noise_2mm]),np.asarray([0,60]),color='red',lw=2)
            pdf.savefig()  
            plt.close()

            fig, ax = plt.subplots(nrows=1, sharex=True)
            ax.xaxis.set_tick_params(width=1.5)
            ax.yaxis.set_tick_params(width=1.5)
            ax.xaxis.set_tick_params(which=u'minor',width=1.5)
            ax.yaxis.set_tick_params(which=u'minor',width=1.5)
            plt.rc('text', usetex=True)
            plt.rcParams['text.latex.preamble'] = [r'\boldmath']
            plt.xlabel(r'$\mathbf{\mathrm{width}}$',fontsize=14)
            plt.xticks(fontsize=14,weight=10)
            plt.yticks(fontsize=14,weight=10)
            plt.grid(alpha=0.3)
            plt.hist(width_arr_1mm,range=[min(width_arr_1mm),3.*thresh_1mm],bins=200)
            plt.plot(np.asarray([thresh_1mm,thresh_1mm]),np.asarray([0,100]),color='red',lw=2)
            pdf.savefig()  
            plt.close()

            fig, ax = plt.subplots(nrows=1, sharex=True)
            ax.xaxis.set_tick_params(width=1.5)
            ax.yaxis.set_tick_params(width=1.5)
            ax.xaxis.set_tick_params(which=u'minor',width=1.5)
            ax.yaxis.set_tick_params(which=u'minor',width=1.5)
            plt.rc('text', usetex=True)
            plt.rcParams['text.latex.preamble'] = [r'\boldmath']
            plt.xlabel(r'$\mathbf{\mathrm{width}}$',fontsize=14)
            plt.xticks(fontsize=14,weight=10)
            plt.yticks(fontsize=14,weight=10)
            plt.grid(alpha=0.3)
            plt.hist(width_arr_2mm,range=[min(width_arr_2mm),3.*thresh_2mm],bins=200)
            plt.plot(np.asarray([thresh_2mm,thresh_2mm]),np.asarray([0,80]),color='red',lw=2)
            pdf.savefig()  
            plt.close()


    print "KID selection..."
    print "==============================================================="
    
    #=================================================
    #Automatic selection for a convnet already trained:
    #=================================================
    if args["load_model"] > 0:
        print("[INFO] compiling model...")
        ncpu = args["ncpu"]
        def processInput(i):
            opt = SGD(lr=0.01)
            model = LeNet.build(width=221, height=221, depth=1, classes=3,
                                weightsPath=args["weights"] if args["load_model"] > 0 else None)
            model.compile(loss="categorical_crossentropy", optimizer=opt,
                          metrics=["accuracy"])

            beam_dir = args["beam_dir"]
            beammap = args["beammap"]
            ncpu = args["ncpu"]
            iteration = args["iter"]
            kidpar_dir = args["kidpar_dir"]
            
            maps = scipy.io.readsav(beam_dir+'map_lists_'+beammap+'_sub_'+str(i)+'.save')
            dataset = np.abs(maps['map_list_azel'])
            data = np.transpose(dataset)[:, np.newaxis, :, :]

            hdukp = fits.open(kidpar_dir+'kidpar_'+beammap+'_'+str(i)+'.fits')
            kidpar = hdukp[1].data

            if i == 0:
                mybar = progress_bar()
                mybar.start()
            for j in range(kidpar['type'].size):
                if i == 0:
                    mybar.update((mybar.maxval/(kidpar['type'].size))*j)

                if (kidpar['type'][j] == 1):
                    data[j,0,:,:] /= np.max(data[j,0,:,:])
                    probs = model.predict(data[np.newaxis, j])
                    prediction = probs.argmax(axis=1)

                    if ((prediction[0] == 1) | (prediction[0] == 2)):
                        kidpar['type'][j] = 5
                    if iteration == 2:
                        if ((kidpar['array'][j] == 1) | (kidpar['array'][j] == 3)):
                            #if A1 or A3 then match with 2D Gaussian of 12.5" FWHM
                            is_double = find_double_kid.double_finder(maptemplate_1mm,np.transpose(data[j,0,14:207,53:170]),thresh=thresh_1mm,noise=noise_1mm) 
                        else:
                            #if A2 then match with 2D Gaussian of 18.5" FWHM
                            is_double = find_double_kid.double_finder(maptemplate_2mm,np.transpose(data[j,0,14:207,53:170]),thresh=thresh_2mm,noise=noise_2mm) 
                        if is_double:
                            kidpar['type'][j] = 5
            if i == 0:
                mybar.finish()
            # Warning ! astropy.io.fits does not handle dtype = 'O' (object type) --> change the type to a more appropriate one. e.g. the 'NAME' entry is a list of string... 
            newname = kidpar['name'].astype('|S5')
            newunits = kidpar['units'].astype('|S7')
            newscan = kidpar['scan'].astype('|S1')

            t = Table(kidpar)
            t.replace_column('NAME', newname)
            t.replace_column('UNITS', newname)
            t.replace_column('SCAN', newname)
            fits.writeto(kidpar_dir+'kidpar_'+beammap+'_'+str(i)+'.fits',np.array(t),clobber=True)
            return i
            
        dumb = Parallel(n_jobs=ncpu)(delayed(processInput)(i) for i in range(ncpu))

        do_plot = args["plot"]
        if do_plot:
            print "Display discarded KIDs in pdf file..."
            print "==============================================================="

            filename = 'KID_selection_not_valid_'+beammap+'.pdf'
            fullpath = os.path.join(beam_dir, filename)
            kidpar_dir = args["kidpar_dir"]
            with PdfPages(fullpath) as pdf:
                for i in range(ncpu):
                    hdu = fits.open(kidpar_dir+'kidpar_'+beammap+'_'+str(i)+'.fits')
                    kidpar = hdu[1].data
                    wreject = np.where(kidpar['type'] == 5)

                    maps = scipy.io.readsav(beam_dir+'map_lists_'+beammap+'_sub_'+str(i)+'.save')
                    dataset = np.abs(maps['map_list_azel'])
                    data = np.transpose(dataset)[:, np.newaxis, :, :]

                    for j in range(len(wreject[0])):
                        data[wreject[0][j],0,:,:] /= np.max(data[wreject[0][j],0,:,:])
                        plt.imshow(np.transpose(data[wreject[0][j]][0]),cmap=cmap,origin='lower')
                        pdf.savefig()  
                        plt.close()


                
