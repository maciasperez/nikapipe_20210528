import xmlrpclib
import numpy as np
import time 
from astropy.table import Table, Column

xmlserver = xmlrpclib.ServerProxy('https://tapas.iram.es/tapas/xml_rpc')

def get_scans_from(year,month,day):
        """
        Find out scans given day
        
        """
        year = str(year)
        month = str(month).zfill(2)
        day   = str(day).zfill(2)
        mdate = year+'-'+month+'-'+day
        bdata = mdate+'T00:00:00'
        edata = mdate+'T23:59:59'
        scans= xmlserver.getNikaScansByParams('t22', '30m/kitu/t22', bdata, edata,"",0, 1, "")
        return scans


def get_today_scans():
        """
        Find out scans for today.
        
        """
        mlocal = time.localtime()
        year = str(mlocal.tm_year)
        month = str(mlocal.tm_mon).zfill(2)
        day   = str(mlocal.tm_mday).zfill(2)
        mdate = year+'-'+month+'-'+day
        bdata = mdate+'T00:00:00'
        edata = mdate+'T23:59:59'
        scans= xmlserver.getNikaScansByParams('t22', '30m/kitu/t22', bdata, edata,"",0, 1, "")
        return scans

        
def get_run_scans(run=0,n2run=0,source='',scantype='',opamin=0.0,opamax=1.0,user = 't22'):
        bdata = '2016-03-11T00:00:00'
        edata = '2018-02-20T23:59:59'

#    4th test run of NIKA2: 1-March-2016 till 15-March-2016. Continue tests started with previous runs, in particular investigate deeper beam patterns (XY focus, beam maps), synchronization, 
# array 1 & 3 performances vs electronic boards, NEFD, mapping strategies. [= Run 16 of a NIKA instrument]
	if (run ==16) or (n2run==4):
		bdata = '2016-03-11T00:00:00'
		edata = '2016-03-15T23:59:59'
#

#    Dark run: 4-May-2016. Test sensitivity of NIKA2 to external electromagnetic perturbations, 
#    with the entrance window of the cryostat closed. [= Run 17 of a NIKA instrument]
	if (run ==17):
		bdata = '2016-05-04T00:00:00'
		edata = '2016-05-04T23:59:59'

#    5th test run of NIKA2: 16-September-2016 till 11-October-2016. Upgrade NIKA2 with new dichroic, 
#new corrugated lenses and window, new 2mm array, new NIKEL boards (get the 20 lines with homogeneous electronics, v3); 
#redo better the tests started with previous runs (mostly beam maps in best weather conditions, but also various types of 
#scan to investigate deeper beams and noise, synchronization, NEFD, skydips, mapping strategies, possibly polarization. 
#[= Run 18 of a NIKA instrument]
	if (run ==18) or (n2run==5):
		bdata = '2016-09-16T00:00:00'
		edata = '2016-10-11T23:59:59'


#    6th test run of NIKA2: 25-October-2016 till 1-November-2016. Continue NIKA2 commissioning. [= Run 19 of a NIKA instrument]
	if (run ==19) or (n2run==6):
		bdata = '2016-10-25T00:00:00'
		edata = '2016-11-01T23:59:59'


#    7th test run of NIKA2: 6-December-2016 till 13-December-2016. Continue NIKA2 commissioning. [= Run 20 of a NIKA instrument]

	if (run ==20) or (n2run==7):
		bdata = '2016-12-06T00:00:00'
		edata = '2016-12-13T23:59:59'

        if (run ==21) or (n2run==8):
                bdata = '2017-01-23T00:00:00'
                edata = '2017-01-27T23:59:59'
                
	if (run ==22) or (n2run==9):
		bdata = '2017-02-21T00:00:00'
		edata = '2017-02-28T23:59:59'

        if (run ==23) or (n2run==10):
		bdata = '2017-04-14T00:00:00'
		edata = '2017-04-25T23:59:59'

        if (run ==25) or (n2run==12):
		bdata = '2017-10-18T00:00:00'
		edata = '2017-11-03T23:59:59'

#        if (run ==26) or (n2run==13):
#		bdata = '2017-10-18T00:00:00'
#		edata = '2017-11-03T23:59:59'
                
        if (run ==27) or (n2run==14):
		bdata = '2018-01-16T00:00:00'
		edata = '2018-01-23T23:59:59'

        if (run ==28) or (n2run==15):
		bdata = '2018-02-13T00:00:00'
		edata = '2018-02-20T23:59:59'

        if (run ==30) or (n2run==17):
		bdata = '2018-03-13T00:00:00'
		edata = '2018-03-20T23:59:59'


        if user == 't22':
                scans= xmlserver.getNikaScansByParams('t22', '30m/kitu/t22', bdata, edata, scantype, opamin, opamax, source)
 
        elif user == 'nikas-17':
                scans= xmlserver.getNikaScansByParams('nikas-17', '30m/mebi/nik', bdata, edata, scantype, opamin, opamax, source)
 
        else:
                return -1

	return scans

