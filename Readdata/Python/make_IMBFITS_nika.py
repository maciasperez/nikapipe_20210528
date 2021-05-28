#!/usr/bin/env python
"""
 Name makeIMBF-NIKA2.py
 Version 2.06 Cloned from makeIMBF-EMIR.py
 Version 2.07 2011-03-09 A.Sievers work towards makeIMBF-NIKA.py started again
 Version 2.11 2011-10-19 A. Sievers new Datastream format
 Version 3.00 2012-10-05 A. Sievers new Antenna tables
 Version 3.1  2014-02-03 A. Sievers time stamps apply to middle of interval
 Version 10.0  2015-09-29 A. Sievers start of NIKA2
 Version 10.4  2016-12-02 JM/AS function that can run continuously
 example call ?? 
 makeIMBF-NIKA2.py 20161006s91 2 local /home/nika2/NIKA/Data/run18_X/scan_36X/X_2016_10_06_AA_0091 /home/nika2/NIKA/Data/NIKAIMBFITS/
"""
import sys
import os
import string
import glob
import time
#import numarray
import math
#import TableIO
import pcfitsio

import pickle
import anydbm
import numpy as nup
# IRAM
## imported later in scanSpecParser
## import ncsMessage
import sla
import EOP
##import sla as slalf
##from scanSpecParser import *
import scanSpecParser as sSP

import pdb
# query the Tau DB

import MySQLdb
import datetime

from read_nika_data import *

__version__ = "10.6"
__author__ = "A.Sievers"
__date__ = "2017-04-18"

def getTau(startDateTime, endDateTime):
    db=MySQLdb.connect(host="mrt-lx3.iram.es", user="weather", passwd="kE72VSJK3KFoKobr",db="weather")
    c=db.cursor()
    f = '%Y-%m-%d %H:%M:%S'
    c.execute("""
            SELECT tau, tauTimestamp as timestamp, tauSigma as sigma, tauFit as fit 
            FROM taumeter2016
            WHERE tauTimestamp>='%s' and tauTimestamp<='%s'
            ORDER BY 2
            """ % (startDateTime.strftime(f), endDateTime.strftime(f)))

    return c.fetchall()

#if __name__ == "__main__":
def make_IMBFITS(InputFileStub = '',NIKAarray=1,remotelocal='local', rawFile= ' ' ,outdir='',silent=0):
   # outdir definition
#   print sys.argv[5]
#   outdir = sys.argv[5]
   if outdir == ' ':
      outdir ='./'
   #print sys.argv[0]
   logger = sSP.ncsMessage.Logger()
   ChosenBackend='NIKA'
#   for substr in ['continuum','NIKA','NIKA1mm','NIKA2mm']:
#      if string.count(sys.argv[0],substr) > 0:
#         position=string.find(sys.argv[0],substr)
#         ChosenBackend=sys.argv[0][position:position+len(substr)]
#         if silent !=1: print 'Do the '+ChosenBackend+' case'

   import imbfits_NIKA
#   if ChosenBackend == 'none':
#      if silent !=1: print 'No supported Backend found '+ChosenBackend
#      sys.exit(1)

   ## Preliminaries, constants
   import enum
   sourcePlanet = []
   for key in enum.enums["sourcePlanet"].keys():
      sourcePlanet.append(key)

   # Time (UTC ?) of writing the fits file
   Now = time.gmtime()
   DateWritten = time.strftime("%Y-%m-%dT%H:%M:%S",Now)
   if silent !=1: print DateWritten
   MJD1970 = 40587.0  # In the antenna traces we have no. of days since 1 January 1979 00:00 UTC
                      # This is the offset to real MJD
   ##MJDfudge = 1.0/86400. ## Fix this in antMD +1 second time correction for slow antenna traces
   MJDfudge = 0.0 ## A.P. found 1 second error in reading the clock
   #encToDeg = (9.*2**-10)/3600.
   encToRad = (9.*2**-10)*math.pi/648000.
   sencToRad = 0.0001*math.pi/180.
   asecToRad = math.pi/180./3600.
   expTime=0.0
   slowRate=8
   NIKAChannels=400
### Should be set from input line
#   NIKAarray=2
#   if len(sys.argv)>2:
#      NIKAarray=string.atoi(sys.argv[2])
   if silent !=1: print "Processing Array No.",NIKAarray
   ## Initialize this class once
   imbfits_NIKA.ComClass = imbfits_NIKA.iram_connector.ComClass()

   # The Header

#   if len(sys.argv)>1:
#      InputFileStub = sys.argv[1]
#   else:
#      InputFileStub = '20050519s16'

   InDir = InputFileStub[:8]+'/scans/'+InputFileStub[9:]
# Standard place
   DataRootDir = '/ncsServer/mrt/ncs/data/'
##   DataRootDir = '/ncsServer/mrt/ncs/data/NIKAData/'
#
# on mrt-lx1 backup datastream disk
##   DataRootDir = '/media/DatastreamsDisk/Datastreams/'
##   DataRootDir = '/ncsServer/mrt/ncs/data/oldData/'
##   DataRootDir = '/ltmp/Nika/'
##   DataRootDir = '/Scratch/nika/'
# On mrt-lx2 USB disk
##   DataRootDir = '/media/sievers/nika2/'
   if silent !=1: print 'DataRootDir = ',DataRootDir

   InputFile=open(DataRootDir + InDir + '/log/iram30m-scan-' + InputFileStub + '.pickle','r')

   SDate=InputFileStub[:8]
   Date=SDate[:4]+'-'+SDate[4:6]+'-'+SDate[-2:]
   scanId=Date+'.'+InputFileStub[9:]
   offLine=False
   zeroData=False
#   if len(sys.argv)>3:
#      if silent !=1: print '>>',sys.argv[3],'<<'
#      if sys.argv[3]=='remote':
#         offLine=True
   if remotelocal =='remote':
      offLine=True
   ## Monitor message
   if offLine:
      logger.ncsMonitor(logId="scanInfo:makeIMBFitsStarted",
                        data={"scanId": scanId})
   else:
      if silent !=1: print 'makeIMBFits started'

   subscanToDo=0

   ## Read header information from PICKLE file
   obsBlock = pickle.load(InputFile)
   #obsBlock.dump()
   InputFile.close()
   ## In case we have a SSB calibration
   receiverNameSSB='None'
   #key =  'observingBlock.scans.scan.observingMode.receiverName'
   #if obsBlock.allParams.has_key(key):
   #   receiverNameParams = obsBlock.allParams[key]
   #   if silent !=1: print "...observingMode.receiverName:",obsBlock.allParams[key].dump() 
   #   receiverNameSSB = getNormValue(receiverNameParams.attrs)
   #   if silent !=1: print "receiverName for SSB-cal :", receiverNameSSB
   #if silent !=1: print "dir of obsBlock:", dir(obsBlock)
   #if silent !=1: print obsBlock.allParams.keys()

   subscan_range = len(obsBlock.scans.list[0].subscans.list)

   # Find start of observation
   ## Can not open the data base on a NFS mounted partition, copy it to the local drive first
   ##syncMsg = anydbm.open('/tmp/syncMsgDB.dbm')
   syncM=[]
   #syncMsg = anydbm.open(InDir+'syncMsgDB.dbm','ru')
   syncMsg = anydbm.open(DataRootDir + InDir + '/log/iram30m-sync-' + InputFileStub +'.dbm','ru')
   for key in syncMsg.keys():
   #   if silent !=1: print key,'MSG:',syncMsg[key]
      syncM.append(syncMsg[key]+' MSG: '+key)

   syncM.sort()
   for i in range(len(syncM)):
       if silent !=1: print i,syncM[i]

   # Find the start of scan
   iScanNo = string.atoi(InputFileStub[9:])
   iSubScanNo = '1'
   #findKey ='masterCS:2004-05-19.19:scanStarted'
   findKey ="antMD:%s.%s.%s:subscanStarted" % (Date,iScanNo,iSubScanNo)
   found = syncMsg.has_key(findKey)
   if not found:   
      findKey ="masterCS:%s.%s:scanStarted" % (Date,iScanNo)
      found = syncMsg.has_key(findKey)
   if found:
      DateTime = syncMsg[findKey]
      if silent !=1: print findKey,syncMsg[findKey]
      iYear = string.atoi(DateTime[:4])
      CiY = DateTime[:4]
      iMonth = string.atoi(DateTime[5:7])
      CiM = DateTime[5:7]
      iDay = string.atoi(DateTime[8:10])
      CiD = DateTime[8:10]
      sHours = string.atoi(DateTime[11:13]) 
      sMinutes = string.atoi(DateTime[14:16]) 
      sSeconds = string.atof(DateTime[17:23])
      siteTime = ((sHours*60 + sMinutes)*60.+sSeconds)
      MJDOBS = sla.mjd(iYear,iMonth,iDay)+siteTime/86400.
      SDateMES = DateTime[:4]+DateTime[5:7]+DateTime[8:10]
      if silent !=1: print iYear,iMonth,iDay,sHours,sMinutes,sSeconds,siteTime,SDate
   else:
      if silent !=1: print "Sync message expected from masterCS ",findKey
      #exit('Scan start not found')
      if silent !=1: print 'Scan start not found'
      return
   
   # This we need if observation starts before midnight and
   # the first subscan starts after midnight
   if SDate != SDateMES:
      SDateBM=SDate
      SDate=SDateMES
   else:
      SDateBM=SDate
   # Always need SDateBM

   ## Open output file (create or overwrite)
   # preliminary (old)
   # New file names not for 'continuum' yet 2005-06-11
   if silent !=1: print "The backend chosen is:",ChosenBackend
   if ChosenBackend == 'continuum':
      OutName="iram30m-continuum-"+InputFileStub+"-imb.fits"
      OutFITSfile = imbfits_NIKA.FitsFile("!"+OutName)
   if ChosenBackend == 'NIKA':
      OutName=outdir+"iram30m-NIKA-%s-"%(NIKAarray) +InputFileStub+"-imb.fits"
      OutFITSfile = imbfits_NIKA.FitsFile("!"+OutName)
   if ChosenBackend == 'NIKA1mm':
      OutName="iram30m-NIKA1mm-"+InputFileStub+"-imb.fits"
      OutFITSfile = imbfits_NIKA.FitsFile("!"+OutName)
   if ChosenBackend == 'NIKA2mm':
      OutName="iram30m-NIKA2mm-"+InputFileStub+"-imb.fits"
      OutFITSfile = imbfits_NIKA.FitsFile("!"+OutName)
   if ChosenBackend == '4mhz':
      OutName="iram30m-4mhz-"+InputFileStub+"-imb.fits"
      OutFITSfile = imbfits_NIKA.FitsFile("!"+OutName)
   if ChosenBackend == '100khz':
      OutName="iram30m-100khz-"+InputFileStub+"-imb.fits"
      OutFITSfile = imbfits_NIKA.FitsFile("!"+OutName)
   if ChosenBackend == 'vespa':
      OutName="iram30m-vespa-"+InputFileStub+"-imb.fits"
      OutFITSfile = imbfits_NIKA.FitsFile("!"+OutName)
   if ChosenBackend == 'wilma':
      OutName="iram30m-wilma-"+InputFileStub+"-imb.fits"
      OutFITSfile = imbfits_NIKA.FitsFile("!"+OutName)
   if ChosenBackend == '1mhz':
      OutName="iram30m-1mhz-"+InputFileStub+"-imb.fits"
      OutFITSfile = imbfits_NIKA.FitsFile("!"+OutName)
   if ChosenBackend == 'fts':
      OutName="iram30m-fts-"+InputFileStub+"-imb.fits"
      OutFITSfile = imbfits_NIKA.FitsFile("!"+OutName)


   fptr=OutFITSfile.create()
   # Overwrite mbfits.py
   pcfitsio.fits_update_key(fptr,'TELESCOP','IRAM 30m','Telescope Name')
   pcfitsio.fits_update_key(fptr,'ORIGIN','IRAM','Organisation or Institution')
   ## edit Version
   pcfitsio.fits_update_key(fptr,'IMBFTSVE',10.6,'IMBFITS version')
   pcfitsio.fits_update_key(fptr,'CREATOR','Python IRAM MBFITS Writer v3.0 (c) 2013 IRAM','Software ')
   ## edit Date
   pcfitsio.fits_write_comment(fptr,'This Version: 18-04-2017')

   ## Some FE (BE!) parameters, no, do BE later, later!
   backendName='CONT'
   for Receiver in obsBlock.receivers.receiverList:
      item="receiver."+Receiver+".receiverName"
      receiverName=str(obsBlock.getInfo(name=item)['value'])
      if silent !=1: print "used receiver ",receiverName
      if receiverName != 'Bolometer':
         if silent !=1: print 'Can not process: ',receiverName
###         exit(1)
         return
   ## Fix me
   pcfitsio.fits_update_key(fptr,'INSTRUME',ChosenBackend,'Backend')
   ## pcfitsio.fits_update_key(fptr,'INSTRUME',receiverName+' '+backendName,'Frontend Backend') #edit fix me
   ##pcfitsio.fits_update_key(fptr,'INSTRUME','MAMBO1 ABBA','Frontend Backend') #edit fix me

   item = 'sourceName'
   res1 = obsBlock.source.params[item].attrs['datatype']
   res2 = obsBlock.source.params[item].attrs['name']
   res3 = obsBlock.source.params[item].attrs['value']
   sourceName = str(res3)                              ## convert from unicode to ascii
   pcfitsio.fits_update_key(fptr,'OBJECT',sourceName,'Source Name')

   ## Special sources, the nine Planets and more
   ##  Fix me Planet Names
   LongObject=0.0;LatObject=0.0   #Just in case these do not get set
   if not sourceName in sourcePlanet and not sourceName[:4] in ['BODY'] :
      item = 'lambda'
      res3 = obsBlock.source.params[item].attrs['value']
      LongObject = string.atof(res3)*180./math.pi  # convert to float and scale to deg.

      pcfitsio.fits_update_key(fptr,'LONGOBJ',LongObject,'')
      item = 'beta'
      res3 = obsBlock.source.params[item].attrs['value']
      LatObject = string.atof(res3)*180./math.pi  # convert to float and scale to degrees
      pcfitsio.fits_update_key(fptr,'LATOBJ',LatObject,'')


   pcfitsio.fits_update_key(fptr,'TIMESYS','UTC','time system (TT,TAI,UTC ...)')
   pcfitsio.fits_update_key(fptr,'MJD-OBS',MJDOBS,'MJD at observation start')
   pcfitsio.fits_update_key(fptr,'DATE-OBS',DateTime,'')

   ##pcfitsio.fits_update_key(fptr,'SCANTYPE',header.obsp(),'Observing Procedure')
   imbfits_NIKA.ComClass.NFEBE=1
   Scan1=imbfits_NIKA.Table('IMBF-scan')

   # This adds a scan table. It is accessible for adding keywords and
   # table entries via object "scan1"
   Scan1.create(fptr)
   Scan1.Header.updateKeyword(fptr,'TELESCOP','','IRAM 30m')
   ## From antMD (J.P)
