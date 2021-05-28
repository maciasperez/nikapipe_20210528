
import numpy as np
import os

def scann2scannr(scannum):
    s = np.long(scannum)
    scannumr = str(s)
    if s < 1000:
        scannumr = '0'+scannumr
        if s < 100:
            scannumr = '0'+scannumr
            if s < 10:
                scannumr = '0'+scannumr
    return scannumr
        
    
    
def scan2daynum(scan):

#   date =[]#
#   scannum = []
#   for sc in scan: 
    date,n = scan.split('s')
    scannum = np.long(n)
#       date.append(d)
#       scannum.append(np.long(n))
    return date,scannum


def scan2run(scan):

    """ Copied directly from IDL files """

# Define the data dir
    

#    data_dir = os.getenv()
#
    day, scan_num = scan2daynum(scan)

    if (np.long(day) > 20121101 & np.long(day) < 20121127): run='5'
    if (np.long(day) > 20130601 & np.long(day) < 20130620): run='6'
    if (np.long(day) > 20131101 & np.long(day) < 20131129): run='cryo'
    if (np.long(day) > 20140101 & np.long(day) < 20140131): run='7'
    if (np.long(day) > 20140201 & np.long(day) < 20140601): run='8'
    if (np.long(day) > 20140201 & np.long(day) <= 20140930): run='8'
    if (np.long(day) > 20140930 & np.long(day) < 20141106): run='9'
    if (np.long(day) >= 20141106 & np.long(day) < 20150123): run='10'
    if (np.long(day) >= 20150123 & np.long(day) < 20150210): run='11'
#     ;; Open Pool 3 = Run11, ended on Feb. 10th in the morning, and the polarization run (12)
#     ;; started the same day in the evening.

    if (np.long(day) == 20150210):
        if scan_num <= 157:
##        ;; still openpool3
            run = '11'
        else:
##        ;; Polarization run
            run = '12'
    
    if (np.long(day) > 20150210 & np.long(day) <= 20150928) : run = '12'

##  ;;---------------------------------------------------------------------------
##  ;; NIKA2 Run 1
    if (np.long(day) > 20150929 & np.long(day) <= 20151110): run = '13'
        
#  ;;---------------------------------------------------------------------------
#  ;; NIKA2 Second Run, End of November 2015
    if np.long(day) >= 20151124 & np.long(day) < 20160112: 
        run = '14'
        acq_dir = "/run14_X/"

#  ;;---------------------------------------------------------------------------
#  ;; NIKA2 third Run, Jan-Feb 2016
    if np.long(day) >= 20160112 & np.long(day) < 20160229:
        run = '15'
        acq_dir = "/run15_X/"

  
#  ;;---------------------------------------------------------------------------
#  ;; NIKA2 fourth run, March 2016
    if np.long(day) >= 20160301 & np.long(day) < 20160630: 
        run = '16'
        acq_dir = "/run16_X/"

    if np.long(day) >= 20160901 & np.long(day) < 20161020: 
        run = '18'
        acq_dir = "/run18_X/scan_36X/"
        pref = 'X_'

    if np.long(day) >= 20161020: 
        run = '19'
        acq_dir = "/run19_X/scan_36X/"
        pref = 'X_'

    if np.long(day) >= 20161102:
        run = '20'
        acq_dir = "/run20_X/scan_36X/"
        pref = 'X_'
        
    if np.long(day) >= 20170220:
        run = '22'
        acq_dir = "/run22_X/scan_36X/"
        pref = 'X_'

    if np.long(day) >= 20170413:
        run = '23'
        acq_dir = "/run23_X/scan_36X/"
        pref = 'X_'

    if np.long(day) >= 20171018:
        run = '23'
        acq_dir = "/run25_X/scan_36X/"
        pref = 'X_'
        
    return run, acq_dir,pref


def scan2rawfile(scan):
    date,scannum = scan.split('s')
    year = date[0:4]
    month = date[4:6]
    day = date[6:]
    run, acq_dir,pref = scan2run(scan)

    file = get_raw_data_dir() + acq_dir + pref+year+'_'+month+'_'+day+'_AA_'+ scann2scannr(scannum)
    return file


def get_raw_data_dir():

    dirdata = '/home/nika2/NIKA/Data/'
    return dirdata

def find_new_scans(run):
    rawdir =  get_raw_data_dir()

    if run == 19:
        dirdata = rawdir + 'run19_X/scan_36X/'

    if run == 20:
        dirdata = rawdir + 'run20_X/scan_36X/'
        
    if run == 22:
        dirdata = rawdir + 'run22_X/scan_36X/'
                 
    if run == 21:
        dirdata = rawdir + 'run21_X/scan_36X/'

    if run == 22:
        dirdata = rawdir + 'run22_X/scan_36X/'

    if run == 23:
        dirdata = rawdir + 'run23_X/scan_36X/'

    if run == 25:
        dirdata = rawdir + 'run25_X/scan_36X/'

    filesF = str.split(os.popen('ls '+dirdata+'/F_*').read())
    filesX = []
    for file in filesF:
        filesX.append(file.replace('F_','X_'))
    return filesF,filesX