def select_nika_scan_type(scans,nika_type,silent=0, reverse=0):

#okscans = filter(lambda scan: scan['type'] == 'lissajous', scans)
#okscans = filter(lambda scan: scan['ncsId'] == '20161009s69', scans)
#selscans = filter(lambda scan: scan['rxConfigurations'][0]['rxBoloCfg'][0]['nikaOM'] == 'beammap1',scans)
        if reverse == 0:
	        selscans = filter(lambda sc: sc['rxConfigurations'][0]['rxBoloCfg'][0]['nikaOM'] == nika_type,scans)
        else:
	        selscans = filter(lambda sc: sc['rxConfigurations'][0]['rxBoloCfg'][0]['nikaOM'] != nika_type,scans)
                
        if silent ==0:
                for scan in selscans:
        #		print scan
                        comment = scan['comment']

                        if len(comment) == 0:
                                comments = ''
                        else:
                                comments=''
                                for index in range(len(comment)):
                                         comments = comments + ' '+comment[index].replace('\n',' ')
 
                        print '|| ' + scan['ncsId']+ ' ||  '+ scan['sourceName'][0] + ' || '+ comments + ' ||'

 
	scanlist = []
	for scan in selscans:
		scanlist.append((scan['ncsId'].replace('.','s')).replace('-',''))
	return selscans, scanlist


def select_nika_scan_comment(scans,mcomment):

	''' Find comments '''
        mcomment = np.str(mcomment)
	scan_list = []
	mtt=[]
	for tt in scans:
                comment = tt['comment']
                if len(comment) >0:
                        for il in range(len(comment)):
                                st = np.str(comment[il])
                if len(comment) >0:
                        st = np.str(comment[0])
                       # print st
                        if st.upper().find(mcomment.upper()) > -1:
                                mtt.append(tt)
                                scan_list.append( (tt['ncsId'].replace('.','s')).replace('-',''))
                                print st
                               # print st
                                if st.upper().find(mcomment) > -1:
                                        mtt.append(tt)
                                        scan_list.append( (tt['ncsId'].replace('.','s')).replace('-',''))
                                        print st
                        

	return mtt,scan_list

def select_nika_scan_time(scans,start_time, end_time):

	''' Find comments 
            start_time : starting time
                         numpy string, format (01:22:20)
            end_time   : ending time 
                         numpy string, format (01:22:20)
        '''
	scan_list = []
	mtt=[]
        stime = np.long(start_time.replace(':',''))
        etime = np.long(end_time.replace(':',''))
	for tt in scans:
		day,st = np.str(tt['startTime']).split()
                st = np.long(np.str(st.replace(':','')))
                if stime < etime:
                        if (st >= stime) & (st <= etime):
                                mtt.append(tt)
                                scan_list.append( (tt['ncsId'].replace('.','s')).replace('-',''))                                
                else:
                        if (st >= etime) & (st <= stime):
                                continue
                        else:
                                mtt.append(tt)
                                scan_list.append( (tt['ncsId'].replace('.','s')).replace('-',''))                                
                        

	return mtt,scan_list

def write_scanlist(scan_list,filename):
        '''
        Write scanlist into txt file that can be used in IDL for example
        '''
        np.savetxt(filename,scan_list,delimiter='\n',fmt='%s')
        return


def write_database_file(mrun,source,writefile=0):
        '''
        write database file for Jean-Francois
        '''
	runscans = get_run_scans(run=mrun,source=source)

        res = {'date':[],'time':[],'scan':[],'sourceName':[],'nikatype':[],'ele':[],'tau':[], 'fZ':[],'comments':[]}
        