##   Scan1.Header.updateKeyword(fptr,'SITELONG','',-3.3989680555556) #3deg23'56.285" W
##   Scan1.Header.updateKeyword(fptr,'SITELAT','', 37.06838)         #37deg04'06.168 N
   ## New recommended values from J.P., used from 7th May 2009
   Scan1.Header.updateKeyword(fptr,'SITELONG','',-3.3987564198685)         # 3deg23'55.523" W
   Scan1.Header.updateKeyword(fptr,'SITELAT','', 37.0684132670517)         #37deg04'06.288" N
   Scan1.Header.updateKeyword(fptr,'SITEELEV','',2851.5)
   Scan1.Header.updateKeyword(fptr,'TELSIZE','',30.0)
   item='project'
   try:
      obsBlock.params[item].attrs['value']
   except:
      if silent !=1: print 'No ',item,' ID found'
      projectID='paKo'
   else:
      projectID=str(obsBlock.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'PROJID','',projectID)
   item='observer'
   try:
      obsBlock.params[item].attrs['value']
   except:
      if silent !=1: print 'No ',item,' ID found'
      Scan1.Header.updateKeyword(fptr,'OBSID','','paKo')
   else:
      Scan1.Header.updateKeyword(fptr,'OBSID','',str(obsBlock.params[item].attrs['value']))
   item='operator'
   try:
      obsBlock.params[item].attrs['value']
   except:
      if silent !=1: print 'No ',item,' ID found'
      Scan1.Header.updateKeyword(fptr,'OPERATOR','','paKo')
   else:
      Scan1.Header.updateKeyword(fptr,'OPERATOR','',str(obsBlock.params[item].attrs['value']))

   item= 'observingMode'
   try:
      observingMode=obsBlock.scans.list[0].params[item].attrs['value']
   except:
      if silent !=1: print 'No ',item,' found'
      observingMode='unknown'

   Scan1.Header.updateKeyword(fptr,'SCANNUM','',iScanNo)
   Scan1.Header.updateKeyword(fptr,'DATE-OBS','',DateTime)
   Scan1.Header.updateKeyword(fptr,'DATE','',DateWritten)
   Scan1.Header.updateKeyword(fptr,'MJD','',MJDOBS)
   #Scan1.Header.updateKeyword(fptr,'LST','',last) 
   Scan1.Header.updateKeyword(fptr,'N_OBS','',subscan_range)
   Scan1.Header.updateKeyword(fptr,'TIMESYS','','UTC')

   pcfitsio.fits_movabs_hdu(fptr,1) # Main header
   pcfitsio.fits_update_key(fptr,'PROJID',projectID,'project ID')
   Scan1.Header.updateKeyword(fptr,'OBJECT','',sourceName)
   #
   LongObject=0.0;LatObject=0.0   #Just in case these do not get set
   if not sourceName  in sourcePlanet and not sourceName[:4] in ['BODY']:
      item = 'lambda'
      res3 = obsBlock.source.params[item].attrs['value']
      LongObject=string.atof(res3)*180./math.pi
      Scan1.Header.updateKeyword(fptr,'LONGOBJ','',LongObject)
      item = 'beta'
      res3 = obsBlock.source.params[item].attrs['value']
      LatObject=string.atof(res3)*180./math.pi
      Scan1.Header.updateKeyword(fptr,'LATOBJ','',LatObject)
      item = 'equinoxYear'
      res3 = string.atof(obsBlock.source.params[item].attrs['value'])
      Scan1.Header.updateKeyword(fptr,'EQUINOX','',res3)

      ##Basis Systems: More systems? No default set.
      item = 'basisSystem'
      res3 = obsBlock.source.params[item].attrs['value']
      basisSystem = str(res3)            
      if basisSystem == 'galactic':
         Scan1.Header.updateKeyword(fptr,'CTYPE1','','GLON')
         Scan1.Header.updateKeyword(fptr,'CTYPE2','','GLAT')
      if basisSystem == 'equatorial':
         Scan1.Header.updateKeyword(fptr,'CTYPE1','','RA-SFL')
         Scan1.Header.updateKeyword(fptr,'CTYPE2','','DEC-SFL')
      if basisSystem == 'ecliptic':
         Scan1.Header.updateKeyword(fptr,'CTYPE1','','ELON')
         Scan1.Header.updateKeyword(fptr,'CTYPE2','','ELAT')
      if basisSystem == 'horizontal':
         Scan1.Header.updateKeyword(fptr,'CTYPE1','','ALON')
         Scan1.Header.updateKeyword(fptr,'CTYPE2','','ALAT')
   else:
      Scan1.Header.updateKeyword(fptr,'CTYPE1','','RA-SFL')
      Scan1.Header.updateKeyword(fptr,'CTYPE2','','DEC-SFL')
      Scan1.Header.updateKeyword(fptr,'EQUINOX','',sla.epj(iYear,iMonth,iDay,siteTime/86400.))
   ## pointing and focus offsets (corrections)
   item='pointingCorrectionP1'
   res3 = string.atof(obsBlock.source.pointingCorrections.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'P1COR','',res3)
   item='pointingCorrectionP2'
   res3 = string.atof(obsBlock.source.pointingCorrections.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'P2COR','',res3)
   item='pointingCorrectionP3'
   res3 = string.atof(obsBlock.source.pointingCorrections.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'P3COR','',res3)
   item='pointingCorrectionP4'
   res3 = string.atof(obsBlock.source.pointingCorrections.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'P4COR','',res3)
   item='pointingCorrectionP5'
   res3 = string.atof(obsBlock.source.pointingCorrections.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'P5COR','',res3)
   item='pointingCorrectionP7'
   res3 = string.atof(obsBlock.source.pointingCorrections.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'P7COR','',res3)
   item='pointingCorrectionP8'
   res3 = string.atof(obsBlock.source.pointingCorrections.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'P8COR','',res3)
   item='pointingCorrectionP9'
   res3 = string.atof(obsBlock.source.pointingCorrections.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'P9COR','',res3)
   item='pointingCorrectionRxVertical'
   res3 = string.atof(obsBlock.source.pointingCorrections.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'RXVERTCO','',res3)
   item='pointingCorrectionRxHorizontal'
   res3 = string.atof(obsBlock.source.pointingCorrections.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'RXHORICO','',res3)
   # subreflector
   item='focusCorrectionX'
   res3 = string.atof(obsBlock.source.focusCorrections.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'FOCUSX','',res3)
   item='focusCorrectionY'
   res3 = string.atof(obsBlock.source.focusCorrections.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'FOCUSY','',res3)
   item='focusCorrectionZ'
   res3 = string.atof(obsBlock.source.focusCorrections.params[item].attrs['value'])
   Scan1.Header.updateKeyword(fptr,'FOCUSZ','',res3)

   ##Switching parameters
   item='mode'
   res3=str(obsBlock.switcher.params[item].attrs['value'])
   if res3 in ['totalPower']:
      item='nPhases'
      Nphases=string.atoi(obsBlock.switcher.params[item].attrs['value'])
      wobblerUsed=0; wobblerThrow=0.0
      item='timePerPhase'
      timePerPhase=string.atof(obsBlock.switcher.params[item].attrs['value'])
   elif res3 in ['beamSwitching']:
      item='nPhases'
      Nphases=string.atoi(obsBlock.switcher.params[item].attrs['value'])
      timePerPhase=0.024 # Approximately from backend data 
   elif res3 in ['wobblerSwitching']:
      Nphases=2
      wobblerUsed=1
      wobblerDir=0.5  # Fix me, always 0.5?
      item='wobblerThrow'
      wobblerThrow=string.atof(obsBlock.switcher.params[item].attrs['value'])
      item='timePerPhase'
      timePerPhase=string.atof(obsBlock.switcher.params[item].attrs['value'])
#      Scan1.Header.updateKeyword(fptr,'WOBUSED','',wobblerUsed)
      Scan1.Header.updateKeyword(fptr,'WOBTHROW','',wobblerThrow*180./math.pi)
      Scan1.Header.updateKeyword(fptr,'WOBCYCLE','',Nphases*timePerPhase)
      Scan1.Header.updateKeyword(fptr,'WOBMODE','','SQUARE')
      Scan1.Header.updateKeyword(fptr,'WOBDIR','',wobblerDir)
   elif res3 in ['frequencySwitching']:
      item='nPhases'
      Nphases=string.atoi(obsBlock.switcher.params[item].attrs['value'])
      item='timePerPhase'
      timePerPhase=string.atof(obsBlock.switcher.params[item].attrs['value'])
   else:
      if silent !=1: print 'Unknown switching mode ',res3
      Nphases=1; wobblerUsed=0; wobblerThrow=0.0
   switchMode=res3
   # 
   if ChosenBackend == 'continuum':
      backendName='Continuum'                       # Pako names 
      DistributionDic={'A100':1,'A230':2,'B100':3,'B230':4,'C150':1,'C270':2,'D150':3,'D270':4,'HERA1vertical':40,'HERA2horizontal':56} #Fix me
      DistributionDic={'E090':1,'A230':2,'B100':3,'B230':4,'C150':1,'C270':2,'D150':3,'D270':4,'HERA1vertical':40,'HERA2horizontal':56} #Fix me
   if ChosenBackend == '4mhz':
      backendName='4MHz'                            # Pako names
      DistributionDic={'A100':1,'A230':2,'B100':3,'B230':4,'C150':1,'C270':2,'D150':3,'D270':4,'HERA1vertical':1,'HERA2horizontal':1} #Fix me
   if ChosenBackend == '100khz':
      backendName='100kHz'                            # Pako names
      DistributionDic={'A100':1,'A230':2,'B100':3,'B230':4,'C150':1,'C270':2,'D150':3,'D270':4} #Fix me
   if ChosenBackend == 'vespa':
      backendName='VESPA'                            # Pako names
      DistributionDic={'A100':1,'A230':2,'B100':3,'B230':4,'C150':1,'C270':2,'D150':3,'D270':4} #Fix me
   if ChosenBackend == 'wilma':
      backendName='WILMA'                            # Pako names
      DistributionDic={'A100':1,'A230':2,'B100':3,'B230':4,'C150':1,'C270':2,'D150':3,'D270':4} #Fix meif ChosenBackend == '1mhz':
   if ChosenBackend == '1mhz':
      backendName='1MHz'                            # Pako names
      DistributionDic={'A100':1,'A230':2,'B100':3,'B230':4,'C150':1,'C270':2,'D150':3,'D270':4} #Fix me
   if ChosenBackend == 'fts':
      backendName='FTS'                            # Pako name, probable wrong
      DistributionDic={'A100':1,'A230':2,'B100':3,'B230':4,'C150':1,'C270':2,'D150':3,'D270':4} #Fix me
   if ChosenBackend == 'NIKA1mm':
      backendName='Continuum' # Do not know the PaKo Name yet NIKA1mm
      restFrequency=240.0
      pointingChannel=1
      recCntrl=1
      timePerPhase=0.045      # FIX ME is this a constant
   if ChosenBackend == 'NIKA2mm':
      backendName='Continuum' # Do not know the PaKo Name yet NIKA2mm
      restFrequency=150.0
      pointingChannel=1
      recCntrl=1
      timePerPhase=0.045      # FIX ME is this a constant
   if ChosenBackend == 'NIKA':
      backendName='Continuum' # Do not know the PaKo Name yet NIKA2mm
      restFrequency=150.0
      pointingChannel=1
      recCntrl=1
      timePerPhase=0.042      # FIX ME!! This value from RZ (18.04.2016)
   BackendParts=[]
   #
   ## State befor/after for weather station and hot-load temperature
   #
   stateAfter = anydbm.open(DataRootDir + InDir + '/log/iram30m-stateafter-' + InputFileStub +'.dbm','ru')
   #
   ## Fix me EOP
   findKey="lib.EOP.value.dUT1"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
      (ut1utc,polax,polay)=EOP.get()
   else:
      ut1utc=string.atof(stateAfter[findKey])
      polax=string.atof(stateAfter["lib.EOP.value.dX"])
      polay=string.atof(stateAfter["lib.EOP.value.dY"])
      if silent !=1: print "dUTC, dX, dY= ",ut1utc,polax,polay
#   (ut1utc,polax,polay)=EOP.get()
## Fix Me, always out-of-date
#   taiutc=35.0    # From I E R S  BULLETIN - A 11 April 2013 Vol. XXVI No. 015 
   taiutc=36.0    # Beginning 1 July 2015 From I E R S  BULLETIN-A 09 July 2015 Vol. XXXVIII No. 028 
   etutc=taiutc+32.184
   Scan1.Header.updateKeyword(fptr,'UT1UTC','',ut1utc)
   Scan1.Header.updateKeyword(fptr,'ETUTC','',etutc)
   Scan1.Header.updateKeyword(fptr,'TAIUTC','',taiutc)
   Scan1.Header.updateKeyword(fptr,'POLEX','',polax)
   Scan1.Header.updateKeyword(fptr,'POLEY','',polay)
   # Local Siderial Time
   iMJDOBS=sla.mjd(iYear,iMonth,iDay)
   doUTC1=(MJDOBS-iMJDOBS)*24.0*3600. + ut1utc
   doLST=sla.ut1st(doUTC1,iYear,iMonth,iDay,-3.3989680555556)
   Scan1.Header.updateKeyword(fptr,'LST','',doLST)
   
   ## In case source offsets are defined, used
   try:
      NoOffsets=len(obsBlock.source.offsets.rows)
   except:
      if silent !=1: print 'No source offsets'
   else:
      if silent !=1: print 'Yes we have Offsets ',NoOffsets
      for iOff in range(NoOffsets):
         Xoffset=string.atof(obsBlock.source.offsets.rows[iOff][0])
         Yoffset=string.atof(obsBlock.source.offsets.rows[iOff][1])
         SysOff=str(obsBlock.source.offsets.rows[iOff][2])
         if silent !=1: print Xoffset,Yoffset,SysOff,' from PaKo'
         if SysOff != "Nasmyth": #Leave out the Nasmyth offsets
            Scan1.BinTable.addTableEntry(fptr,'XOFFSET',[Xoffset])
            Scan1.BinTable.subsTableEntry(fptr,'YOFFSET',[Yoffset])
            Scan1.BinTable.subsTableEntry_str(fptr,'SYSOFF' ,[SysOff])
   #
   ## Now write Nasmyth offsets, rewrite, using split
   findKey="antCS.source.offsetNasmyth.value"
#   print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=stateAfter[findKey]
      Values1=Value.split()
#      print Values1
      Xoffset=string.atof(Values1[1])
      Yoffset=string.atof(Values1[2])
      SysOff="Nasmyth"
      if silent !=1: print Xoffset,Yoffset,SysOff,' from Walter'
      Scan1.BinTable.addTableEntry(fptr,'XOFFSET',[Xoffset])
      Scan1.BinTable.subsTableEntry(fptr,'YOFFSET',[Yoffset])
      Scan1.BinTable.subsTableEntry_str(fptr,'SYSOFF' ,[SysOff])

   #
   ## State befor/after for Pointing Model
   findKey="antCS.pointing.model.P1"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])*asecToRad
      Scan1.Header.updateKeyword(fptr,'P1','',Value)
   findKey="antCS.pointing.model.P2"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])*asecToRad
      Scan1.Header.updateKeyword(fptr,'P2','',Value)
   findKey="antCS.pointing.model.P3"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])*asecToRad
      Scan1.Header.updateKeyword(fptr,'P3','',Value)
   findKey="antCS.pointing.model.P4"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])*asecToRad
      Scan1.Header.updateKeyword(fptr,'P4','',Value)
   findKey="antCS.pointing.model.P5"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])*asecToRad
      Scan1.Header.updateKeyword(fptr,'P5','',Value)
   findKey="antCS.pointing.model.P7"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])*asecToRad
      Scan1.Header.updateKeyword(fptr,'P7','',Value)
   findKey="antCS.pointing.model.P8"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])*asecToRad
      Scan1.Header.updateKeyword(fptr,'P8','',Value)
   findKey="antCS.pointing.model.P9"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])*asecToRad
      Scan1.Header.updateKeyword(fptr,'P9','',Value)
   findKey="antCS.pointing.model.RX_HOR"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])*asecToRad
      Scan1.Header.updateKeyword(fptr,'RXHORI','',Value)
   findKey="antCS.pointing.model.RX_VERT"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])*asecToRad
      Scan1.Header.updateKeyword(fptr,'RXVERT','',Value)
   findKey="antCS.pointing.model.THIRD_REFRACT"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])
      Scan1.Header.updateKeyword(fptr,'THIRD_RE','',Value)
   findKey="antCS.pointing.model.ZERO_POL"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])
      Scan1.Header.updateKeyword(fptr,'ZERO_POL','',Value)
   findKey="antCS.pointing.model.PHI_POL"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])
      Scan1.Header.updateKeyword(fptr,'PHI_POL','',Value)
   findKey="antCS.pointing.model.EPSILON_POL"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])
      Scan1.Header.updateKeyword(fptr,'EPS_POL','',Value)
   findKey="antCS.pointing.model.COL_SINUS"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])
      Scan1.Header.updateKeyword(fptr,'COL_SIN','',Value)
   findKey="antCS.pointing.model.COL_COSINUS"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])
      Scan1.Header.updateKeyword(fptr,'COL_COS','',Value)
   findKey="antCS.pointing.model.timeStamp"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if silent !=1: print stateAfter[findKey]
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'DATE-POI','',stateAfter[findKey])

   #
   ## P4, P5 corrections from inclinometers
   findKey="antCS.inclinometer.p4"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])*asecToRad
      Scan1.Header.updateKeyword(fptr,'P4CORINC','',Value)
   findKey="antCS.inclinometer.p5"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Value=string.atof(stateAfter[findKey])*asecToRad
      Scan1.Header.updateKeyword(fptr,'P5CORINC','',Value)
   findKey="antCS.inclinometer.timeStamp"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if silent !=1: print stateAfter[findKey]
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'DATE-INC','',stateAfter[findKey])
   #
   ## StateAfter for slow rate from antMD
   
   findKey="antMD.trace.slowRate"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
      slowRate=1
   else:
      slowRate=string.atoi(stateAfter[findKey])
      if silent !=1: print "antMD slow loops per sec ",slowRate
   
   
   #
   ## State befor/after for weather station and hot-load temperature
   # Check state of weather station 'automatic' or 'manual'
   
   findKey="weatherStation.config.mode"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
      WSmode = 'automatic'              # Needs to be set, otherwise this script exits
   else:
      WSmode=stateAfter[findKey]
      if silent !=1: print "Weather-station mode ",WSmode

   if WSmode == 'manual':
      findKey="weatherStation.manual.data.temperature"
   else:
      findKey="weatherStation.data.temperature"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      #Scan1.Header.updateKeyword(fptr,'TEMPERAT','',stateAfter[findKey])
      Scan1.Header.updateKeyword(fptr,'TAMBIENT','',stateAfter[findKey])

   if WSmode == 'manual':
      findKey="weatherStation.manual.data.pressure"
   else:
      findKey="weatherStation.data.pressure"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'PRESSURE','',stateAfter[findKey])

   if WSmode == 'manual':
      findKey="weatherStation.manual.data.humidity"
   else:
      findKey="weatherStation.data.humidity"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   #Only when found==true: print stateAfter[findKey]
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'HUMIDITY','',stateAfter[findKey])

   findKey="weatherStation.data.windDir"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if silent !=1: print stateAfter[findKey]
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'WINDDIR','',stateAfter[findKey])

   findKey="weatherStation.data.windVel"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if silent !=1: print stateAfter[findKey]
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'WINDVEL','',stateAfter[findKey])

   findKey="weatherStation.data.windVelMax"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if silent !=1: print stateAfter[findKey]
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'WINDVELM','',stateAfter[findKey])

   if WSmode == 'manual':
      findKey="weatherStation.manual.data.timeStamp"
   else:
      findKey="weatherStation.data.timeStamp"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if silent !=1: print stateAfter[findKey]
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'DATE-WEA','',stateAfter[findKey])

   findKey="weather.tau.tau"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if silent !=1: print stateAfter[findKey]
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'TIPTAUZ','',stateAfter[findKey])

   findKey="weather.tau.sigma"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if silent !=1: print stateAfter[findKey]
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'TIPTAUE','',stateAfter[findKey])

   findKey="weather.tau.fit"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if silent !=1: print stateAfter[findKey]
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'TIPTAUC','',stateAfter[findKey])

   findKey="weather.tau.timeStamp"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if silent !=1: print stateAfter[findKey]
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'DATE-TIP','',stateAfter[findKey])

   findKey="rxCS.ambientLoad.timeStamp"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if silent !=1: print stateAfter[findKey]
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'DATE-HOT','',stateAfter[findKey])

   findKey="rxCS.ambientLoad.temperature"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      Scan1.Header.updateKeyword(fptr,'THOT','',string.atof(stateAfter[findKey])+273.15)


   findKey="rxCS.hera.temperature.tCold"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
      heraTcold=0.0
   else:
      heraTcold=string.atof(stateAfter[findKey])
      if silent !=1: print 'heraTcold found ',heraTcold
      heraTcold=0.8*heraTcold
      # Fix me: Need be confirmed. Changed from 0.85 to 0.8 on 2006-02-10

   findKey="rxCS.hera.temperature.tHot"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
      heraThot=0.0
   else:
      heraThot=string.atof(stateAfter[findKey])
      if silent !=1: print 'heraThot found ',heraThot

   findKey="rxCS.hera.temperature.timeStamp"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if silent !=1: print stateAfter[findKey]
   if not found:
      if silent !=1: print "Key not found: ",findKey
   else:
      heraThotDate=stateAfter[findKey]
   #
   # At present (2006.04.18) we have only one value for the doppler
   # correction, should be one per subscan FIX ME
   findKey="rxCS.dopplerCorrection.dopplerCorrection"
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
      dopplerCorrection=1.0
   else:
      dopplerCorrection=string.atof(stateAfter[findKey])
      if silent !=1: print 'Doppler correction found ',dopplerCorrection

   findKey="rxCS.dopplerCorrection.vel"
   ## This is the sum of e.g. vlsr + sourceVelocity
   if silent !=1: print findKey
   found = stateAfter.has_key(findKey)
   if not found:
      if silent !=1: print "Key not found: ",findKey
      dopplerVlsr=0.0
   else:
      valueDopplerVelocity=stateAfter[findKey]
      if valueDopplerVelocity != "":
         dopplerVsum=string.atof(valueDopplerVelocity)
         findKey="rxCS.dopplerCorrection.sourceVelocity"
         sourceVelocity=string.atof(stateAfter[findKey])/1000.
         dopplerVlsr=dopplerVsum-sourceVelocity
         if silent !=1: print "doppler Vsum, Vsource, Vlsr :",dopplerVsum,sourceVelocity,dopplerVlsr
      else:
         if silent !=1: print "Empty string for doppler velocity"
         dopplerVlsr=0.0
      if silent !=1: print 'Vlsr observer ',dopplerVlsr

   Scan1.Header.updateKeyword(fptr,'SWTCHMOD','',switchMode)
   Scan1.Header.updateKeyword(fptr,'NOSWITCH','',Nphases)
   Scan1.Header.updateKeyword(fptr,'PHASETIM','',timePerPhase)
   Scan1.Header.updateKeyword(fptr,'RECON','',pointingChannel)
   Scan1.Header.updateKeyword(fptr,'RECCNTRL','',recCntrl)
   #   
   ## Now the Frontend table
   #
   stateAfter.close()
   Febepar1=imbfits_NIKA.Table('IMBF-frontend',Scan1)
   Febepar1.create(fptr)
