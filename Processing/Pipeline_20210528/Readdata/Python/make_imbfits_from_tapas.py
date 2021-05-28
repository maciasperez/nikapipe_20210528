#!/usr/bin/env python

import xmlrpclib
import string as str
import scan2run as sr
import make_IMBFITS_nika as imb
import time
import os
import numpy as np
import sla
import datetime
from joblib import Parallel, delayed
import thread

dirdata= '/home/nika2/NIKA/Data/'
outdir ='/home/nika2/NIKA/Data/NIKAIMBFITS/'


def find_scan_pos(tr,scan):
    ns = len(tr)
    pos=-1
    for idx in range(ns):
        t = tr[idx]
        day, scannum= t['ncsId'].split('.')
        day1, scannum1= scan.split('.')
        if day == day1:
            if scannum == scannum1:
                pos = idx
    return pos
        

def file2imbfits(infile,dirdata,outdir):
    
    dummy = os.system('ls '+infile)
    if dummy == 0:            
        #imb.make_IMBFITS(InputFileStub = scan, NIKAarray=1,remotelocal='local', rawFile= infile ,outdir=outdir,silent=1)
        #imb.make_IMBFITS(InputFileStub = scan, NIKAarray=2,remotelocal='local', rawFile= infile ,outdir=outdir,silent=1)
        #imb.make_IMBFITS(InputFileStub = scan, NIKAarray=3,remotelocal='local', rawFile= infile ,outdir=outdir,silent=1)
        #thread.start_new_thread(imb.make_IMBFITS , ( scan,1,'local',  infile ,outdir,1) )
        #thread.start_new_thread(imb.make_IMBFITS , ( scan,2,'local',  infile ,outdir,1) )
        #thread.start_new_thread(imb.make_IMBFITS , ( scan,3,'local',  infile ,outdir,1) )
        pos = infile.find('X_')
        scan = infile[pos+2:]
        scan = scan.replace('_','')
        scan,num = scan.split('AA')
        scan = scan +'s'+ np.str(str.atoi(num))
        print 'Working on scan: '+ scan
        Parallel(n_jobs=3)(delayed(imb.make_IMBFITS)(InputFileStub = scan, NIKAarray=i+1,remotelocal='local', rawFile= infile ,outdir=outdir,silent=1) for i in range(3))

    return

def scan2imbfits(scan,dirdata,outdir):
    
    date,scannum = scan.split('s')
    year = date[0:4]
    month = date[4:6]
    day = date[6:]
    run, acq_dir,pref = sr.scan2run(scan)
    #print scan
    #print run, acq_dir,pref
    infile = dirdata + acq_dir + pref+year+'_'+month+'_'+day+'_AA_'+ sr.scann2scannr(scannum)

    dummy = os.system('ls '+infile)
    if dummy == 0:            
        #imb.make_IMBFITS(InputFileStub = scan, NIKAarray=1,remotelocal='local', rawFile= infile ,outdir=outdir,silent=1)
        #imb.make_IMBFITS(InputFileStub = scan, NIKAarray=2,remotelocal='local', rawFile= infile ,outdir=outdir,silent=1)
        #imb.make_IMBFITS(InputFileStub = scan, NIKAarray=3,remotelocal='local', rawFile= infile ,outdir=outdir,silent=1)
        #thread.start_new_thread(imb.make_IMBFITS , ( scan,1,'local',  infile ,outdir,1) )
        #thread.start_new_thread(imb.make_IMBFITS , ( scan,2,'local',  infile ,outdir,1) )
        #thread.start_new_thread(imb.make_IMBFITS , ( scan,3,'local',  infile ,outdir,1) )
        Parallel(n_jobs=3)(delayed(imb.make_IMBFITS)(InputFileStub = scan, NIKAarray=i+1,remotelocal='local', rawFile= infile ,outdir=outdir,silent=1) for i in range(3))

    return

def update_date(date_start,nbmin):
    date,hour = date_start.split('T')
    year,month,day = date.split('-')
    h,m,s = hour.split(':')

    fracday =  (str.atof(h)+str.atof(m)/60.0+str.atof(s)/3600.0)/24.0
    mjd = sla.mjd(str.atoi(year),str.atoi(month),str.atof(day))+ fracday
    mjd += nbmin/60.0/24.0

    year,month,day,fracday = sla.djcl(mjd)
    h = np.int(fracday*24)
    fracday = fracday-h/24.0
    m = np.int(fracday*24.0*60.0)
    fracday = fracday - m/24.0/60.0
    s = fracday*24*3600.0

    hh = np.str(h)
    if h <10:
        hh = '0'+hh
    mm = np.str(m)
    if m < 10:
        mm = '0'+mm
    ss = np.str(np.int(s))
    if s < 10:
        ss = '0'+ss
        
    date_end = np.str(year)+'-'+np.str(month)+'-'+np.str(day)+'T'+hh+':'+mm+':'+ss
    date_now = get_date_now()
    date_end = date_compare(date_end,date_now)
    
    return date_end

def date_compare(date1,date2):
    date,hour = date1.split('T')
    year,month,day = date.split('-')
    h,m,s = hour.split(':')
    fracday =  (str.atof(h)+str.atof(m)/60.0+str.atof(s)/3600.0)/24.0
    mjd1 = sla.mjd(str.atoi(year),str.atoi(month),str.atof(day))+ fracday

    date2,hour2 = date2.split('T')
    year2,month2,day2 = date2.split('-')
    h2,m2,s2 = hour2.split(':')
    fracday2 =  (str.atof(h2)+str.atof(m2)/60.0+str.atof(s2)/3600.0)/24.0
    mjd2 = sla.mjd(str.atoi(year2),str.atoi(month2),str.atof(day2))+ fracday2

    if mjd1 > mjd2:
        return date2
    else:
        return date1
    return