#        ff = open('run'+str(run)+'_db.txt', 'wb')
        
        for rf in runscans:
                comment=''
                if len(rf['comment']) > 0:
                        for idx in range(len(rf['comment'])):
                                         comment+= (rf['comment'][idx].strip())
                else:
                        comment += 'None'
                comment = comment.strip()        
                nikatype = rf['rxConfigurations'][0]['rxBoloCfg'][0]['nikaOM']
                mtype=rf['type']

                if (mtype != 'track') & (mtype != 'DIY'):
                        date,scan =  rf['ncsId'].replace('.',' ').split()
                        scan =(rf['ncsId'].replace('.','s')).replace('-','')
                        res['date'].append(date)
                        res['time'].append( rf['startTime'].split()[1])
                        res['scan'].append(scan)
                        res['sourceName'].append(rf['sourceName'][0])
                        res['nikatype'].append(nikatype)
                        res['ele'].append(rf['el'][0])
                        res['tau'].append(rf['tau'])
                        res['fZ'].append(rf['fZ'][0])
                        comment = rf['comment']
                        if len(comment) == 0:
                                comments = ''
                        else:
                                comments=''
                                for index in range(len(comment)):
                                         comments = comments + ' '+comment[index].replace('\n',' ')
                        res['comments'].append(comments)
                        
#                       print date+" \t "+ rf['startTime'].split()[1]+"\t" +scan+" \t "+rf['sourceName'][0]+" \t" +nikatype +"\t" +str(rf['tau'])+" \t" + str(rf['fZ'][0])  +" \t "+comment
#                       ff.write(date+" \t "+ rf['startTime'].split()[1]+"\t" +scan+" \t "+rf['sourceName'][0]+" \t" +nikatype +"\t" +str(rf['tau'])+" \t" + str(rf['fZ'][0])  +"\n")
        c_date = Column(name='date',data=np.array(res['date']))
        c_time = Column(name='time',data=np.array(res['time']))
        c_scan = Column(name='scan',data=np.array(res['scan']))
        c_sour = Column(name='sourceName',data=np.array(res['sourceName']))
        c_nikt = Column(name='nikatype   ',data=np.array(res['nikatype']))
        c_ele  = Column(name=' Elev   ',data=np.array(res['ele']),format='4.1f')
        c_tau  = Column(name=' tau225 ',data=np.array(res['tau']),format='4.2f')
        c_fZ   = Column(name=' fZ ',data=np.array(res['fZ']),format='5.2f')
        c_comment   = Column(name='comment',data=np.array(res['comments']))

        mt = Table()
        mt.add_columns([c_date,c_time,c_scan,c_sour,c_nikt,c_ele,c_tau,c_fZ,c_comment])
        mt.pprint(align = '<', max_lines = -1)
        if writefile == 1:
                taba=mt.pformat(align = '<', max_lines = -1)
                ff = open('run'+str(mrun)+'_db.txt', 'w')
                ff.write('\n'.join(taba))

        return mt