# header
   Febepar1.Header.updateKeyword(fptr,'SCANNUM','',iScanNo)
   Febepar1.Header.updateKeyword(fptr,'DATE-OBS','',DateTime)
# table
   if NIKAarray==1:
      array=1; recname="1mm H"; restFrequency=260.0
      Febepar1.BinTable.addTableEntry(fptr,'ARRAY',[array])
      Febepar1.BinTable.subsTableEntry_str(fptr,'RECNAME',[recname])
      Febepar1.BinTable.subsTableEntry(fptr,'RESTFREQ',[restFrequency])
   elif NIKAarray==2:
      array=2; recname="2mm "; restFrequency=160.0
      Febepar1.BinTable.addTableEntry(fptr,'ARRAY',[array])
      Febepar1.BinTable.subsTableEntry_str(fptr,'RECNAME',[recname])
      Febepar1.BinTable.subsTableEntry(fptr,'RESTFREQ',[restFrequency])
   elif NIKAarray==3:
      array=3; recname="1mm V"; restFrequency=260.0
      Febepar1.BinTable.addTableEntry(fptr,'ARRAY',[array])
      Febepar1.BinTable.subsTableEntry_str(fptr,'RECNAME',[recname])
      Febepar1.BinTable.subsTableEntry(fptr,'RESTFREQ',[restFrequency])
   else:
      if silent !=1: print "No NIKA array no. found: ",NIKAarray
   Scan1.Header.updateKeyword(fptr,'RECON','',pointingChannel)
   Scan1.Header.updateKeyword(fptr,'RECCNTRL','',recCntrl)
   #   
   ## Now the Febepar2 table backend configuration
   #
   ##imbfits_NIKA.ComClass.NCH=150     # FIX ME
   #if ChosenBackend == 'NIKA1mm':NIKAChannels=213
   #if ChosenBackend == 'NIKA2mm':NIKAChannels=168
   # from 20131114
   #if ChosenBackend == 'NIKA1mm':NIKAChannels=201
   #if ChosenBackend == 'NIKA2mm':NIKAChannels=130
   # from 20140121
   #if ChosenBackend == 'NIKA1mm':NIKAChannels=236
   #if ChosenBackend == 'NIKA2mm':NIKAChannels=168
   # from 20140218
   #if ChosenBackend == 'NIKA1mm':NIKAChannels=235
   #if ChosenBackend == 'NIKA2mm':NIKAChannels=168
   # from 20140424
   if ChosenBackend == 'NIKA1mm':NIKAChannels=236
   if ChosenBackend == 'NIKA2mm':NIKAChannels=168
   #
   # Done further below
   #imbfits_NIKA.ComClass.NCH=NIKAChannels
   #Febepar2=imbfits_NIKA.Table('IMBF-backend',Scan1)
   #Febepar2.create(fptr)
   #Febepar2.Header.updateKeyword(fptr,'SCANNUM','',iScanNo)
   #Febepar2.Header.updateKeyword(fptr,'DATE-OBS','',DateTime)
   #
   ## No write the backend table
   # Check Nchannel, it is messed up
   Nchannel=0
   ## SET for all backends here, reset for specific backends below (if needed)
   ##Tstamped=1.0
   ## SET from 3.02.2014 onwards, only NIKA backend done in this script
   Tstamped=0.5
   phaseOne='ON'
   if ChosenBackend == 'NIKA1mm':
#      NoofBEparts=len(obsBlock.backends.backends[backendName].parts)
      NoofBEparts=8  # For the streams !
      NoofBEpartsOut=7 # For the IMBFits
      #NIKAChannels=213 # FIX, read from primary header of NIKA data streams
      # From 201311 on
      #NIKAChannels=201 # FIX, read from primary header of NIKA data streams
      # From 20140121 on
      NIKAChannels=236 # FIX, read from primary header of NIKA data streams
      # From 18 Feb. 2014
      NIKAChannels=235 # FIX, read from primary header of NIKA data streams
      usedchan=NIKAChannels
      numBEparts=0
      bePixels=1
      imbfits_NIKA.ComClass.NCH=usedchan
      Febepar2.BinTable.addTableEntry_str(fptr,'RECNAME',['NIKA1mm'])
      # K=Kid, B=BadKid, O=OffReso, U=Undef, 1st line=1mm 
#2010      feedType='KOKKKOKKKKKOKKKKOKKKKOKOKKKKOKKOKKKKBBOKOKKKKKKOKOKKKKBOKKKKOKKKOBKKKOKOKOBKBBOKOKBKOKKKOKKOKOUUUUUUUUUUUUUUUUUU'
#20-10-2011
#      feedType='KKKKKKKKKKKKKKKKKKKKKKKBKKKKKKKKKKKKKKKBKBKBKKKKKKKBKKKKBKKBBKKKKKKKKKBKKKKKKKKKKKKKKKKKKKKBKKKBBBKKKBKKKKKBKKKKKKBKUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU'
#v9
      feedType='KKKKKKKKKKKKKKKKKKKKKKKBKKKKKKKKKKKKKKKBKBKBKKKKKKKBKKKKBKKBBKKKKKKKKKBKKKKKKKKKKKKKKKKKKKKBKKKBBBKKKBKKKKKBKKKKKKBKUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU'
      ##Febepar2.BinTable.subsTableEntry_str(fptr,'FEEDTYPE',[feedType])
      useFeed=range(1,usedchan+1)
      Febepar2.BinTable.subsTableEntry_dbl(fptr,'USEFEED',useFeed)

   if ChosenBackend == 'NIKA2mm':
      NoofBEparts=8
      NoofBEpartsOut=7
      #NIKAChannels=168 # Fix Me read from data
      # From 20131115
      #NIKAChannels=130 # Fix Me read from data
      # From 20140121
      NIKAChannels=168 # Fix Me read from data
      usedchan=NIKAChannels
      numBEparts=0
      bePixels=1
      imbfits_NIKA.ComClass.NCH=usedchan
      Febepar2.BinTable.addTableEntry_str(fptr,'RECNAME',['NIKA2mm'])
      # K=Kid, B=BadKid, O=OffReso, U=Undef, 2nd line=2mm
#2010      feedType='KKKKKKKBBOKKKKOKKKKKKKKKKOKKKKKKKKKKKOKKKKKKOKKKKKKKKKKKOKKKKKKKKKKKKKOBKKKKKKOKKKKKOKKKKKBKKKOKKKKKKKKKKKKKKKKK'
#20-10-2011
#     feedType='KOUKKKKKKKKOBKKKKBKKBKKOKKKBKKBKBOKKKKBBKKBBOKKKKKBKKOKKKKBBKKKBOKKKKKKKKKKKOKKKKKBBBOBBKKKKKKKKKKBOKKKKBKBKBKKKKBKBUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU'
#v9
      feedType='KOUKKKKKKKKOBKKKKBKKBKKOKKKBKKBKBOKKKKBBKKBBOKKKKKUKKOKKKKBBKKKBOKKKKKKKKKKKOKKKKKBBBOBBKKKKKKKKKKBOKKKKBKUKBKKKKBKBUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU'
      ##Febepar2.BinTable.subsTableEntry_str(fptr,'FEEDTYPE',[feedType])
      useFeed=range(1,usedchan+1)
      Febepar2.BinTable.subsTableEntry_dbl(fptr,'USEFEED',useFeed)

   if ChosenBackend == 'NIKA':
#      if len(sys.argv)>4:
#         if silent !=1: print '>>',sys.argv[4],'<<'
#         rawFile=sys.argv[4]
#      else:
#         rawFileStub="X_%s_%s_%s_AA_%04.4d" % (CiY,CiM,CiD,iScanNo)
#         if silent !=1: print rawFileStub 
#         largeList=glob.glob(DataRootDir+"/datastreams/NIKA/"+rawFileStub)
#         largeList=largeList+glob.glob(DataRootDir+SDate+"/datastreams/NIKA/"+rawFileStub)
#         rawFile=largeList[0]
#          if silent !=1: print largeList
      
#      import sla
#      if silent !=1: print "SLALib wrapper from ",sla.__file__
      silent=1
#      nika2run2=1 desactivated
      nika2run2=0
      
#      list_data='sample scan subscan scan_st paral MJD RF_didq I Q dI dQ F_tone k_flag'
#      list_data='sample scan subscan A_t_utc MJD RF_didq I Q dI dQ F_tone k_flag' # seems  A_t_utc gives an error
#      list_data='sample scan subscan MJD RF_didq I Q dI dQ F_tone k_flag'
#      list_data='sample scan subscan A_t_utc MJD I Q dI dQ F_tone k_flag RF_didq'
#      list_data='subscan scan El retard 0 ofs_Az ofs_El Az paral scan_st MJD LST sample I Q dI dQ RF_didq F_tone DF_tone A_masq B_masq k_flag c_position c_synchro A_t_utc B_t_utc antxoffset antyoffset anttrackaz anttrackel'
      list_data='sample subscan scan El retard 0 ofs_Az ofs_El Az paral scan_st MJD LST I Q dI dQ RF_didq F_tone DF_tone A_masq B_masq k_flag c_position c_synchro A_t_utc B_t_utc C_t_utc D_t_utc E_t_utc F_t_utc G_t_utc H_t_utc I_t_utc J_t_utc K_t_utc L_t_utc M_t_utc N_t_utc O_t_utc P_t_utc Q_t_utc R_t_utc S_t_utc T_t_utc U_t_utc A_pps B_pps C_pps D_pps E_pps F_pps G_pps H_pps I_pps J_pps K_pps L_pps M_pps N_pps O_pps P_pps Q_pps R_pps S_pps T_pps U_pps A_o_pps B_o_pps C_o_pps D_o_pps E_o_pps F_o_pps G_o_pps H_o_pps I_o_pps J_o_pps K_o_pps L_o_pps M_o_pps N_o_pps O_o_pps P_o_pps Q_o_pps R_o_pps S_o_pps T_o_pps U_o_pps'
#      rawdata= read_nika_data(rawFile,silent,list_data,nika2run2)
      rawdata= read_nika_data(rawFile,silent,det2read='KOD',list_data=list_data,nika2run2=nika2run2)

      
# Header info rea (Params) and data for later
#      NoofBEparts=len(obsBlock.backends.backends[backendName].parts)
      NoofBEparts=8  # For the streams !
      NoofBEpartsOut=8 # For the IMBFits
#      posA=nup.where(nup.array(rawdata.kidpar['pname']) =='array')
#      dectarr = nup.array(rawdata.kidpar['pvalue'][posA[0][0]])
      dectarr = rawdata.kidpar['array']
      dect1array =  rawdata.kidpar['num'][(nup.where(dectarr == NIKAarray))[0]]

      if silent !=1: print nup.size(dect1array)
      ##if silent !=1: print "Lisxbte :",dect1array[0].tolist()
#      channelL=dect1array[0].tolist()
      channelL=dect1array.tolist()
      NIKAChannels=nup.size(channelL)
      if silent !=1: print "NIKAChannels ",NIKAChannels
      ##NIKAChannels=rawdata.data_detector.shape[1]
      usedchan=NIKAChannels
      numBEparts=8 # FIX this ! Same as NoofBEpartsOut ?
      bePixels=1
      imbfits_NIKA.ComClass.NCH=usedchan
      Febepar2=imbfits_NIKA.Table('IMBF-backend',Scan1)
      Febepar2.create(fptr)
      Febepar2.Header.updateKeyword(fptr,'SCANNUM','',iScanNo)
      Febepar2.Header.updateKeyword(fptr,'DATE-OBS','',DateTime)
      Febepar2.Header.updateKeyword(fptr,'NVPPHASE','',NoofBEpartsOut)

#      name_kidpar_var = rawdata.kidpar['pname']
      name_kidpar_var = rawdata.kidpar.keys()
      nkidparvar = len(name_kidpar_var)
##      for jjj in range(usedchan):
##      pdb.set_trace()
      for jjj in channelL:
##         for iii in range(nkidparvar):
         for kidvar in name_kidpar_var:
            NAME_VAR = kidvar
#            NAME_VAR= name_kidpar_var[iii]
            pos = (np.where(jjj == rawdata.kidpar['num']))[0][0]
            DATA_VAR = (rawdata.kidpar[kidvar])[pos]
#            DATA_VAR= rawdata.kidpar['pvalue'][iii][jjj]
            if NAME_VAR == 'name':
               Febepar2.BinTable.addTableEntry_str(fptr,NAME_VAR,[DATA_VAR])
            else:
#               if silent !=1: print NAME_VAR, DATA_VAR
               Febepar2.BinTable.subsTableEntry(fptr,NAME_VAR,[DATA_VAR])
               
   if silent !=1: print 'No. of data per pixel expected for ',ChosenBackend,' are ',numBEparts
   imbfits_NIKA.ComClass.NFEBE= numBEparts     #Simply the no. data per pixel on output
   Scan1.Header.updateKeyword(fptr,'NFEBE','',numBEparts)
## These parameters are not very useful! 
   Febepar1.Header.updateKeyword(fptr,'NUSEFEED','',usedchan)
   Febepar1.Header.updateKeyword(fptr,'FEBEFEED','',usedchan)
   Febepar1.Header.updateKeyword(fptr,'NVPPHASE','',numBEparts)
   Febepar2.Header.updateKeyword(fptr,'NUSEFEED','',usedchan)
   Febepar2.Header.updateKeyword(fptr,'FEBEFEED','',usedchan)
   Febepar2.Header.updateKeyword(fptr,'NVPPHASE','',numBEparts)
   
   ## At present we can have only 1 Value for the Secondary rotation angle per scan
   #item = observingBlock.antenna.rotationAngle
   try:
      FeedAngl = obsBlock.antenna.resources['secondary'].values['rotationAngle']