def get_date_now():
    now = datetime.datetime.now()
    date_now = now.strftime("%Y-%m-%dT%H:%M:%S")
    return date_now

def new_scan_tapas2imbfits(date_start):
    """
     Find scans
    """
    dirdata= '/home/nika2/NIKA/Data/'
    outdir ='/home/nika2/NIKA/Data/NIKAIMBFITS/'
    dummy = 0
    while(dummy == 0):
        date_end = update_date(date_start,30)
        s = xmlrpclib.ServerProxy('https://tapas.iram.es/tapas/xml_rpc')
        tr  = (s.getNikaScansByParams('t22','30m/kitu/t22', date_start, date_end, '', 0., 1.0, ''))
        if len(tr) == 0:
            time.sleep(1)
            print "No scans from "+date_start+ "  to  "+date_end
            
        else:
            nscans = len(tr)
            scan_list = []
            ibeg = 0
            for idx in range(ibeg,nscans):
                r = tr[idx]
                #print r
                if r['type'] != 'track':
                    day,snum = r['ncsId'].split('.')
                    day = day.replace('-','')
                    scan = day+'s'+snum
                    #print scan
                    scan2imbfits(scan,dirdata,outdir)
                    
        date_start = date_end
        date_now = get_date_now()
        date_start = date_compare(date_start,date_now)

def new_scan2imbfits():
    """
     Find scans
    """
    lastid = ''
    dirdata= '/home/nika2/NIKA/Data/'
    outdir ='/home/nika2/NIKA/Data/NIKAIMBFITS/'
    dummy = 0
    while(dummy == 0):
        s = xmlrpclib.ServerProxy('https://tapas.iram.es/tapas/xml_rpc')
        tr = (s.getNikaLastCompletedScan('t22','30m/kitu/t22'))
        if len(tr) == 0:
            time.sleep(60)
        else:
            r = tr[0]
            if r['ncsId'] != lastid:
                if r['type'] != 'track':
                    print "Working on scan: "+r['ncsId']
                    lastid = r['ncsId']
                    day,snum = r['ncsId'].split('.')
                    day = day.replace('-','')
                    scan = day+'s'+snum
                    #print scan
                    #try:
                    #   print "I SEND NOW"
                       # thread.start_new_thread( scan2imbfits, (scan,dirdata,outdir) )
                    #except:
                    #    print "Error: unable to start thread"
                    scan2imbfits(scan,dirdata,outdir)


def make_imbfits_tapas(date_start,date_end,scan_start = ' '):

    # find nika dir
    dirdata= '/home/nika2/NIKA/Data/'
    outdir ='/home/nika2/NIKA/Data/NIKAIMBFITS/'
    # find scans
    s = xmlrpclib.ServerProxy('https://tapas.iram.es/tapas/xml_rpc')

    tr  = (s.getNikaScansByParams('t22','30m/kitu/t22', date_start, date_end, '', 0., 1.0, ''))
    if scan_start == ' ':
        ibeg = 0
    else:
        ibeg = find_scan_pos(tr,scan_start)
        if ibeg == -1:
            ibeg = 0

    nscans = len(tr)
    scan_list = []
    for idx in range(ibeg,nscans):
        r = tr[idx]
        #print r
        if r['type'] != 'track':
            day,snum = r['ncsId'].split('.')
            day = day.replace('-','')
            scan = day+'s'+snum
            #print scan
            scan2imbfits(scan,dirdata,outdir)
    return

def make_imbfits_scanlist(scans):
    dirdata= '/home/nika2/NIKA/Data/'
    outdir ='/home/nika2/NIKA/Data/NIKAIMBFITS/'
    for scan in scans:
       scan2imbfits(scan,dirdata,outdir) 
    return

def make_imbfits_ffile(run):
    dummy = 1
    while(dummy == 1):
        filesF,filesX = sr.find_new_scans(run)
        nfiles = len(filesF)
        if nfiles >0 :
            for idx in range(nfiles):
                ffile = filesF[idx] 
                pfiles = ffile.replace('F_','P_')
                dum = os.popen('touch '+pfiles)
                dum = os.popen('rm '+filesF[idx])
                infile = filesX[idx]
                file2imbfits(infile,dirdata,outdir)
                dum = os.popen('rm '+pfiles)
        else:
            time.sleep(10)
    return

if __name__ == "__main__":

#    date_start = '2016-10-27T06:48:00'
    #   new_scan_tapas2imbfits(date_start)
#    date_end = '2016-10-25T23:59:59'
    #new_scan2imbfits()
    #make_imbfits_tapas(date_start,date_end,scan_start='2016-10-09.151')
    #make_imbfits_tapas(date_start,date_end)

    # NEW FUNCTIONS
    #scans = ['20161026s'+np.str(x) for x in [57,89,99,105,115,116,118,131]]
    #scans = scans + ['20161027s'+np.str(x) for x in [10,11,12,13,22,23,24,30,31,33,34,35]]
    #scans = ['20161030s199']
    #make_imbfits_scanlist(scans)
    #Automatic procedure
#    make_imbfits_ffile(19)
# configured for run 20 now
    make_imbfits_ffile(23)