if __name__ == '__main__':
	''' Example of use '''
        import get_nika_scans as gns
        import hfits
        import numpy as np 
	runscans = gns.get_run_scans(run=23,source='')
	runscans = gns.get_run_scans(run=25,source='',user='nikas-17')
        runscans = gns.get_run_scans(run=25,source='',user='t22')

        mdb = gns.write_database_file(30,'Uranus')
        mdb.pprint(align = '<', max_lines = -1)

	runscans = gns.get_run_scans(run=30)
        
        rfs,rfslist = gns.select_nika_scan_type(runscans,'skydip')
        for rf in rfs:
                comment=''
                if len(rf['comment']) > 0:
                        for idx in range(len(rf['comment'])):
                                         comment+= rf['comment'][idx]
                date,scan =  rf['ncsId'].replace('.',' ').split()
                print "|| "+date+" || "+scan+" || "+str(rf['tau'])+" || "+ rf['startTime'].split()[1]+" || "+comment+" ||"
                                         

        rfs,rfslist = gns.select_nika_scan_type(runscans,'beammap')
        for rf in rfs:
                comment=''
                if len(rf['comment']) > 0:
                        for idx in range(len(rf['comment'])):
                                         comment+= rf['comment'][idx]
                scan =  rf['ncsId'].replace('-','').replace('.','s')
                sname = rf['sourceName'][0]
                dum,time = rf['startTime'].split()
                elev = str(rf['el'][0])
                tau = str(rf['tau'])
                print "|| "+scan+" || "+sname+" || "+time+" || "+ elev +" || "+ " tau: "+tau+" "+comment+" ||  ||  ||  ||"
       
        
	rfs,rfslist = gns.select_nika_scan_type(runscans,'focusOTF-Z')
        
                
        
        runscans = gns.get_run_scans(run=28,source='MWC349',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        
        runscans = gns.get_run_scans(run=28,source='PSZ2-G160.8',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')

        runscans = gns.get_run_scans(run=28,source='PSZ2-G086.9',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        el = []
        tau= []
        for rf in rfs:
                el.append(rf['el'][0])
                tau.append(rf['tau'])
        el = np.array(el)
        tau = np.array(tau)
        
        runscans = gns.get_run_scans(run=27,source='',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN27/allotfs_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)

        runscans = gns.get_run_scans(run=25,source='PSZ2-G091.8',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
 

        runscans = gns.get_run_scans(run=27,source='ACTCLJ0215',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')

        runscans = gns.get_run_scans(run=27,source='PSZ2-G099.8',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')

        runscans = gns.get_run_scans(run=27,source='PSZ2-G183.9',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')


        runscans = gns.get_run_scans(run=27,source='PSZ2-G201.5',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')

        runscans = gns.get_run_scans(run=27,source='PSZ2-G211.2',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')

        runscans = gns.get_run_scans(run=27,source='PSZ2-G228.1',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')

        

        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/G2_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)
        
        runscans = gns.get_run_scans(run=25,source='',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/allotfs_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)

        runscans = gns.get_run_scans(run=25,source='G2',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/G2_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)

        runscans = gns.get_run_scans(run=25,source='JINGLE_D1',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/JINGLE_D1_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)

        
        runscans = gns.get_run_scans(run=25,source='JKCS041',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/JKCS041_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)

        runscans = gns.get_run_scans(run=25,source='Vega',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/Vega_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)

        
        runscans = gns.get_run_scans(run=25,source='MGE042',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/MGE042_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)

        runscans = gns.get_run_scans(run=25,source='MGE027',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/MGE027_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)

        runscans = gns.get_run_scans(run=25,source='PSZ2-G201.5',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/PSZ2G201_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)
        
        runscans = gns.get_run_scans(run=25,source='PSZ2-G091.8',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/PSZ2G091_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)

        runscans = gns.get_run_scans(run=25,source='PSZ2-G046.1',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/PSZ2G046_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)

         

        runscans = gns.get_run_scans(run=25,source='Uranus',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'beammap')
        
        runscans = gns.get_run_scans(run=25,source='Mars',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'beammap')

        runscans = gns.get_run_scans(run=25,source='MWC349',user = 'nikas-17')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
                    
        rfs,rfslist = gns.select_nika_scan_type(runscans,'beammap')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
	rfs,rfslist = gns.select_nika_scan_type(runscans,'focusOTF-Z')
	rf1s,rf1slist = gns.select_nika_scan_comment(rfs,np.str('1/5'))
        rf1s,rf1slist = gns.select_nika_scan_time(runscans,'00:00:00','08:00:00')
        write_scanlist(rfslist,'scanlist.txt')
        runscans = gns.get_run_scans(run=23,source='NGC7027')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN23/ngc7027_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)
        runscans = gns.get_run_scans(run=23,source='CRL2688')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN23/crl2688_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)
        runscans = gns.get_run_scans(run=23,source='MWC349')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN23/mwc349_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)
        runscans = gns.get_run_scans(run=23,source='M99')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN23/m99_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)
        runscans = gns.get_run_scans(run=23,source='PSZ2-G144.8')
        rfs,rfslist = gns.select_nika_scan_type(runscans,'nkotf ')
        file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN23/m99_scans.fits'
        hfits.arr2fits(np.array(rfslist),'scans',file)
        rfs1,rfslist1 = gns.select_nika_scan_type(runscans,'beammap')
        file =  '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN23/beammap_scans.fits'
        hfits.arr2fits(np.array(rfslist1),'scans',file)
        rfs2,rfslist2 = gns.select_nika_scan_type(runscans,'nkotf ')
        file =  '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN23/nkotf_scans.fits'
        hfits.arr2fits(np.array(rfslist2),'scans',file)
        
        rfs3,rfslist3 = gns.select_nika_scan_comment(runscans,'Dark')
        file =  '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN23/dark_scans.fits'
        hfits.arr2fits(np.array(rfslist3),'scans',file)
                        
	rfs4,rfslist4 = gns.select_nika_scan_type(runscans,'focusOTF-Z')
	rfs5,rfslist5 = gns.select_nika_scan_type(runscans,'focusOTF-X')
        for scan in rfslist5:
                rfslist4.append(scan)
	rfs6,rfslist6 = gns.select_nika_scan_type(runscans,'focusOTF-Y')
        for scan in rfslist6:
                rfslist4.append(scan)
        
        file =  '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN23/focus_scans.fits'
        hfits.arr2fits(np.array(rfslist4),'scans',file)

        rfs3,rfslist3 = gns.select_nika_scan_comment(runscans,'failure')
        rfs3,rfslist3 = gns.select_nika_scan_comment(runscans,'error')
        rfs3,rfslist3 = gns.select_nika_scan_comment(runscans,'CANCELLED')
        file =  '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN23/badcancelled_scans.fits'
        hfits.arr2fits(np.array(rfslist3),'scans',file)
                        
 