#      FeedAngl = obsBlock.resources['antenna'].resources['secondary'].values['rotationAngle']
   #   FeedAngl = scanSpecParser.getNormValue(observingBlock.allParams[key].attrs)
   except:
      if silent !=1: print "Feed Angle not set, assume it is zero"
      FeedAngl=0.0
   else:
   #   FeedAngl = FeedAngl*180./math.pi is already in radian
      if silent !=1: print "Feed Angle found :",FeedAngl

   #if silent !=1: print 'debug: subscanToDo,subscan_range',subscanToDo,subscan_range
   if subscanToDo<1 or subscanToDo>=subscan_range :
      SubScansInLoop=subscan_range+1
   else:
      SubScansInLoop=subscanToDo+1

   ### Start the big loop data + traces ###########################################################################
      
   # The following only once per scan
   oncePerScan=1;VespaConfigWrite=1;subscansDone=0;WilmaConfigWrite=1;FtsConfigWrite=1
   passedMidnight=False
   writeDataStreams=0
   NIKAConfigWrite=1;neleFast=0;neleSlow=0
   for isub in range(1,SubScansInLoop):                # This is not 'where a float is required'
      if silent !=1: print "Starting with Subscan ",isub," from ",SubScansInLoop
      oncePerSubscan=1
      midnight=False
      midnightJP=False
      scanIdSubscan=scanId+".%s" % isub
      "masterCS:%s.%s:scanStarted" % (Date,iScanNo)
      # Parameters per subscan/segment
      parameter="type"
      subs_type = obsBlock.scans.list[0].subscans.list[isub-1].params[parameter].attrs["value"] #Fix me: put in table
      #Specific parameters

      if subs_type in ["calPaddle","calCold","calAmbient","calSky","calGrid"]:
         parameter="timePerCalibration"
         subs_timePerSubscan = obsBlock.scans.list[0].subscans.list[isub-1].params[parameter].attrs["value"]
         subs_systemOffset='' ## So this variable exists

      if subs_type in ["airmass","calPaddle","onFocus","track","calSky","tune"]:
         parameter="systemOffset"
         subs_systemOffset = obsBlock.scans.list[0].subscans.list[isub-1].params[parameter].attrs["value"]
         parameter="xOffset"
         subs_xOffset = obsBlock.scans.list[0].subscans.list[isub-1].params[parameter].attrs["value"]
         parameter="yOffset"
         subs_yOffset = obsBlock.scans.list[0].subscans.list[isub-1].params[parameter].attrs["value"]

      if subs_type in ["airmass","track","tune"] :
         parameter="timePerSubscan"
         subs_timePerSubscan = obsBlock.scans.list[0].subscans.list[isub-1].params[parameter].attrs["value"]

      if subs_type == "onFocus" :
         parameter="timePerSubscan"
         subs_timePerSubscan = obsBlock.scans.list[0].subscans.list[isub-1].params[parameter].attrs["value"]
         parameter="focusTranslation"
         subs_focusTranslatio =  obsBlock.scans.list[0].subscans.list[isub-1].params[parameter].attrs["value"]
         parameter="focusOffset"
         subs_focusOffset = obsBlock.scans.list[0].subscans.list[isub-1].params[parameter].attrs["value"]

      if subs_type in ["OTF","otf","onTheFly"]:
         parameter="systemOffset"
         subs_systemOffset = obsBlock.scans.list[0].subscans.list[isub-1].params[parameter].attrs["value"] 
         parameter="type"
         seg_type=obsBlock.scans.list[0].subscans.list[isub-1].segments.list[0].params[parameter].attrs["value"]
         if seg_type == "linear":
            parameter="xStart"      
            seg_xStart=string.atof(obsBlock.scans.list[0].subscans.list[isub-1].segments.list[0].params[parameter].attrs["value"])
            parameter="xEnd"
            seg_xEnd=string.atof(obsBlock.scans.list[0].subscans.list[isub-1].segments.list[0].params[parameter].attrs["value"])
            parameter="yStart"
            seg_yStart=string.atof(obsBlock.scans.list[0].subscans.list[isub-1].segments.list[0].params[parameter].attrs["value"])
            parameter="yEnd"
            seg_yEnd=string.atof(obsBlock.scans.list[0].subscans.list[isub-1].segments.list[0].params[parameter].attrs["value"])
            parameter="speedStart"
            seg_speedStart=string.atof(obsBlock.scans.list[0].subscans.list[isub-1].segments.list[0].params[parameter].attrs["value"])
            parameter="speedEnd"
            seg_speedEnd=string.atof(obsBlock.scans.list[0].subscans.list[isub-1].segments.list[0].params[parameter].attrs["value"])
            subs_timePerSubscan=math.sqrt((seg_xEnd-seg_xStart)**2 + (seg_yEnd-seg_yStart)**2)/((seg_speedStart+seg_speedEnd)/2.) 
            if silent !=1: print "We have here segment 1",seg_xStart,seg_xEnd,seg_yStart,seg_yEnd,seg_speedStart,seg_speedEnd
            if silent !=1: print "timePerSubscan",subs_timePerSubscan
         if seg_type == "lissajous":
            parameter="timePerSubscan"
            subs_timePerSubscan=string.atof(obsBlock.scans.list[0].subscans.list[isub-1].segments.list[0].params[parameter].attrs["value"])
         if silent !=1: print "<><> presets"
         ##print obsBlock.scans.list[0].subscans.list[isub-1].presets.list[0].values['focusOffset']
         try:
            subs_focusOffset = string.atof(obsBlock.scans.list[0].subscans.list[isub-1].presets.list[0].values['focusOffset'])
         ##print obsBlock.scans.list[0].subscans.list[isub-1].presets.list[0].values['focusTranslation']
         except:
            if silent !=1: print "No preset focusOffset found"
            subs_focusOffset=0.0
         try:
            subs_focusTranslatio = obsBlock.scans.list[0].subscans.list[isub-1].presets.list[0].values['focusTranslation']
         except:
            if silent !=1: print "No preset focusTranslation found"
            subs_focusTranslatio='NULL'
            
      if subs_type in ["slewElevation"]:
         parameter="elevationStart"
         slew_Start=string.atof(obsBlock.scans.list[0].subscans.list[isub-1].params[parameter].attrs["value"])
         parameter="elevationEnd"
         slew_End=string.atof(obsBlock.scans.list[0].subscans.list[isub-1].params[parameter].attrs["value"])
         parameter="speed"
         slew_Speed=string.atof(obsBlock.scans.list[0].subscans.list[isub-1].params[parameter].attrs["value"])
         subs_timePerSubscan=math.fabs(slew_End-slew_Start)/slew_Speed
         subs_systemOffset='' ## So this variable exists
         
      ### find the observation start for this subscan or segment 1
      #  fix me: OTF we should use backOnTrack here? Yes, but Fall-back solution ?
      iseg=1
      if subs_type == 'airmass':
         findKey ="antMD:%s.%s.%s:subscanStarted" % (Date,iScanNo,isub)
      elif subs_type[0:3]=='cal':                                       #Fix me
         findKey ="masterCS:%s.%s.%s:subscanStarted" % (Date,iScanNo,isub)
      elif subs_type[0:7]=='onFocus':                                       #Fix me !! Wrong time used! Not antenna, but master
         findKey ="masterCS:%s.%s.%s:subscanStarted" % (Date,iScanNo,isub)
         ##findKey ="antMD:%s.%s.%s:subscanStarted" % (Date,iScanNo,isub)
         ###findKey ="antMD:%s.%s.%s:backOnTrack" % (Date,iScanNo,isub)
      elif subs_type[0:8]=='onTheFly':
## Has to change for antMD Vers. 20070615, used from 20071022 (?)
##         findKey ="antMD:%s.%s.%s.%s:backOnTrack" % (Date,iScanNo,isub,iseg)
         findKey ="antMD:%s.%s.%s.%s:segmentStarted" % (Date,iScanNo,isub,iseg) 
      elif subs_type[0:5]=='track':
         findKey ="antMD:%s.%s.%s:backOnTrack" % (Date,iScanNo,isub)
      elif subs_type[0:4]=='tune':
         findKey ="antMD:%s.%s.%s:backOnTrack" % (Date,iScanNo,isub)
      else:
         findKey ="antMD:%s.%s.%s:subscanStarted" % (Date,iScanNo,isub)
      if silent !=1: print 'To find dateObs use ',findKey
      found = syncMsg.has_key(findKey)
      if found:
         dateObs=syncMsg[findKey]
         if silent !=1: print 'Sync message found: ',findKey,dateObs
      else:
         ## fix me, maybe we should use "backOnTrack"
         if offLine:
            logger.ncsWarning(logId="dpCS.makeIMBFits: "+findKey+" not found",
                           data={"scanId": scanIdSubscan})
         if subs_type in ["OTF","otf","onTheFly"]:
            findKey ="antMD:%s.%s.%s.%s:segmentStarted" % (Date,iScanNo,isub,iseg)
            found = syncMsg.has_key(findKey)
            if found:
               dateObs=syncMsg[findKey]
               if silent !=1: print 'Sync message found: ',findKey,dateObs
            else:
               if silent !=1: print 'EXIT: Sync message expected from: ',findKey
               OutFITSfile.close()
               sys.exit(1)
         else: ## If not this finally give up! fix me, too complicated
            findKey ="masterCS:%s.%s.%s:subscanStarted" % (Date,iScanNo,isub)
            found = syncMsg.has_key(findKey)
            if found:
               dateObs=syncMsg[findKey]
               if silent !=1: print 'Sync message found: ',findKey,dateObs
            else:
               if silent !=1: print 'EXIT: Sync message expected from: ',findKey
               OutFITSfile.close()
               sys.exit(1)

   ### Now the antMD table: Find the subscan start of backend integration
      findKey ="rxCS:%s.%s.%s:synthezisersAdjusted" % (Date,iScanNo,isub)
      found = syncMsg.has_key(findKey)
      if found and isub != 1:
         subScanStart=syncMsg[findKey][-12:]
      else:   
         if subs_type in ["airmass"]:
            findKey ="antMD:%s.%s.%s:subscanStarted" % (Date,iScanNo,isub)
         #elif subs_type in ["calPaddle","calCold","calAmbient","calSky","calGrid","onFocus"]:                    #Fix me
         elif subs_type in ["calPaddle","calCold","calAmbient","calSky","calGrid"]:                    #Fix me
            findKey ="masterCS:%s.%s.%s:subscanStarted" % (Date,iScanNo,isub)
         else:
            findKey ="antMD:%s.%s.%s:subscanStarted" % (Date,iScanNo,isub)
         found = syncMsg.has_key(findKey)
         if found:
            subScanStart=syncMsg[findKey][-12:]
         else:
            if silent !=1: print "Subscan Start not found ",isub,findKey
      if silent !=1: print "Start of subscan found ",subScanStart," from ",syncMsg[findKey]
      if isub == 1:
         ScanStart=subScanStart
         ScanEnd=subScanStart
         ScanDateObs=dateObs

   ## Now the subscan end
   #   findKey ="antMD:%s.%s:subscanDone" % (InputFileStub,isub)
      if subs_type in ["airmass"]:
         findKey ="antMD:%s.%s.%s:subscanDone" % (Date,iScanNo,isub)
      elif subs_type in ["calPaddle","calCold","calAmbient","calSky","calGrid","onFocus"]:   #Fix me
##      elif subs_type in ["calPaddle","calCold","calAmbient","calSky","calGrid"]:   #Fix me
         findKey ="masterCS:%s.%s.%s:subscanDone" % (Date,iScanNo,isub)
      else:
         findKey ="antMD:%s.%s.%s:subscanDone" % (Date,iScanNo,isub)

      found = syncMsg.has_key(findKey)
      if found:
         subScanEnd=syncMsg[findKey][-12:]
         DatePart=syncMsg[findKey][:-12]
         endS=string.atof(subScanEnd[-6:])
         endM=string.atoi(subScanEnd[-9:-7])
         endH=string.atoi(subScanEnd[-12:-10])
         endSOD=endS+(endM+endH*60.)*60.
         if silent !=1: print "Date end H M S ",DatePart,endH,endM,endS,
         endSOD=endSOD-1./slowRate                         ## Message 1 slow rate late
         endH=int(endSOD/3600)
         endM=int((endSOD-endH*3600)/60)
         endS=endSOD-endH*3600-endM*60
         subScanEndMess="%02.2d:%02.2d:%06.3f" % (endH,endM,endS)
         dateEnd   =DatePart+subScanEndMess

         iYear =string.atoi(DatePart[:4])
         iMonth=string.atoi(DatePart[5:7])
         iDay  =string.atoi(DatePart[8:10])

      else:
         if silent !=1: print "Subscan End not found ",isub,findKey
         break
      if isub == (SubScansInLoop-1):
         ScanEnd=subScanEnd
      
      if silent !=1: print " to ",endH,endM,endS
      if silent !=1: print "subscan",isub,"started",subScanStart,"ended",subScanEnd,findKey
      if silent !=1: print "For the whole Scan we use as start ",ScanStart," and as end ",ScanEnd
      NoofBEpartsOut=8
      if isub == 1:
         Febepar4=imbfits_NIKA.Table('IMBF-subscans',Febepar2)
         Febepar4.create(fptr)
      Febepar4.Header.updateKeyword(fptr,'NVPPHASE','',NoofBEpartsOut)
      Febepar4.BinTable.addTableEntry(fptr,'Subscan',[isub])
      Febepar4.BinTable.subsTableEntry_str(fptr,'DATE-OBS',[dateObs])
      Febepar4.BinTable.subsTableEntry_str(fptr,'DATE-END',[dateEnd])
      Febepar4.BinTable.subsTableEntry_str(fptr,'OBSTYPE',[observingMode])
      if silent !=1: print "subs_type",subs_type
      Febepar4.BinTable.subsTableEntry_str(fptr,'SUBSTYPE',[subs_type])
      Febepar4.BinTable.subsTableEntry(fptr,'SUBSTIME',[float(subs_timePerSubscan)])
      if subs_type in ["airmass","calPaddle","onFocus","calSky","track","tune"]:
         Febepar4.BinTable.subsTableEntry_str(fptr,'SYSTEMOF',[subs_systemOffset])
         Febepar4.BinTable.subsTableEntry(fptr,'SUBSXOFF',[string.atof(subs_xOffset)])        # rad
         Febepar4.BinTable.subsTableEntry(fptr,'SUBSYOFF',[string.atof(subs_yOffset)])        # rad 
      if subs_type in ["onFocus","onTheFly"]: 
         Febepar4.BinTable.subsTableEntry_str(fptr,'FOTRANSL',[subs_focusTranslatio])
         Febepar4.BinTable.subsTableEntry(fptr,'FOOFFSET',[float(subs_focusOffset)])
      if subs_type in ["OTF","otf","onTheFly"]:
         if silent !=1: print "seg_type",seg_type
         Febepar4.BinTable.subsTableEntry_str(fptr,'SETYPE01',[seg_type])
         if silent !=1: print "subs_systemOffset",subs_systemOffset
         Febepar4.BinTable.subsTableEntry_str(fptr,'SYSTEMOF',[subs_systemOffset])
         Febepar4.BinTable.subsTableEntry(fptr,'SETIME01',[string.atof(subs_timePerSubscan)])
         if silent !=1: print  'seg_type', seg_type
         if seg_type == "linear":
            if silent !=1: print 'seg_xStart seg_yStart seg_xEnd seg_yEnd seg_speedStart seg_speedEnd',seg_xStart,seg_yStart,seg_xEnd,seg_yEnd,seg_speedStart,seg_speedEnd
            Febepar4.BinTable.subsTableEntry(fptr,'SEXSTA01',[seg_xStart])
            Febepar4.BinTable.subsTableEntry(fptr,'SEYSTA01',[seg_yStart])
            Febepar4.BinTable.subsTableEntry(fptr,'SEXEND01',[seg_xEnd])
            Febepar4.BinTable.subsTableEntry(fptr,'SEYEND01',[seg_yEnd])
            Febepar4.BinTable.subsTableEntry(fptr,'SESPES01',[seg_speedStart])
            Febepar4.BinTable.subsTableEntry(fptr,'SESPEE01',[seg_speedEnd])
      if isub == (SubScansInLoop-1):
         subScanStart=ScanStart
         subScanEnd=ScanEnd
         ScanDateEnd=dateEnd
         writeDataStreams=1
         OBSnum=1
         if silent !=1: print "Last Subscan  is ",isub
##         OutFITSfile.close()
##         exit()
      if silent !=1: print "FINISHED ",isub," now write the data:",writeDataStreams
   if writeDataStreams:
# Detect Midnight 
      if silent !=1: print SDate[-2:], '==', DatePart[-3:-1]
      if SDate[-2:] == DatePart[-3:-1]:
         midnight=False
         SDateM=SDate
            #In any case we need the date before the last midnight!
            #iMJDOBSbm=iMJDOBS-1
         if silent !=1: print 'iMJDOBS',iMJDOBS,type(iMJDOBS)
         if passedMidnight:
            iMJDOBSbm=iMJDOBS
            if silent !=1: print 'iMJDOBSbm pass',iMJDOBSbm
         else:
            iMJDOBSbm=iMJDOBS-1.0
            if silent !=1: print 'iMJDOBSbm==',iMJDOBSbm, type(iMJDOBSbm)
            yearBM,monthBM,dayBM,fracday = sla.djcl(iMJDOBSbm)
            SDateBM="%04.4d%02.2d%02.2d" % (yearBM,monthBM,dayBM)
      else:
         midnight=True
         passedMidnight=True
         SDateM=DatePart[:4]+DatePart[5:7]+DatePart[-3:-1]
         SDateBM=SDate
      if silent !=1: print "Midnight detected ",midnight,SDate,SDateM,passedMidnight

#
### Antenna datastreams First the slow
###  Find the traces
      largeList=[]
      oncePerSubscan=1
      
      if midnight:
         largeList=largeList+glob.glob(DataRootDir+"/datastreams/antmd/iram30m-antmd-"+SDate+"t[1-2]*")
         largeList=largeList+glob.glob(DataRootDir+"/datastreams/antmd/iram30m-antmd-"+SDateM+"t0*")
         largeList=largeList+glob.glob(DataRootDir+SDate+"/datastreams/antmd/iram30m-antmd-"+SDate+"t2*")
         largeList=largeList+glob.glob(DataRootDir+SDateM+"/datastreams/antmd/iram30m-antmd-"+SDateM+"t0*")
      else:      
         largeList=glob.glob(DataRootDir+"/datastreams/antmd/iram30m-antmd-"+SDate+"t*")
         largeList=largeList+glob.glob(DataRootDir+SDate+"/datastreams/antmd/iram30m-antmd-"+SDate+"t*")

      largeList.sort(lambda x, y: cmp(x[-20:],y[-20:]))

      smallList=[]
      prev=0;count=0
      # Write a function !
      timeFrom=subScanStart[0:12]
      #
      timeTo=subScanEnd[0:12]
      timeToFi=subScanEnd[0:8]   # Just to initialize
      # Bug fix, midnight triggered but start, stop times on same side of midnight
      if midnight and timeFrom<timeTo:
         midnight=False
         midnightJP=True
         if silent !=1: print "We just passed Midnight:",timeFrom,timeTo
      #
      # From
      endS=string.atof(subScanStart[-6:])
      endM=string.atoi(subScanStart[-9:-7])
      endH=string.atoi(subScanStart[-12:-10])
## WHERE do these 60. seconds come frome? Fine tuning just to pick up the right no. of files
## Fine tuning for IMBFits 3 Shoud be 62 ?
      endSOD  =endS + (endM+endH*60.)*60. - 59.
      endSODff=endS + (endM+endH*60.)*60. - 61.
      
      if endSOD<0:endSOD=0.0
      if silent !=1: print "H M S ",endH,endM,endS
      endH=int(endSOD/3600)
      endM=int((endSOD-endH*3600)/60)
      endS=endSOD-endH*3600-endM*60
      timeFromM="%02.2d:%02.2d:%06.3f" % (endH,endM,endS)
      timeFromMSI="%02.2d%02.2d%06.3f" % (endH,endM,endS)
      if silent !=1: print 'timeMSI ',timeFromMSI
      # To
      endS=string.atof(subScanEnd[-6:])
      endM=string.atoi(subScanEnd[-9:-7])
      endH=string.atoi(subScanEnd[-12:-10])
## WHERE do these 2 seconds come frome? Fine tuning just to pick up the right no. of files
## because of the 3 ? 1/slowrate seconds shift in time between slow and fast traces 
## BUT this is not correct anymore, is it?
##      endSOD=endS+(endM+endH*60.)*60. + 2.
      endSOD  =endS+(endM+endH*60.)*60.  - 1.0         ## Avoide taking too many trace-files slow
      endSODft=endS+(endM+endH*60.)*60.  + 1.0         ## Avoide taking too many trace-files fast
      endSOD  =endS+(endM+endH*60.)*60.           ## Avoide taking too many trace-files slow, but take the same no. of files
      endSODft=endS+(endM+endH*60.)*60.           ## Avoide taking too many trace-files fast
      if endSOD<0:endSOD=0.0
      if silent !=1: print "H M S ",endH,endM,endS
      endH=int(endSOD/3600)
      endM=int((endSOD-endH*3600)/60)
      endS=endSOD-endH*3600-endM*60
      timeToFi="%02.2d:%02.2d:%06.3f" % (endH,endM,endS)
      if silent !=1: print 'timeToFi ',timeToFi

      if silent !=1: print timeFromM,timeFrom,timeTo,timeToFi
      #01234567890123456789012345678901234
      ##iram30m-antmd-20050427t083507.fits
      #nf infileTime=infile[-13:-5]
      for infile in largeList:
         infileTime=infile[-11:-9]+":"+infile[-9:-7]+":"+infile[-7:-5]
         if midnight:# Midnight fixed?? 
            if infileTime>=timeFromM and infileTime<"24:00:00":
               count=count+1
               smallList.append(infile)            
            elif infileTime>="00:00:00" and infileTime<timeToFi:
               count=count+1
               smallList.append(infile)            
         else:
            if infileTime<timeFromM:              ## Was set to timeFrom ??
               prevFile=infile
               prev=1
            elif infileTime>=timeFromM and infileTime<timeToFi:
               count=count+1
               smallList.append(infile)

      if prev==1 and count>0:
         smallList=(smallList[:0]+[prevFile])+smallList
      elif prev==1 and count==0:
         smallList=[prevFile]
      if silent !=1: print count+prev,"antenna traces found:",smallList 
      if silent !=1: print "Now try ",SDateBM
      if prev==0 and len(SDateBM)>1 and not midnight:
         largeList=glob.glob(DataRootDir+"/datastreams/antmd/iram30m-antmd-"+SDateBM+"t2*")
         if len(largeList)==0:largeList=glob.glob(DataRootDir+SDateBM+"/datastreams/antmd/iram30m-antmd-"+SDateBM+"t2*")
         largeList.sort(lambda x, y: cmp(x[-20:],y[-20:]))
         if len(smallList)==0:
            smallList=[largeList[-1]]
         else:
            smallList=(smallList[:0]+[largeList[-1]])+smallList
         if silent !=1: print "Extended smallList ",smallList

      ##if subs_type in ["OTF","otf","onTheFly","track","onFocus"]: Now for all
      ## Fix me 2 Seconds added here to subscan start !!!
      ## Do not add for now 2005.09.30
      ## BUT at the end are 2 seconds of Fast traces missing, so add 2 sec. 2006.06.19
      ## Nothing added A.Sievers 2012.10.15
      MJDfrom=sla.mjd(iYear,iMonth,iDay)+((string.atoi(timeFrom[0:2])*60.+string.atoi(timeFrom[3:5]))*60.+string.atof(timeFrom[-6:])+0.0)/86400.
      MJDto=sla.mjd(iYear,iMonth,iDay)+((string.atoi(timeTo[0:2])*60.+ string.atoi(timeTo[3:5]))*60.+ string.atof(timeTo[-6:])+0.0)/86400.

      if midnight:MJDfrom=MJDfrom-1.0 #Fix me 20060908
      if silent !=1: print "antmd MJDfrom, MJDto ",MJDfrom, MJDto
      if silent !=1: print "antmd MJDfrom, MJDto ",timeFrom[0:2],timeFrom[3:5],timeFrom[-6:],timeFrom,isub
      if silent !=1: print "antmd MJDfrom, MJDto ",timeTo[0:2],timeTo[3:5],timeTo[-6:],timeTo,

# New table for slow antMD traces
      for infile in smallList:
         mode=0
         fptrin=pcfitsio.fits_open_file(infile,mode)
         pcfitsio.fits_movabs_hdu(fptrin,2)
         numCols=pcfitsio.fits_get_num_cols(fptrin)
         numRows=pcfitsio.fits_get_num_rows(fptrin)
         traceRate=string.atoi(pcfitsio.fits_read_keyword(fptrin,'TRACERAT')[0])
         slowRate=string.atoi(pcfitsio.fits_read_keyword(fptrin,'SLOWRATE')[0])
         nelements=numRows
         if oncePerSubscan:
            if silent !=1: print 'Found traceRate ',traceRate,' <<<<<<<<<<<<<<<<<'
            imbfits_NIKA.ComClass.TRACERAT=traceRate
            # Open DAP's table 1
            Datapar1=imbfits_NIKA.Table('IMBF-antenna-s',Febepar1)
            Datapar1.create(fptr)
            Datapar1.Header.updateKeyword(fptr,'SCANNUM','',iScanNo)
            Datapar1.Header.updateKeyword(fptr,'OBSNUM','',OBSnum)
            Datapar1.Header.updateKeyword(fptr,'DATE-OBS','',ScanDateObs)
            Datapar1.Header.updateKeyword(fptr,'DATE-END','',ScanDateEnd)
            Datapar1.Header.updateKeyword(fptr,'SUBSTIME','',subs_timePerSubscan)
            Datapar1.Header.updateKeyword(fptr,'SUBSTYPE','',subs_type)
            Datapar1.Header.updateKeyword(fptr,'OBSTYPE','',observingMode)
            if receiverNameSSB != 'None':
               Datapar1.Header.updateKeyword(fptr,'SBCALREC','',receiverNameSSB)
            Datapar1.Header.updateKeyword(fptr,'DOPPLERC','',dopplerCorrection)
            Datapar1.Header.updateKeyword(fptr,'OBSVELRF','',dopplerVlsr)
            Datapar1.Header.updateKeyword(fptr,'FEEDANGL','',FeedAngl)
            #slowRate=1 ############################################################################## FIX
            Datapar1.Header.updateKeyword(fptr,'SLOWRATE','',slowRate)

            if subs_type in ["airmass","calPaddle","onFocus","calSky","track","tune"]:
               Datapar1.Header.updateKeyword(fptr,'SYSTEMOF','',subs_systemOffset)
               Datapar1.Header.updateKeyword(fptr,'SUBSXOFF','',string.atof(subs_xOffset))        # rad
               Datapar1.Header.updateKeyword(fptr,'SUBSYOFF','',string.atof(subs_yOffset))        # rad 
            if subs_type == "onFocus":
               Datapar1.Header.updateKeyword(fptr,'FOTRANSL','',subs_focusTranslatio)
               Datapar1.Header.updateKeyword(fptr,'FOOFFSET','',subs_focusOffset)
            if subs_type in ["OTF","otf","onTheFly"]:
               Datapar1.Header.updateKeyword(fptr,'SETYPE01','',seg_type)
               Datapar1.Header.updateKeyword(fptr,'SYSTEMOF','',subs_systemOffset)
               Datapar1.Header.updateKeyword(fptr,'SETIME01','',subs_timePerSubscan)
               if seg_type == "linear":
                  Datapar1.Header.updateKeyword(fptr,'SEXSTA01','',seg_xStart)
                  Datapar1.Header.updateKeyword(fptr,'SEYSTA01','',seg_yStart)
                  Datapar1.Header.updateKeyword(fptr,'SEXEND01','',seg_xEnd)
                  Datapar1.Header.updateKeyword(fptr,'SEYEND01','',seg_yEnd)
                  Datapar1.Header.updateKeyword(fptr,'SESPES01','',seg_speedStart)
                  Datapar1.Header.updateKeyword(fptr,'SESPEE01','',seg_speedEnd)
            oncePerSubscan=0
            neleSlow=0
         firstrow=1;firstelem=1;nulval=0.0
         column=8 # select according to the SLOW traces
         # The last item is zero(? check)
         days1970=pcfitsio.fits_read_col(fptrin,column,firstrow,firstelem,nelements,nulval)[:-1]
         if silent !=1: print len(days1970),' How many slow traces ?'
         outFrom=0;outTo=0
         for ii in range(numRows):
            MJDin=days1970[ii]
            #if silent !=1: print MJDin,MJDfrom,MJDto,ii
#            if MJDin <  MJDfrom : outFrom = ii+1
#            if MJDin <= MJDto   : outTo   = ii+1
            if MJDin <= MJDfrom : outFrom = ii+1
            if MJDin <  MJDto   : outTo   = ii+1
         if silent !=1: print outFrom,outTo
         # If all traces have time stamps > MJDto
         #if outFrom == 0 and outTo == 0 : break
         if outFrom==0:
            outFrom=1        
         nelements=outTo-outFrom+1
         if nelements>1:
            neleSlow=neleSlow + nelements
         if silent !=1: print "neleSlow ",neleSlow
         # If all traces have time stamps < MJDfrom CHECK
         #if nelements == 1 and outFrom == numRows-1 : break
         if nelements > 1: 
            column=pcfitsio.fits_get_colnum(fptrin,0,'MJD')[1]
            MJD70=    pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=9 ;column=pcfitsio.fits_get_colnum(fptrin,0,'LST')[1]
            LST=      pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=10;column=pcfitsio.fits_get_colnum(fptrin,0,'xOffset')[1]
            xOffset=  pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=11;column=pcfitsio.fits_get_colnum(fptrin,0,'yOffset')[1]
            yOffset=  pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=12;column=pcfitsio.fits_get_colnum(fptrin,0,'Azm')[1]
            commAz=   pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=13;column=pcfitsio.fits_get_colnum(fptrin,0,'Elv')[1]
            commElv=  pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=14;column=pcfitsio.fits_get_colnum(fptrin,0,'basisLong')[1]
            basisLong=pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=15;column=pcfitsio.fits_get_colnum(fptrin,0,'basisLat')[1]
            basisLat= pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=16;column=pcfitsio.fits_get_colnum(fptrin,0,'parAngle')[1]
            parAngle= pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=17;column=pcfitsio.fits_get_colnum(fptrin,0,'inSegment')[1]
            inSegment=pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=18;column=pcfitsio.fits_get_colnum(fptrin,0,'traceFlag')[1]
            traceFlag=pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
#
#            status=pcfitsio.fits_close_file(fptrin)
            # Close the input file or we open too many
            
            for idap in range(nelements):
               Datapar1.BinTable.addTableEntry(fptr,'INTEGNUM',[outFrom+idap+1]) #just for debugging
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'MJD',[MJD70[idap]+MJDfudge]) # MJD check
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'LST', [(LST[idap]/(2.0*math.pi))*86400.]) # rad --> seconds
               ## From 20091110 
               if subs_systemOffset == 'horizontalTrue':
                  Datapar1.BinTable.subsTableEntry_dbl(fptr,'LONGOFF', [xOffset[idap]*math.cos(commElv[idap])])   # rad 
               else:
                  Datapar1.BinTable.subsTableEntry_dbl(fptr,'LONGOFF', [xOffset[idap]])   # rad 
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'LATOFF',  [yOffset[idap]])   # rad 
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'CAZIMUTH', [commAz[idap]])      # rad 
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'CELEVATIO',[commElv[idap]])     # rad 
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'BASLONG', [basisLong[idap]]) # rad 
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'BASLAT',  [basisLat[idap]])  # rad
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'PARANGLE',[parAngle[idap]])  # rad 
               Datapar1.BinTable.subsTableEntry(fptr,'INSEGMENT',[inSegment[idap]])
               Datapar1.BinTable.subsTableEntry(fptr,'TRACEFLAG',[traceFlag[idap]])

               if oncePerScan and (MJD70[idap] >= MJDOBS):
                  if sourceName in sourcePlanet or sourceName[:4] in ['BODY']:
                  ## Fix me, first value(s?) may still be bad
                     LongObject=basisLong[idap]*180./math.pi
                     Scan1.Header.updateKeyword(fptr,'LONGOBJ','',LongObject)
                     LatObject=basisLat[idap]*180./math.pi
                     Scan1.Header.updateKeyword(fptr,'LATOBJ','',LatObject)
                  oncePerScan=0
         status=pcfitsio.fits_close_file(fptrin)
### New table for fast antMD traces
      oncePerSubscan=1; nTr=0; mTr=len(smallList)
# We had redefined largeList above when going over midnight!! 
      largeList=[]
      if midnight:
         largeList=largeList+glob.glob(DataRootDir+"/datastreams/antmd/iram30m-antmd-"+SDate+"t[1-2]*")
         largeList=largeList+glob.glob(DataRootDir+"/datastreams/antmd/iram30m-antmd-"+SDateM+"t0*")
         largeList=largeList+glob.glob(DataRootDir+SDate+"/datastreams/antmd/iram30m-antmd-"+SDate+"t2*")
         largeList=largeList+glob.glob(DataRootDir+SDateM+"/datastreams/antmd/iram30m-antmd-"+SDateM+"t0*")
      else:      
         largeList=glob.glob(DataRootDir+"/datastreams/antmd/iram30m-antmd-"+SDate+"t*")
         largeList=largeList+glob.glob(DataRootDir+SDate+"/datastreams/antmd/iram30m-antmd-"+SDate+"t*")

      largeList.sort(lambda x, y: cmp(x[-20:],y[-20:]))
#
#     New From for fast traces
      if silent !=1: print "endSODff ",endSODff
      if endSODff<0:endSODff=0.0
      if silent !=1: print "H M S ",endH,endM,endS
      endH=int(endSODff/3600)
      endM=int((endSODff-endH*3600)/60)
      endS=endSODff-endH*3600-endM*60
      timeFromM="%02.2d:%02.2d:%06.3f" % (endH,endM,endS)
      timeFromMSI="%02.2d%02.2d%06.3f" % (endH,endM,endS)
      if silent !=1: print 'timeFromM ',timeFromM
#     To
      if silent !=1: print "endSODft ",endSODft
      if endSODft<0:endSODft=0.0
      if silent !=1: print "H M S ",endH,endM,endS
      endH=int(endSODft/3600)
      endM=int((endSODft-endH*3600)/60)
      endS=endSODft-endH*3600-endM*60
      timeToFi="%02.2d:%02.2d:%06.3f" % (endH,endM,endS)
      if silent !=1: print 'timeToFi ',timeToFi
      smallList=[];count=0;prev=0
      if silent !=1: print "timeFromM,timeToFi :",timeFromM,timeToFi
      for infile in largeList:
         infileTime=infile[-11:-9]+":"+infile[-9:-7]+":"+infile[-7:-5]
         if midnight:# Midnight fixed?? 
            if infileTime>=timeFromM and infileTime<"24:00:00":
               count=count+1
               smallList.append(infile)
               if silent !=1: print "m if infileTime,timeFromM,timeToFi ",infileTime,timeFromM,timeToFi  
            elif infileTime>="00:00:00" and infileTime<timeToFi:
               count=count+1
               smallList.append(infile)
               if silent !=1: print "m elif infileTime,timeFromM,timeToFi ",infileTime,timeFromM,timeToFi  
         else:
            if infileTime<timeFromM:              ## Was set to timeFrom ??
               prevFile=infile
               prev=1
               #if silent !=1: print infileTime,
               #if silent !=1: print "if infileTime,timeFromM,timeToFi ",infileTime,timeFromM,timeToFi  
            elif infileTime>=timeFromM and infileTime<timeToFi:
               count=count+1
               smallList.append(infile)
               if silent !=1: print "elif infileTime,timeFromM,timeToFi ",infileTime,timeFromM,timeToFi
      if prev==1 and count>0:
         smallList=(smallList[:0]+[prevFile])+smallList
      elif prev==1 and count==0:
         smallList=[prevFile]
      if silent !=1: print count+prev,"antenna traces found f:",smallList 
      if silent !=1: print "Now try ",SDateBM
      if prev==0 and len(SDateBM)>1 and not midnight:
         largeList=glob.glob(DataRootDir+"/datastreams/antmd/iram30m-antmd-"+SDateBM+"t2*")
         if len(largeList)==0:largeList=glob.glob(DataRootDir+SDateBM+"/datastreams/antmd/iram30m-antmd-"+SDateBM+"t2*")
         largeList.sort(lambda x, y: cmp(x[-20:],y[-20:]))
         if len(smallList)==0:
            smallList=[largeList[-1]]
         else:
            smallList=(smallList[:0]+[largeList[-1]])+smallList
         if silent !=1: print "Extended smallList f ",smallList
      nTr=0;mTr=len(smallList)
      ## Bug found 28 Mar. 2014 as
##      # special cheat for rz
      MJDto = MJDto + 0.9*1.15740741e-5/traceRate
      for infile in smallList:
         mode=0;nTr=nTr+1
         fptrin=pcfitsio.fits_open_file(infile,mode)
         pcfitsio.fits_movabs_hdu(fptrin,2)
         numCols=pcfitsio.fits_get_num_cols(fptrin)
         numRows=pcfitsio.fits_get_num_rows(fptrin)
         traceRate=string.atoi(pcfitsio.fits_read_keyword(fptrin,'TRACERAT')[0])
         slowRate=string.atoi(pcfitsio.fits_read_keyword(fptrin,'SLOWRATE')[0])
         nelements=numRows
         #if silent !=1: print 'Fast amd oncePerSubscan ',oncePerSubscan
         if oncePerSubscan:
            if silent !=1: print 'Found traceRate ',traceRate,' <<<<<<<<<<<<<<<<<'
            imbfits_NIKA.ComClass.TRACERAT=traceRate
            # Open DAP's table 1
            Datapar1=imbfits_NIKA.Table('IMBF-antenna-f',Febepar1)
            Datapar1.create(fptr)
            Datapar1.Header.updateKeyword(fptr,'SCANNUM','',iScanNo)
            Datapar1.Header.updateKeyword(fptr,'OBSNUM','',OBSnum)
            Datapar1.Header.updateKeyword(fptr,'DATE-OBS','',ScanDateObs)
            Datapar1.Header.updateKeyword(fptr,'DATE-END','',ScanDateEnd)
            Datapar1.Header.updateKeyword(fptr,'SUBSTIME','',subs_timePerSubscan)
            Datapar1.Header.updateKeyword(fptr,'SUBSTYPE','',subs_type)
            Datapar1.Header.updateKeyword(fptr,'OBSTYPE','',observingMode)
            if receiverNameSSB != 'None':
               Datapar1.Header.updateKeyword(fptr,'SBCALREC','',receiverNameSSB)
            Datapar1.Header.updateKeyword(fptr,'DOPPLERC','',dopplerCorrection)
            Datapar1.Header.updateKeyword(fptr,'OBSVELRF','',dopplerVlsr)
            Datapar1.Header.updateKeyword(fptr,'FEEDANGL','',FeedAngl)
            Datapar1.Header.updateKeyword(fptr,'SLOWRATE','',slowRate)

            if subs_type in ["airmass","calPaddle","onFocus","calSky","track","tune"]:
               Datapar1.Header.updateKeyword(fptr,'SYSTEMOF','',subs_systemOffset)
               Datapar1.Header.updateKeyword(fptr,'SUBSXOFF','',string.atof(subs_xOffset))        # rad
               Datapar1.Header.updateKeyword(fptr,'SUBSYOFF','',string.atof(subs_yOffset))        # rad 
            if subs_type == "onFocus":
               Datapar1.Header.updateKeyword(fptr,'FOTRANSL','',subs_focusTranslatio)
               Datapar1.Header.updateKeyword(fptr,'FOOFFSET','',subs_focusOffset)
            if subs_type in ["OTF","otf","onTheFly"]:
               Datapar1.Header.updateKeyword(fptr,'SETYPE01','',seg_type)
               Datapar1.Header.updateKeyword(fptr,'SYSTEMOF','',subs_systemOffset)
               Datapar1.Header.updateKeyword(fptr,'SETIME01','',subs_timePerSubscan)
               if seg_type == "linear":
                  Datapar1.Header.updateKeyword(fptr,'SEXSTA01','',seg_xStart)
                  Datapar1.Header.updateKeyword(fptr,'SEYSTA01','',seg_yStart)
                  Datapar1.Header.updateKeyword(fptr,'SEXEND01','',seg_xEnd)
                  Datapar1.Header.updateKeyword(fptr,'SEYEND01','',seg_yEnd)
                  Datapar1.Header.updateKeyword(fptr,'SESPES01','',seg_speedStart)
                  Datapar1.Header.updateKeyword(fptr,'SESPEE01','',seg_speedEnd)
            oncePerSubscan=0
            neleFast=0
         firstrow=1;firstelem=1;nulval=0.0;WriteOne=0
         column=1 # select according to the FAST traces
         # The last item is zero(? check)
         days1970f=pcfitsio.fits_read_col(fptrin,column,firstrow,firstelem,nelements*traceRate,nulval)[:-1]  
         if silent !=1: print 'No. of fast time-stamps ',len(days1970f)
         days1970ff=[]
         for ii in range(len(days1970f)):
            if (ii % traceRate == 0):
                days1970ff = days1970ff + [days1970f[ii]]
#Bug                days1970[iii] = days1970f[ii] length depended on previous datastream 
#Bug                iii = iii+1
         #if silent !=1: print 'Using ',len(days1970ff),' corresponding to the first fast trace of each slow trace.'
         outFrom=0;outTo=0
         for ii in range(numRows):
            MJDin=days1970ff[ii]
            #if silent !=1: print MJDin,MJDfrom,MJDto,ii
            if MJDin <=  MJDfrom : outFrom = ii+1
            if MJDin <  MJDto   : outTo   = ii+1
         if silent !=1: print outFrom,outTo
         # If all traces have time stamps > MJDto
         #if outFrom == 0 and outTo == 0 : break
         #if outFrom == outTo and outFrom == numRows : break
         #
         if outFrom==0:
            outFrom=1        
         nelements=outTo-outFrom+1
         if nelements>1:
            neleFast=neleFast + nelements
         if silent !=1: print 'nelements before ',nelements
         if silent !=1: print 'nTr,mTr ',nTr,mTr
#         if (outTo<numRows and nelements>1):                  # Only when using the last file in the list. FIX ME
         if (nTr == mTr):
            if ((neleFast-neleSlow) > -3):
               nelements=nelements + (neleSlow-neleFast)
               #if silent !=1: print " neleFS ",infile[-20:-4]," ,isub,neleSlow,neleFast,(neleFast-neleSlow),len(smallList)"
               if silent !=1: print " neleFS ",infile[-20:-4]," ",isub,neleSlow,neleFast,(neleFast-neleSlow),len(smallList)
            else:
               if silent !=1: print "No correction for: "
               if silent !=1: print " neleFSn ",infile[-20:-4]," ",isub,neleSlow,neleFast,(neleFast-neleSlow),len(smallList)
         if silent !=1: print 'nelements after ',nelements
         if (nelements == 1 and (neleSlow-neleFast)<0):
            WriteOne=1 
         # If all traces have time stamps < MJDfrom CHECK
         #if nelements == 1 and outFrom == numRows-1 : break
         if (nelements > 1 or WriteOne == 1) : 

            column=1;column=pcfitsio.fits_get_colnum(fptrin,0,'MJDfast')[1]
            MJD70fast= pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements*traceRate,nulval)[:-1]
            column=2;column=pcfitsio.fits_get_colnum(fptrin,0,'actualAz')[1]
            actualAz= pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements*traceRate,nulval)[:-1]
            column=3;column=pcfitsio.fits_get_colnum(fptrin,0,'actualEl')[1]
            actualEl= pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements*traceRate,nulval)[:-1]
            column=4;column=pcfitsio.fits_get_colnum(fptrin,0,'trackAz')[1]
            trackAz=  pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements*traceRate,nulval)[:-1]
            column=5;column=pcfitsio.fits_get_colnum(fptrin,0,'trackEl')[1]
            trackEl=  pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements*traceRate,nulval)[:-1]
            column=6;column=pcfitsio.fits_get_colnum(fptrin,0,'azTrackFlag')[1]
            AzTrackFlag= pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements*traceRate,nulval)[:-1]
            column=7;column=pcfitsio.fits_get_colnum(fptrin,0,'elTrackFlag')[1]
            ElTrackFlag= pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements*traceRate,nulval)[:-1]

         ##   status=pcfitsio.fits_close_file(fptrin)
            # Close the input file or we open too many
            
            for idap in range(nelements):
               Datapar1.BinTable.addTableEntry(fptr,'INTEGNUM',[outFrom+idap+1]) #just for debugging
               trTu=[]
               for i in range(traceRate):trTu.append(MJD70fast[idap*traceRate+i])# MJD
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'MJDFAST',trTu) 
               trTu=[]
               for i in range(traceRate):trTu.append(actualAz[idap*traceRate+i]*encToRad)# enc --> radian
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'AZIMUTH',trTu)
               trTu=[]
               for i in range(traceRate):trTu.append(actualEl[idap*traceRate+i]*encToRad)# enc --> radian
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'ELEVATION',trTu)
               trTu=[]
               for i in range(traceRate):trTu.append(trackAz[idap*traceRate+i]*encToRad)# enc --> radian
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'TRACKING_AZ',trTu)
               trTu=[]
               for i in range(traceRate):trTu.append(trackEl[idap*traceRate+i]*encToRad)# enc --> radian
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'TRACKING_EL',trTu)
               trTu=[]
               for i in range(traceRate):trTu.append(AzTrackFlag[idap*traceRate+i])
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'AZTRACKFLAG',trTu)
               trTu=[]
               for i in range(traceRate):trTu.append(ElTrackFlag[idap*traceRate+i])
               Datapar1.BinTable.subsTableEntry_dbl(fptr,'ELTRACKFLAG',trTu)

               if oncePerScan and (MJD70[idap] >= MJDOBS):
                  if sourceName in sourcePlanet or sourceName[:4] in ['BODY']:
                  ## Fix me, first value(s?) may still be bad
                     LongObject=basisLong[idap]*180./math.pi
                     Scan1.Header.updateKeyword(fptr,'LONGOBJ','',LongObject)
                     LatObject=basisLat[idap]*180./math.pi
                     Scan1.Header.updateKeyword(fptr,'LATOBJ','',LatObject)
                  oncePerScan=0
         status=pcfitsio.fits_close_file(fptrin)
   ##
   ###  Find the secondary traces
   ##
      oncePerSubscan=1
      if midnight or midnightJP:
         largeList=glob.glob(DataRootDir+"/datastreams/secondary/iram30m-secondary-"+SDate+"t[1-2]*")
         largeList=largeList+glob.glob(DataRootDir+"/datastreams/secondary/iram30m-secondary-"+SDateM+"t0*")
         largeList=largeList+glob.glob(DataRootDir+SDate+"/datastreams/secondary/iram30m-secondary-"+SDate+"t[1-2]*")
         largeList=largeList+glob.glob(DataRootDir+SDateM+"/datastreams/secondary/iram30m-secondary-"+SDateM+"t0*")
      else:
         largeList=glob.glob(DataRootDir+"/datastreams/secondary/iram30m-secondary-"+SDate+"t*")
         largeList=largeList+glob.glob(DataRootDir+SDate+"/datastreams/secondary/iram30m-secondary-"+SDate+"t*")

      largeList.sort(lambda x, y: cmp(x[-20:],y[-20:]))
      smallList=[]
      prev=0;count=0
      timeFrom=subScanStart[0:12];timeTo=subScanEnd[0:12]
      if silent !=1: print timeFrom,timeTo
      for infile in largeList:
         infileTime=infile[-11:-9]+":"+infile[-9:-7]+":"+infile[-7:-5]
         if midnight:# Midnight fixed?? 
            if infileTime>=timeFromM and infileTime<"24:00:00":
               count=count+1
               smallList.append(infile)            
            elif infileTime>="00:00:00" and infileTime<timeTo:
               count=count+1
               smallList.append(infile)            
         else:
            if infileTime<timeFrom:
               prevFile=infile
               prev=1
            elif infileTime>=timeFrom and infileTime<timeTo:
               count=count+1
               smallList.append(infile)

      if prev==1 and count>0:
         smallList=(smallList[:0]+[prevFile])+smallList
      elif prev==1 and count==0:
         smallList=[prevFile]
      if silent !=1: print count+prev,"subreflector traces found:",smallList

      if prev==0 and len(SDateBM)>1 and not midnight:
         largeList=glob.glob(DataRootDir+"/datastreams/secondary/iram30m-secondary-"+SDateBM+"t2*")
         if len(largeList)==0:largeList=glob.glob(DataRootDir+SDateBM+"/datastreams/secondary/iram30m-secondary-"+SDateBM+"t2*")
         largeList.sort(lambda x, y: cmp(x[-20:],y[-20:]))
         if len(smallList)==0:
            smallList=[largeList[-1]]
         else:
            smallList=(smallList[:0]+[largeList[-1]])+smallList
         if silent !=1: print "Extended smallList ",smallList

      UCTfrom=((string.atoi(timeFrom[0:2])*60.+ string.atoi(timeFrom[3:5]))*60.+ string.atof(timeFrom[-6:]))*1000 #ms
      UCTto=((string.atoi(timeTo[0:2])*60.+ string.atoi(timeTo[3:5]))*60.+ string.atof(timeTo[-6:]))*1000 # ms
      if silent !=1: print 'secondary ',UCTfrom,UCTto
      midnight2=False
      for infile in smallList:
         mode=0
         fptrin=pcfitsio.fits_open_file(infile,mode)
         pcfitsio.fits_movabs_hdu(fptrin,2)
         numCols=pcfitsio.fits_get_num_cols(fptrin);numRows=pcfitsio.fits_get_num_rows(fptrin)
         nelements=numRows
         if oncePerSubscan:
            ## Open subreflector traces (DAP's) table DATAPA3
            Datapar3=imbfits_NIKA.Table('IMBF-subreflector',Febepar1)
            Datapar3.create(fptr)
            Datapar3.Header.updateKeyword(fptr,'SCANNUM','',iScanNo)
            Datapar3.Header.updateKeyword(fptr,'OBSNUM','',OBSnum)
            Datapar3.Header.updateKeyword(fptr,'DATE-OBS','',ScanDateObs)
            Datapar3.Header.updateKeyword(fptr,'DATE-END','',ScanDateEnd)
            Datapar3.Header.updateKeyword(fptr,'SUBSTIME','',subs_timePerSubscan)
            Datapar3.Header.updateKeyword(fptr,'SUBSTYPE','',subs_type)
            Datapar3.Header.updateKeyword(fptr,'OBSTYPE','',observingMode)
            if receiverNameSSB != 'None':
               Datapar3.Header.updateKeyword(fptr,'SBCALREC','',receiverNameSSB)
            Datapar3.Header.updateKeyword(fptr,'DOPPLERC','',dopplerCorrection)
            Datapar3.Header.updateKeyword(fptr,'OBSVELRF','',dopplerVlsr)
            Datapar3.Header.updateKeyword(fptr,'FEEDANGL','',FeedAngl)
            if subs_type in ["airmass","calPaddle","onFocus","track","tune"]:
               Datapar3.Header.updateKeyword(fptr,'SYSTEMOF','',subs_systemOffset)
               Datapar3.Header.updateKeyword(fptr,'SUBSXOFF','',string.atof(subs_xOffset))        # rad
               Datapar3.Header.updateKeyword(fptr,'SUBSYOFF','',string.atof(subs_yOffset))        # rad 
            if subs_type == "onFocus":
               Datapar3.Header.updateKeyword(fptr,'FOTRANSL','',subs_focusTranslatio)
               Datapar3.Header.updateKeyword(fptr,'FOOFFSET','',subs_focusOffset)
            if subs_type in ["OTF","otf","onTheFly"]:
               Datapar3.Header.updateKeyword(fptr,'SETYPE01','',seg_type)
               Datapar3.Header.updateKeyword(fptr,'SYSTEMOF','',subs_systemOffset)
               Datapar3.Header.updateKeyword(fptr,'SETIME01','',subs_timePerSubscan)
               if seg_type == "linear":
                  Datapar3.Header.updateKeyword(fptr,'SEXSTA01','',seg_xStart)
                  Datapar3.Header.updateKeyword(fptr,'SEYSTA01','',seg_yStart)
                  Datapar3.Header.updateKeyword(fptr,'SEXEND01','',seg_xEnd)
                  Datapar3.Header.updateKeyword(fptr,'SEYEND01','',seg_yEnd)
                  Datapar3.Header.updateKeyword(fptr,'SESPES01','',seg_speedStart)
                  Datapar3.Header.updateKeyword(fptr,'SESPEE01','',seg_speedEnd)
            oncePerSubscan=0
         firstrow=1;firstelem=1;nulval=0.0
         column=1
         # The last item is zero (? check)
         UCTms=pcfitsio.fits_read_col(fptrin,column,firstrow,firstelem,nelements,nulval)[:-1]

         outFrom=0;outTo=0;midnightTrace=False;afterMid=True
         for ii in range(numRows):
            if midnight:
               if UCTms[ii] < UCTfrom and UCTms[ii] > 36000000 : outFrom = ii+1 # 10 hours !
               if UCTms[ii] > UCTfrom and UCTms[ii] <= 86400000:
                  outTo   = ii+1
               elif UCTms[ii] <= UCTto:
                  outTo   = ii+1
            else:
               if ii>0 and UCTms[ii]<UCTms[ii-1]:
                  midnightTrace=True
                  if outTo > 0:
                     afterMid=False
                  elif outFrom == 0:
                     outFrom=ii
                  if silent !=1: print "after midnight found: ",afterMid,ii,outTo
               if not midnightTrace:
                  if UCTms[ii] < UCTfrom : outFrom = ii+1
                  if UCTms[ii] <= UCTto  : outTo   = ii+1
               elif midnightTrace and afterMid:
                  if UCTms[ii] < UCTfrom : outFrom = ii+1
                  if UCTms[ii] <= UCTto  : outTo   = ii+1

         if silent !=1: print 'Use lines ',outFrom,outTo,' from ',infile
         # If all traces have time stamps >= MJDto
         if outFrom == 0 and outTo == 0 : continue
         if outFrom==0:outFrom=1              
         nelements=outTo-outFrom+1
         # If all traces have time stamps > MJDto CHECK
         #if nelements == 1 and outFrom == numRows-1 : break
         if nelements > 0:
            column=1 ; column=pcfitsio.fits_get_colnum(fptrin,0,'UTC')[1]
            UCTms =   pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=2 ; column=pcfitsio.fits_get_colnum(fptrin,0,'focusX')[1]
            focusX=   pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=3 ; column=pcfitsio.fits_get_colnum(fptrin,0,'focusY')[1]
            focusY=   pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=4 ; column=pcfitsio.fits_get_colnum(fptrin,0,'focusZ')[1]
            focusZ=   pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=5 ; column=pcfitsio.fits_get_colnum(fptrin,0,'phiX')[1]
            phiX  =   pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=6 ; column=pcfitsio.fits_get_colnum(fptrin,0,'phiY')[1]
            phiY  =   pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=7 ; column=pcfitsio.fits_get_colnum(fptrin,0,'phiZ')[1]
            phiZ  =   pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]
            column=8 ; column=pcfitsio.fits_get_colnum(fptrin,0,'feedAngle')[1]
            feedAngle=pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,nelements,nulval)[:-1]

            status=pcfitsio.fits_close_file(fptrin)

            for idap in range(nelements):
               Datapar3.BinTable.addTableEntry(fptr,'INTEGNUM',      [outFrom+idap]) #just for debugging
               if idap>=1 and UCTms[idap] < UCTms[idap-1]: midnight2=True
               if midnight2 and midnight:
                  MJDsubr=sla.mjd(iYear,iMonth,iDay) + UCTms[idap]/86400000.
               elif midnight:
                  MJDsubr=sla.mjd(iYear,iMonth,iDay) + UCTms[idap]/86400000. - 1.0            
               else:
                  MJDsubr=sla.mjd(iYear,iMonth,iDay) + UCTms[idap]/86400000.
               Datapar3.BinTable.subsTableEntry_dbl(fptr,'MJD',      [MJDsubr])                         # Fix me, ms
               Datapar3.BinTable.subsTableEntry_dbl(fptr,'FOCUS_X',  [focusX[idap]/1000.])     # Micron ==> mm
               Datapar3.BinTable.subsTableEntry_dbl(fptr,'FOCUS_Y',  [focusY[idap]/1000.])     # Micron ==> mm 
               Datapar3.BinTable.subsTableEntry_dbl(fptr,'FOCUS_Z',  [focusZ[idap]/1000.])     # Micron ==> mm 
               Datapar3.BinTable.subsTableEntry_dbl(fptr,'PHI_X',    [phiX[idap]*sencToRad])       # 0.0001 d 
               Datapar3.BinTable.subsTableEntry_dbl(fptr,'PHI_Y',    [phiY[idap]*sencToRad])       # 0.0001 d
               Datapar3.BinTable.subsTableEntry_dbl(fptr,'PHI_Z',    [phiZ[idap]*sencToRad])       # 0.0001 d
               Datapar3.BinTable.subsTableEntry_dbl(fptr,'FEEDANGLE',[feedAngle[idap]*500*sencToRad])  # 3 arc min 

   ### Backends
   ### Preparing to write the SIS continuum data
      if ChosenBackend=='continuum':
         inDirBackend=DataRootDir+"/datastreams/continuum/"
         if midnight or midnightJP:
            largeList=glob.glob(inDirBackend+"iram30m-continuum-"+SDate+"t[1-2]*")
            largeList=largeList+glob.glob(inDirBackend+"iram30m-continuum-"+SDateM+"t0*")
            largeList=largeList+glob.glob(DataRootDir+SDate+"/datastreams/continuum/iram30m-continuum-"+SDate+"t[1-2]*")
            largeList=largeList+glob.glob(DataRootDir+SDateM+"/datastreams/continuum/iram30m-continuum-"+SDateM+"t0*")
         else:
            largeList=glob.glob(inDirBackend+"iram30m-continuum-"+SDate+"t*.fits")
            largeList=largeList+glob.glob(DataRootDir+SDate+"/datastreams/continuum/"+"iram30m-continuum-"+SDate+"t*.fits")
         if len(largeList) == 0:
            if silent !=1: print "No data found for continuum"
         largeList.sort(lambda x, y: cmp(x[-20:],y[-20:]))
         smallList=[]
         prev=0;count=0
         timeFrom=subScanStart[0:8];timeTo=subScanEnd[0:8]
   #      timeFromSI=(string.atoi(timeFrom[:2]) * 60 + string.atoi(timeFrom[3:5]))*60 + string.atoi(timeFrom[6:8])
         timeFromSI=timeFrom[:2] + timeFrom[3:5] + timeFrom[6:8]
         secondsFrom=(string.atoi(timeFrom[:2]) * 60 + string.atoi(timeFrom[3:5]))*60 + string.atoi(timeFrom[6:8])
         timeToSI=timeTo[:2] + timeTo[3:5] + timeTo[6:8]
         secondsTo=(string.atoi(timeTo[:2]) * 60 + string.atoi(timeTo[3:5]))*60 + string.atoi(timeTo[6:8])
         if silent !=1: print 'time(From,To)SI ',timeFromSI,timeToSI
         endSOD=secondsFrom-60.
         if endSOD<0:endSOD=0.0
         endH=int(endSOD/3600)
         endM=int((endSOD-endH*3600)/60)
         endS=endSOD-endH*3600-endM*60
         timeFromMSI="%02.2d%02.2d%06.3f" % (endH,endM,endS)
         if silent !=1: print 'timeMSI ',timeFromMSI

         for infile in largeList:
            infileTime=infile[-11:-5]
            if midnight:# Midnight fixed??
               if infileTime>=timeFromMSI and infileTime<"240000":
                  count=count+1
                  smallList.append(infile)            
               elif infileTime>="000000" and infileTime<timeToSI:
                  count=count+1
                  smallList.append(infile)            
            else:            
               if infileTime<timeFromSI:
                  prevFile=infile
                  prev=1
               elif infileTime >= timeFromSI and infileTime < timeToSI:
                  count=count+1
                  smallList.append(infile)
         if prev==1 and count>0:
            smallList=(smallList[:0]+[prevFile])+smallList
         elif prev==1 and count==0:
            smallList=[prevFile]
         if silent !=1: print count+prev,"continuum data found:",smallList
         #if count+prev==0:break
         if prev==0 and len(SDateBM)>1 and not midnight:
            largeList=glob.glob(DataRootDir+"/datastreams/continuum/iram30m-continuum-"+SDateBM+"t2*")
            if len(largeList)==0:largeList=glob.glob(DataRootDir+SDateBM+"/datastreams/continuum/iram30m-continuum-"+SDateBM+"t2*")
            largeList.sort(lambda x, y: cmp(x[-20:],y[-20:]))
            if len(smallList)==0:
               smallList=[largeList[-1]]
            else:
               smallList=(smallList[:0]+[largeList[-1]])+smallList
            if silent !=1: print "Extended smallList ",smallList


   ## Now read and write the backend continuum data
         firstData=1
         midnight2=False;UTCtsOld=0.0
         for infile in smallList:
            mode=0
            fptrin=pcfitsio.fits_open_file(infile,mode)
            pcfitsio.fits_movabs_hdu(fptrin,2)
            numCols=pcfitsio.fits_get_num_cols(fptrin)
            numRows=pcfitsio.fits_get_num_rows(fptrin)
   #        Nchannel=string.atoi(pcfitsio.fits_read_keyword(fptrin,'NRCHAN')[0])
   # The raw data always has 4 channels, but we may have used less
            Nchannel=NoofBEparts
            if firstData:
               normalized=False    # Fix me
               imbfits_NIKA.ComClass.NCH=Nchannel*bePixels
               Arraydata1=imbfits_NIKA.Table('IMBF-backendCONT',Febepar1)
               Arraydata1.create(fptr)
               Arraydata1.Header.updateKeyword(fptr,'SCANNUM','',iScanNo)
               Arraydata1.Header.updateKeyword(fptr,'OBSNUM','',isub)
               Arraydata1.Header.updateKeyword(fptr,'DATE-OBS','',dateObs)
               Arraydata1.Header.updateKeyword(fptr,'DATE-END','',dateEnd)
               if silent !=1: print 'Nphases= ',Nphases
               Arraydata1.Header.updateKeyword(fptr,'NPHASES','',Nphases)
               Arraydata1.Header.updateKeyword(fptr,'CHANNELS','',Nchannel*bePixels)
               Arraydata1.Header.updateKeyword(fptr,'TSTAMPED','',Tstamped)
               Arraydata1.Header.updateKeyword(fptr,'PHASEONE','',phaseOne)
               Arraydata1.Header.updateKeyword(fptr,'NORMALIZ','',True)
               firstData=0
            nelements=numRows
            firstrow=1;firstelem=1;nulval=0.0
            column=1 ## UT(C)
            secondsOfDay=pcfitsio.fits_read_col(fptrin,column,firstrow,firstelem,nelements,nulval)[:-1]
            outFrom=0;outTo=0;midnightTrace=False;afterMid=True
            for ii in range(numRows):
               if midnight:
                  if secondsOfDay[ii] < secondsFrom and secondsOfDay[ii] > 36000. : outFrom = ii+1 # 10 hours !
                  if secondsOfDay[ii] > secondsFrom and secondsOfDay[ii] <= 86400.:
                     outTo   = ii+1
                  elif secondsOfDay[ii] <= secondsTo:
                     outTo   = ii+1
               else:
                  if ii>0 and secondsOfDay[ii]<secondsOfDay[ii-1]:
                     midnightTrace=True
                     if outTo > 0:
                        afterMid=False
                     elif outFrom == 0:
                        outFrom=ii
                  if not midnightTrace:
                     if secondsOfDay[ii] < secondsFrom : outFrom = ii+1
                     if secondsOfDay[ii] <= secondsTo  : outTo   = ii+1
                  elif midnightTrace and afterMid:
                     if secondsOfDay[ii] < secondsFrom : outFrom = ii+1
                     if secondsOfDay[ii] <= secondsTo  : outTo   = ii+1

            #if silent !=1: print 'Original outFrom outTo ',outFrom,outTo
            notIn=0
            # If all traces have time stamps > MJDto
            if outFrom == 0 and outTo == 0 : continue
            if outFrom == 0 and outTo == 0 : notIn=1
            # If all traces have time stamps < MJDfrom CHECK
            if outTo-outFrom == 0 and outFrom == numRows-1 : notIn=1
            if outFrom == 0 and outTo > 0 : outFrom=1

            column=3; kPhase = pcfitsio.fits_read_col(fptrin,column,outFrom,firstelem,1,nulval)[:-1]
            nPhase=int(kPhase[0])
            #if silent !=1: print nPhase, '<<< nPhase '
            if nPhase == 0:
               sys.exit(1)
            if nPhase > 1:
               outFrom = outFrom-nPhase+1
            if (outTo-outFrom+1)%Nphases > 0: 
               outTo = outTo+(Nphases-(outTo-outFrom+1)%Nphases)            
            if outFrom < 1:
               outFrom=1
            if outTo > numRows:
               outTo=numRows
            #if silent !=1: print 'New outFrom outTo ',outFrom,outTo

   #BUG 20051102         if (outTo-outFrom) > 0:  If there is only one !
            if (outTo-outFrom) >= 0 and notIn == 0:
               for idap in range(outFrom,outTo+1):
                  column=1; UTCts = pcfitsio.fits_read_col(fptrin,column,idap,firstelem,1,nulval)[:-1]
                  if UTCts < UTCtsOld: midnight2=True
                  UTCtsOld=UTCts
                  column=2; integrationTimeOld = pcfitsio.fits_read_col(fptrin,column,idap,firstelem,1,nulval)[:-1]
                  column=3; kPhase = pcfitsio.fits_read_col(fptrin,column,idap,firstelem,1,nulval)[:-1]
                  ## BAD fix me: here firstelem needs to be set according to the "distribution setting"
                  ## E.g. if only B100,B230 are configured/used, firstelem=3 and Nchannel=2 to read continuum
                  ## channels 3 and 4 from the backend traces
                  ## firstelem=3    ##B100, B230 only Should be fixed now
                  #column=4; data_c = pcfitsio.fits_read_col(fptrin,column,idap,firstelem+2,Nchannel,nulval)[:-1]
                  column=4;data_c=[]
                  for ipart in range(1,NoofBEparts+1):
                     data_c = data_c+pcfitsio.fits_read_col(fptrin,column,idap,BackendParts[ipart-1],bePixels,nulval)[:-1]


                  ## Take the 2 Mhz counter normalized to 1 sec which is also in the Data (column 16)
                  column=4;integrationTime= [pcfitsio.fits_read_col(fptrin,column,idap,16,1,nulval)[:-1][0]/2000000.]
                  problem=(1.-integrationTimeOld[0]/integrationTime[0])
                  if math.fabs(problem)>0.002:
                     if silent !=1: print "Problem in 2KHz Counter",problem
                     
                  if not normalized:
                     for ii in range(Nchannel*bePixels):
                        data_c[ii] = int(round(float(data_c[ii])/integrationTime[0]))
                  Arraydata1.BinTable.addTableEntry(fptr,'INTEGNUM',[idap])

                  if midnight2 and midnight:
                     MJDs=sla.mjd(iYear,iMonth,iDay) + UTCts[0]/86400.
                  elif midnight:
                     MJDs=sla.mjd(iYear,iMonth,iDay) + UTCts[0]/86400. - 1.0
                  else:
                     MJDs=sla.mjd(iYear,iMonth,iDay) + UTCts[0]/86400.

                  Arraydata1.BinTable.subsTableEntry_dbl(fptr,'MJD',[MJDs])
                  Arraydata1.BinTable.subsTableEntry_dbl(fptr,'INTEGTIM',integrationTime)
                  Arraydata1.BinTable.subsTableEntry(fptr,'ISWITCH',kPhase)
                  Arraydata1.BinTable.subsTableEntry_dbl(fptr,'DATA',data_c)
                  status=pcfitsio.fits_close_file(fptrin) 
   ### Another Backend
      if ChosenBackend=='NIKA1mm' or ChosenBackend=='NIKA2mm':
         # Preparing to write the NIKA 1mm (iramA)  data NB Oct 2011 A is swapped with B i.e. now B is 1mm!!!      
         if ChosenBackend=='NIKA1mm':
            inDirBackend=DataRootDir+SDate+"/datastreams/NIKA/"
            NIKAfileStub='NIKA1iram-'+SDate+'-'
            NIKAfileStub=NIKAfileStub+"%i" % iScanNo
            NIKAfile=NIKAfileStub+'.fits'
            modeAccess=os.F_OK
            if os.access(inDirBackend+NIKAfile,modeAccess):
               if silent !=1: print 'Found:', NIKAfile,' from ',inDirBackend
            else:
               inDirBackend=DataRootDir+"datastreams/NIKA/"
               if os.access(inDirBackend+NIKAfile,modeAccess):
                  if silent !=1: print 'Found:', NIKAfile,' from ',inDirBackend
               else: # Midnight case
                  inDirBackend=DataRootDir+SDateBM+"/datastreams/NIKA/"
                  NIKAfileStub='NIKA1iram-'+SDateBM+'-'
                  NIKAfileStub=NIKAfileStub+"%i" % iScanNo
                  NIKAfile=NIKAfileStub+'.fits'
                  if os.access(inDirBackend+NIKAfile,modeAccess):
                     if silent !=1: print 'Found:', NIKAfile,' from ',inDirBackend
                  else:
                     if silent !=1: print 'Finally give up',inDirBackend,NIKAfile
                     sys.exit(1) # Finally give up
         # Preparing to write the NIKA 2mm (iramB)  data      
         if ChosenBackend=='NIKA2mm':
            inDirBackend=DataRootDir+SDate+"/datastreams/NIKA/"
            NIKAfileStub='NIKA2iram-'+SDate+'-'
            NIKAfileStub=NIKAfileStub+"%i" % iScanNo
            NIKAfile=NIKAfileStub+'.fits'
            modeAccess=os.F_OK
            if os.access(inDirBackend+NIKAfile,modeAccess):
               if silent !=1: print 'Found:', NIKAfile,' from ',inDirBackend
            else:
               inDirBackend=DataRootDir+"datastreams/NIKA/"
               if os.access(inDirBackend+NIKAfile,modeAccess):
                  if silent !=1: print 'Found:', NIKAfile,' from ',inDirBackend
               else: # Midnight case
                  inDirBackend=DataRootDir+SDateBM+"/datastreams/NIKA/"
                  NIKAfileStub='NIKA2iram-'+SDateBM+'-'
                  NIKAfileStub=NIKAfileStub+"%i" % iScanNo
                  NIKAfile=NIKAfileStub+'.fits'
                  if os.access(inDirBackend+NIKAfile,modeAccess):
                     if silent !=1: print 'Found:', NIKAfile,' from ',inDirBackend
                  else:
                     if silent !=1: print 'Finally give up',inDirBackend,NIKAfile
                     sys.exit(1) # Finally give up

         smallList=[inDirBackend+NIKAfile]
# Only one per scan
         prev=0;count=0
         # BUG no fractions for seconds !! 16.April 2014 as
#         timeFrom=subScanStart[0:8]
#         timeTo=subScanEnd[0:8]
         timeFrom=subScanStart[0:12]
         timeTo=subScanEnd[0:12]

         timeFromSI=timeFrom[:2] + timeFrom[3:5] + timeFrom[6:8]
         secondsFrom=(string.atoi(timeFrom[:2]) * 60 + string.atoi(timeFrom[3:5]))*60 + string.atoi(timeFrom[6:8])
         timeToSI=timeTo[:2] + timeTo[3:5] + timeTo[6:8]
         secondsTo=(string.atoi(timeTo[:2]) * 60 + string.atoi(timeTo[3:5]))*60 + string.atoi(timeTo[6:8])
         if silent !=1: print 'time(From,To)SI ',timeFromSI,timeToSI,secondsFrom,secondsTo
         # Optimal for 1 minute data-streams
         endSOD=secondsFrom-60.
         if endSOD<0:endSOD=0.0
         endH=int(endSOD/3600)
         endM=int((endSOD-endH*3600)/60)
         endS=endSOD-endH*3600-endM*60
         timeFromMSI="%02.2d%02.2d%06.3f" % (endH,endM,endS)
         MJDfrom=sla.mjd(iYear,iMonth,iDay)+((string.atoi(timeFrom[0:2])*60.+ string.atoi(timeFrom[3:5]))*60.+ string.atof(timeFrom[-6:])+0.0)/86400.
         MJDto=sla.mjd(iYear,iMonth,iDay)+((string.atoi(timeTo[0:2])*60.+ string.atoi(timeTo[3:5]))*60.+ string.atof(timeTo[-6:])+0.0)/86400.
         if midnight:MJDfrom=MJDfrom-1.0 #Fix me 20060908
         if silent !=1: print MJDfrom, MJDto,' NIKA backend'
         if silent !=1: print "Extended smallList ",smallList
   ## Now read and write the backend data
         firstData=1
         midnight2=False;UTCtsOld=0.0
         for infile in smallList:
            mode=0
            fptrin=pcfitsio.fits_open_file(infile,mode)
            pcfitsio.fits_movabs_hdu(fptrin,2)
            numCols=pcfitsio.fits_get_num_cols(fptrin)
            numRows=pcfitsio.fits_get_num_rows(fptrin)
            if firstData:
# First write a table with tuning information
               if NIKAConfigWrite:
                  pcfitsio.fits_movabs_hdu(fptrin,3)
                  numPixels=pcfitsio.fits_get_num_rows(fptrin)   # no. of rows gives number of pixels in data
                  if silent !=1: print 'numPixels ',numPixels ,'****************************************'
                  if numPixels != usedchan:
                     usedchan=numPixels
                     if silent !=1: print 'No. of pixel changed to ',numPixels
                     Febepar1.Header.updateKeyword(fptr,'NUSEFEED','',usedchan)
                     Febepar1.Header.updateKeyword(fptr,'FEBEFEED','',usedchan)
                     Febepar2.Header.updateKeyword(fptr,'NUSEFEED','',usedchan)
                     Febepar2.Header.updateKeyword(fptr,'FEBEFEED','',usedchan)
                  pcfitsio.fits_copy_hdu(fptrin,fptr,0)
                  pcfitsio.fits_movabs_hdu(fptrin,2)
# And back to the data table
                  NIKAConfigWrite=0
               normalized=True
               Nchannel=NoofBEpartsOut*usedchan
               ##imbfits_NIKA.ComClass.NCH=Nchannel*bePixels
               imbfits_NIKA.ComClass.NCH=usedchan
               if ChosenBackend=='NIKA1mm':
                  Arraydata1=imbfits_NIKA.Table('IMBF-backendNIKA1mm',Febepar1)
               if ChosenBackend=='NIKA2mm':
                  Arraydata1=imbfits_NIKA.Table('IMBF-backendNIKA2mm',Febepar1)
               Arraydata1.create(fptr)
               Arraydata1.Header.updateKeyword(fptr,'SCANNUM','',iScanNo)
               Arraydata1.Header.updateKeyword(fptr,'OBSNUM','',isub)
               Arraydata1.Header.updateKeyword(fptr,'DATE-OBS','',dateObs)
               Arraydata1.Header.updateKeyword(fptr,'DATE-END','',dateEnd)
               if silent !=1: print 'Nphases= ',Nphases
               Arraydata1.Header.updateKeyword(fptr,'NPHASES','',Nphases)
#               Arraydata1.Header.updateKeyword(fptr,'CHANNELS','',usedchan*bePixels)
               Arraydata1.Header.updateKeyword(fptr,'CHANNELS','',usedchan*NoofBEpartsOut)
               Arraydata1.Header.updateKeyword(fptr,'TSTAMPED','',Tstamped)
               Arraydata1.Header.updateKeyword(fptr,'PHASEONE','',phaseOne)
               Arraydata1.Header.updateKeyword(fptr,'NORMALIZ','',normalized)
               firstData=0
            nelements=numRows
            firstrow=1;firstelem=1;nulval=0.0
            column=2 ## MJD
            days1970=pcfitsio.fits_read_col(fptrin,column,firstrow,firstelem,nelements,nulval)[:-1]
            if silent !=1: print len(days1970),' Backend NIKA timestamps'
            outFrom=0;outTo=0;notIn=0
            for ii in range(numRows):
               MJDin=days1970[ii]
               if MJDin <  MJDfrom : outFrom = ii+1
               if MJDin <= MJDto   : outTo   = ii+1
            if silent !=1: print outFrom,outTo

            if (outTo-outFrom) >= 0 and notIn == 0:
               for idap in range(outFrom,outTo):
                  column=2; MJDts = float(pcfitsio.fits_read_col(fptrin,column,idap+1,1,1,nulval)[:-1][0])
                  data_r = []; data_i = []; data_q = []; data_di = []; data_dq = []; data_pf = []
                  data_r = pcfitsio.fits_read_col(fptrin,3,idap+1,1,usedchan,nulval)[:-1]
                  data_i = pcfitsio.fits_read_col(fptrin,4,idap+1,1,usedchan,nulval)[:-1]
                  data_q = pcfitsio.fits_read_col(fptrin,5,idap+1,1,usedchan,nulval)[:-1]
                  data_di = pcfitsio.fits_read_col(fptrin,6,idap+1,1,usedchan,nulval)[:-1]
                  data_dq = pcfitsio.fits_read_col(fptrin,7,idap+1,1,usedchan,nulval)[:-1]
                  data_pf = pcfitsio.fits_read_col(fptrin,8,idap+1,1,usedchan,nulval)[:-1]
# From Nov 2012 on we have a 9th column
                  data_ftone = pcfitsio.fits_read_col(fptrin,9,idap+1,1,usedchan,nulval)[:-1]
#                  if silent !=1: print idap+1,' data_r ',data_r
#                  if silent !=1: print idap+1,' data_i ',data_i
#                  if silent !=1: print idap+1,' data_q ',data_q

                  Arraydata1.BinTable.addTableEntry(fptr,'INTEGNUM',[idap+1])
                  Arraydata1.BinTable.subsTableEntry_dbl(fptr,'MJD',[MJDts])
                  Arraydata1.BinTable.subsTableEntry(fptr,'R',data_r)
                  Arraydata1.BinTable.subsTableEntry(fptr,'I',data_i)
                  Arraydata1.BinTable.subsTableEntry(fptr,'Q',data_q)
                  Arraydata1.BinTable.subsTableEntry(fptr,'DI',data_di)
                  Arraydata1.BinTable.subsTableEntry(fptr,'DQ',data_dq)
                  Arraydata1.BinTable.subsTableEntry(fptr,'PF',data_pf)
                  Arraydata1.BinTable.subsTableEntry(fptr,'FRES',data_ftone)
#                  Arraydata1.BinTable.subsTableEntry(fptr,'FTONE',data_ftone)
#                  pcfitsio.fits_movabs_hdu(fptrin,2) # Move back for MJD
                  status=pcfitsio.fits_close_file(fptrin)
      ## End of NIKA1mm NIKA2mm NIKA1 backend
   ### Another Backend

      if ChosenBackend=='NIKA':
#         if len(sys.argv)>3:
#            if silent !=1: print '>>',sys.argv[3],'<<'
#            rawFile=sys.argv[3]
#         from read_nika_data import *
#         silent=1
#         list_data='sample MJD I Q dI dQ F_tone k_flag RF_didq'
#         rawdata= read_nika_data(rawFile,silent,list_data)

         posSample=nup.where(rawdata.name_data_c =='sample')
         Sample=rawdata.data_common[posSample[0][0],0:rawdata.nb_samples]
#         if silent !=1: print Sample
         NoofBEpartsOut=8
         normalized=True
         numPixels=rawdata.data_detector.shape[1]
         usedRawchan=numPixels
         nb_samples=rawdata.nb_samples
         if silent !=1: print 'numPixels samples usedchan ',numPixels,nb_samples,usedchan
         imbfits_NIKA.ComClass.NCH=usedchan
         Arraydata1=imbfits_NIKA.Table('IMBF-backendNIKA',Febepar1)
         Arraydata1.create(fptr)
         # Update set some header variables
         Arraydata1.Header.updateKeyword(fptr,'SCANNUM','',iScanNo)
         Arraydata1.Header.updateKeyword(fptr,'OBSNUM','',OBSnum)
         Arraydata1.Header.updateKeyword(fptr,'DATE-OBS','',ScanDateObs)
         Arraydata1.Header.updateKeyword(fptr,'DATE-END','',ScanDateEnd)
         Arraydata1.Header.updateKeyword(fptr,'NPHASES','',Nphases)
         Arraydata1.Header.updateKeyword(fptr,'CHANNELS','',usedchan*NoofBEpartsOut)
         Arraydata1.Header.updateKeyword(fptr,'TSTAMPED','',Tstamped)
         Arraydata1.Header.updateKeyword(fptr,'PHASEONE','',phaseOne)
         Arraydata1.Header.updateKeyword(fptr,'NORMALIZ','',normalized)

         # No write the colums
#         outSample=[]
         possam = nup.where(rawdata.name_data_c =='sample')
         outSample =  rawdata.data_common[possam[0][0],0:rawdata.nb_samples]
         if silent !=1: print 'outSample ',outSample,
         if silent !=1: print outSample[0],outSample[nb_samples-1]
# MJD now
         posmjd = nup.where(rawdata.name_data_c =='MJD')
         posmjd = posmjd[0][0]
         mjd =  rawdata.data_common[posmjd,0:rawdata.nb_samples]
# referece clock A now
         posAutc = nup.where(rawdata.name_data_c =='A_t_utc')[0][0]
         Autc =  rawdata.data_common[posAutc,0:rawdata.nb_samples]
# referece clock B now
         posButc = nup.where(rawdata.name_data_c =='B_t_utc')[0][0]
         Butc =  rawdata.data_common[posButc,0:rawdata.nb_samples]
# referece clock C now
         posCutc = nup.where(rawdata.name_data_c =='C_t_utc')[0][0]
         Cutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
# and the others until U
         posCutc = nup.where(rawdata.name_data_c =='D_t_utc')[0][0]
         Dutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='E_t_utc')[0][0]
         Eutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='F_t_utc')[0][0]
         Futc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='G_t_utc')[0][0]
         Gutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='H_t_utc')[0][0]
         Hutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='I_t_utc')[0][0]
         Iutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='J_t_utc')[0][0]
         Jutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='K_t_utc')[0][0]
         Kutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='L_t_utc')[0][0]
         Lutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='M_t_utc')[0][0]
         Mutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='N_t_utc')[0][0]
         Nutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='O_t_utc')[0][0]
         Outc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='P_t_utc')[0][0]
         Putc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='Q_t_utc')[0][0]
         Qutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='R_t_utc')[0][0]
         Rutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='S_t_utc')[0][0]
         Sutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='T_t_utc')[0][0]
         Tutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
         posCutc = nup.where(rawdata.name_data_c =='U_t_utc')[0][0]
         Uutc =  rawdata.data_common[posCutc,0:rawdata.nb_samples]
# pps time data
         PPSt = rawdata.pps
         PPSdiff = rawdata.pps_diff
         
# I now
         If = get_nikavar_data(rawdata,'I')
#         posif = nup.where(rawdata.name_data_d =='I')
#         posif = posif[0][0]
#         If = rawdata.data_detector[posif,0:usedRawchan,0:rawdata.nb_samples]
# Q now
         Q = get_nikavar_data(rawdata,'Q')
#         posq = nup.where(rawdata.name_data_d =='Q')
#         posq = posq[0][0]
#         Q = rawdata.data_detector[posq,0:usedRawchan,0:rawdata.nb_samples]
# dI now
         dI = get_nikavar_data(rawdata,'dI')
#         posdi = nup.where(rawdata.name_data_d =='dI')
#         posdi = posdi[0][0]
         #dI = rawdata.data_detector[posif,0:usedRawchan,0:rawdata.nb_samples]
#         dI = rawdata.data_detector[posdi,0:usedRawchan,0:rawdata.nb_samples]
# dQ now
         dQ = get_nikavar_data(rawdata,'dQ')
#         posdq = nup.where(rawdata.name_data_d =='dQ')
#         posdq = posdq[0][0]
#         dQ = rawdata.data_detector[posdq,0:usedRawchan,0:rawdata.nb_samples]
# F_tone now
         ftone = get_nikavar_data(rawdata,'F_tone')

#         posft = nup.where(rawdata.name_data_d =='F_tone')
#         posft = posft[0][0]
#         ftone = rawdata.data_detector[posft,0:usedRawchan,0:rawdata.nb_samples]
# F_tone now  (not found !!)
#         posdft = nup.where(rawdata.name_data_d =='DF_tone')
#         if silent !=1: print 'posdft ',posdft
#         posdft = posdft[0][0]
#         dftone = rawdata.data_detector[posdft,0:usedRawchan,0:rawdata.nb_samples]
# k_flag
         k_flag = get_nikavar_data(rawdata,'k_flag')

#         poskf = nup.where(rawdata.name_data_d =='k_flag')
#         poskf = poskf[0][0]
#         k_flag = rawdata.data_detector[poskf,0:usedRawchan,0:rawdata.nb_samples]
# RF_didq
         RF = get_nikavar_data(rawdata,'RF_didq')
        
#         posrf = nup.where(rawdata.name_data_d =='RF_didq')
#         posrf = posrf[0][0]
#         RF = rawdata.data_detector[posrf,0:usedRawchan,0:rawdata.nb_samples]
         

#         if silent !=1: print RF[0],len(RF)
#         if silent !=1: print RF[2399][50:nb_samples]
## Determine the range of pixels used in given NIKAarray above
## Are there always 50 bad samples at the start of backend integration ??
         for iii in range(50,nb_samples):            
            Arraydata1.BinTable.addTableEntry(fptr,'INTEGNUM',[outSample[iii]])            
            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'MJD',[mjd[iii]])
            Iff=[];Qff=[];dIff=[];dQff=[];FTff=[];KFff=[];RFff=[]            
            for jjj in channelL:
               pos = (np.where(rawdata.kidpar['num'] == jjj))[0][0]
               Iff.append(If[pos][iii])
               Qff.append(Q[pos][iii])
               dIff.append(dI[pos][iii])
               dQff.append(dQ[pos][iii])
               FTff.append(ftone[pos][iii])
##             DFTff.append(dftone[jjj][iii])
               KFff.append(k_flag[pos][iii])
#18.04.17               RFff.append(RF[pos][iii])
#               Iff.append(If[jjj][iii])
#               Qff.append(Q[jjj][iii])
#               dIff.append(dI[jjj][iii])
#               dQff.append(dQ[jjj][iii])
#               FTff.append(ftone[jjj][iii])
##             DFTff.append(dftone[jjj][iii])
#               KFff.append(k_flag[jjj][iii])
#               RFff.append(RF[jjj][iii])
#            if silent !=1: print If[iii][:],iii
#            Iff=If[iii][:].tolist()
#            if silent !=1: print len(Iff)
            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'I',    Iff)
            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'Q',    Qff)
            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'DI',   dIff)
            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'DQ',   dQff)
            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'FTONE',FTff)
##          Arraydata1.BinTable.subsTableEntry_dbl(fptr,'DFTONE',DFTff)
            Arraydata1.BinTable.subsTableEntry(fptr,'KFLAG',KFff)
#18.04.17            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'R',    RFff)
#           Only 1 phase please 
            Arraydata1.BinTable.subsTableEntry(fptr,'ISWITCH',[1])
            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'PPS_t',[PPSt[iii]])
            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'PPS_diff',[PPSdiff[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'A_t_utc',[Autc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'B_t_utc',[Butc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'C_t_utc',[Cutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'D_t_utc',[Dutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'E_t_utc',[Eutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'F_t_utc',[Futc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'G_t_utc',[Gutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'H_t_utc',[Hutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'I_t_utc',[Iutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'J_t_utc',[Jutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'K_t_utc',[Kutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'L_t_utc',[Lutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'M_t_utc',[Mutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'N_t_utc',[Nutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'O_t_utc',[Outc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'P_t_utc',[Putc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'Q_t_utc',[Qutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'R_t_utc',[Rutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'S_t_utc',[Sutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'T_t_utc',[Tutc[iii]])
#            Arraydata1.BinTable.subsTableEntry_dbl(fptr,'U_t_utc',[Uutc[iii]])
         dir(rawdata)
         


         ### End the big loop data + traces





### END OF SUBSCAN LOOP





      expTime=expTime + string.atof(subs_timePerSubscan)
      subscansDone=isub
      if midnight:
         SDate=SDateM
         iYear =string.atoi(DatePart[:4])
         iMonth=string.atoi(DatePart[5:7])
         iDay  =string.atoi(DatePart[8:10])
         midnight=False
         midnightJP=False
## Query data base for table of Taus
#      ts = '2015-01-12 15:27:43'
      ts = ScanDateEnd[:10]+' '+ScanDateEnd[11:19]
      print "ts= ",ts 
      f = '%Y-%m-%d %H:%M:%S'
      newEndTime = datetime.datetime.strptime(ts, f)
#      ts = '2015-01-12 16:27:43'
#      newEndTime = datetime.datetime.strptime(ts, f)
      newStartTime = newEndTime - datetime.timedelta(minutes=120)
      newEndTime = newEndTime + datetime.timedelta(minutes=5)
      taus = getTau(newStartTime, newEndTime)
      print("I found %d taus in your query" % (len(taus)))
      print("This is the first tau found: %f with time %s" % (taus[0][0], taus[0][1]))
#      print("And now a list of all of the taus found:")
#      print()
#      print("Timestamp           Tau       Sigma    Fit     ")
#      print("---------           -------- -------- --------")
#      for t in taus:
#         print("%s %f %f %f" % (t[1], t[0], t[2], t[3]))
#      print()
      Datapar4=imbfits_NIKA.Table('IMBF-tau-225G',Febepar1)
      Datapar4.create(fptr)

      for t in range(0,len(taus)):
          Datapar4.BinTable.addTableEntry(fptr,'Tau225',[taus[t][0]])
          DTT="%s" % (taus[t][1])
          #print DTT[0:4],';',DTT[5:7],DTT[8:10],DTT[11:13],DTT[14:16],DTT[17:19]
          siteTime=string.atoi(DTT[11:13])*3600 + string.atoi(DTT[14:16])*60 + string.atoi(DTT[17:19])
          MJDTAU = sla.mjd(string.atoi(DTT[0:4]),string.atoi(DTT[5:7]),string.atoi(DTT[8:10]))+siteTime/86400.
          Datapar4.BinTable.subsTableEntry_str(fptr,'DATE',[DTT])
          Datapar4.BinTable.subsTableEntry(fptr,'MJD',  [MJDTAU])
          Datapar4.BinTable.subsTableEntry(fptr,'Sigma',[taus[t][2]])
          Datapar4.BinTable.subsTableEntry(fptr,'Fit',  [taus[t][3]])
      



   ## Final: Update some of the main header keywords
      pcfitsio.fits_movabs_hdu(fptr,1) # Primary Header
      pcfitsio.fits_update_key(fptr,'EXPTIME',expTime,'Total netto integration time [s]')
      pcfitsio.fits_update_key(fptr,'N_OBS',subscan_range,'No of subscans defined')
      pcfitsio.fits_update_key(fptr,'N_OBSP',subscansDone,'No of subscans found')
      pcfitsio.fits_update_key(fptr,'LONGOBJ',LongObject,'[deg] Source longitude in basis frame')
      pcfitsio.fits_update_key(fptr,'LATOBJ',LatObject,'[deg] Source latitude in basis frame')
      pcfitsio.fits_update_key(fptr,'LST',doLST,'[s] Local apparent sidereal time (scan start)')
      pcfitsio.fits_update_key(fptr,'OBSTYPE',observingMode,'')
      pcfitsio.fits_update_key(fptr,'NUSEFEED',usedchan,'')
      pcfitsio.fits_movabs_hdu(fptr,2) # IMBF-scan header
      pcfitsio.fits_update_key(fptr,'EXPTIME',expTime,'Total netto integration time [s]')

   # finished
# Revise the below!
#   nTables=4*subscansDone + 5
#   totAnts=0;totAntf=0;totSubr=0;totBackend=0
#   for nT in range(5,nTables+1):
#      naxis0=0;naxis1=0;naxis2=0
#      pcfitsio.fits_movabs_hdu(fptr,nT)
#      naxis0=string.atoi(pcfitsio.fits_read_keyword(fptr,'NAXIS')[0])
#      WichExt=pcfitsio.fits_read_keyword(fptr,'EXTNAME')[0]
#      if naxis0>1:
#         naxis1=string.atoi(pcfitsio.fits_read_keyword(fptr,'NAXIS1')[0])
#         naxis2=string.atoi(pcfitsio.fits_read_keyword(fptr,'NAXIS2')[0])
#         if WichExt[1:15]=='IMBF-antenna-s':
#            totAnts=totAnts + naxis2
#         if WichExt[1:15]=='IMBF-antenna-f':
#            totAntf=totAntf + naxis2
#            if silent !=1: print 'Cumulative Lines antenna slow, fast : ',totAnts,totAntf
#         if WichExt[1:13]=='IMBF-subrefl':
#            totSubr=totSubr + naxis2
#         if WichExt[1:13]=='IMBF-backend':
#            totBackend=totBackend + naxis2
#   if silent !=1: print 'Cumulative Line count tot : ',totAnts,totAntf,totSubr,totBackend         
#   pcfitsio.fits_movabs_hdu(fptr,1) # Main header
#   pcfitsio.fits_update_key(fptr,'TOTANTS',totAnts,'Total no. of LINES in antenna tables')
#   pcfitsio.fits_update_key(fptr,'TOTANTF',totAntf,'Total no. of LINES in antenna tables')
#   pcfitsio.fits_update_key(fptr,'TOTSUBR',totSubr,'Total no. of LINES in secondary tables')
#   pcfitsio.fits_update_key(fptr,'TOTBACK',totBackend,'Total no. of LINES in backenddata tables')

   OutFITSfile.close()
   syncMsg.close()
   if zeroData:
      #Does not work logger.ncsMonitor(logId="dpCS:makeIMBFits data.bad ",
      logger.ncsMonitor(logId="scanInfo:makeIMBFits data.bad ",
                        msg="Zero in data",
                        data={"scanId": scanId, "backend":ChosenBackend})
   if offLine:
      logger.ncsMonitor(logId="scanInfo:makeIMBFitsDone",
                        data={"scanId": scanId})
   else:
      if silent !=1: print 'Reached end of script NIKAIMBFITS'

   return
