;;===============================================================
;;           Name: NGC3351
;;           Run: 10
;;           Extended: yes
;;           Flux peak: a few 10 mJy
;;           Target description: 
;;                Long scan across galaxy
;;===============================================================
 
pro ngc3351_op2
;;------- Properties of the source to be given here ------------------
source = 'NGC3351'                                    ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;------- Prepare output directory for plots and logbook --------------
;; output_dir = !nika.plot_dir+'/'+source
;; spawn, "mkdir -p "+output_dir

;;------- Scans --------------
;; scan_num1 = [578,579,580,581,582,583,584,585,586,587,588,589,590,591,592,593,594,595,596,597,598,599,600,601,602,603,604,605,606,607,608,609,610,611,612,613,614,615,616,617,618,619,620,621,622,623,624,625,626,627,628,629,630,631,632,633,634,635,636,637,638,639,640,641,642,643,644,645,646,647,648,649,650,651,652,653,654,655,656,657,658,659,660,661,662,663,664,665,666,667,668,669,670,671,672,673,674,675,676,677,678,679,680,681,682,683,684,685,689,690,691,692,693,694,695,696,697,698,699,700,701,702,703,704,705,706,707,708,709,710,711,712,713,714,715,716,717,718,719,720,721,722,723,724,725,726,727,728,729,730,731,732,733,734,735,736,737,738,739,740,741,742,743,744,745,746,747,748,749,750,751,752,753,754,755,756,757,758,759,760,761,762,763,764,765,766,767,768,769,770,771,772,773,774,775,776,777,778,779,780,781,782,783,784,785,786,787,788,789,790,791,792,793,794,795,796,800,801,802,803,804,805,806,807,808,809,810,811,812,813,814,815,816,817,818,819,820,821,822,823,824,825,826,827,828,829,830,831,832,833,834,835,836,837,838,839,840,841,842,843,844,845,846,847,848,849,850,851,852,853,854,855,856,857,858,859,860,861,862,863,864,865,866,867,868,869,870,871,872,873,874,875,876,877,878,879,880,881,882]
;; day1 = '20141117'+strarr(n_elements(scan_num1))
;; scan_num2 = [001,002,003,004,005,006,007,008,009,010,011,012,013,014,015,016,017,018,019,020,021,022,023,024,029,030,031,032,033,034,035,036,037,038,039,040,041,042,043,044,045,046,047,048,049,050,051,052,053,054,055,056,057,058,059,060,061,062,063,064,065,066,067,068,069,070,071,072,073,074,075,076,077,078,079,080,081,082,083,084,085,086,087,088,089,090,091,092,093,094,095,096,097,098,099,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136]
;; day2 = '20141118'+strarr(n_elements(scan_num2))

;; scan_num = [scan_num1]
;; day = [day1]

thisprojid = '098-14'
output_dir = !nika.plot_dir+'/OpenPool2/'+thisprojid+'/'+source+'/' 
thissource = source
get_scans_from_database,thisprojid ,thissource , day ,scan_num, info=info
outdir = output_dir+'iter0/'
spawn, "mkdir -p "+outdir


;;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param
param.source = source
;param.coord_map = {ra:[1.0,36.0,42.0], dec:[15.0,47.0,1.0]}
param.name4file = name4file
param.version = version
param.output_dir = outdir

param.map.reso = 5
param.map.size_ra = 1000
param.map.size_dec = 1000

param.filter.apply = 'yes'
param.filter.freq_start = 1.0
param.filter.nsigma = 4

param.decor.method = 'COMMON_MODE'
param.decor.common_mode.d_min = 0.0
param.decor.common_mode.per_subscan = 'no'
param.decor.common_mode.median = 'yes'
param.decor.common_mode.nsig_bloc = 1.0
param.decor.common_mode.nbloc_min = 30
param.fit_elevation = 'yes'
param.decor.baseline = [3,1]

param.w8.per_subscan = 'no'
param.w8.dist_off_source = 0.0
param.zero_level.per_subscan = 'no'
param.zero_level.dist_off_source = 0.0

param.flag.uncorr = 'no'

;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, $
                  use_noise_from_map=1, $
                  ps=1, clean=1, check_flag_speed=1,$
                  check_flag_cor=0, meas_atm=1, plot_decor_toi=1,check_toi_in=0, $
                  noskydip=1, multi=0, nocut=1

; check for bad scans 
nika_pipe_check_scan_flag, param

;;------- 2 Launch the pipeline by reiteration
param.decor.method = 'COMMON_MODE_KIDS_OUT'
param.decor.common_mode.map_guess1mm = outdir+'/MAPS_1mm_'+name4file+'_'+version+'.fits'
param.decor.common_mode.map_guess2mm = outdir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.w8.map_guess1mm = outdir+'/MAPS_1mm_'+name4file+'_'+version+'.fits'
param.w8.map_guess2mm = outdir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.zero_level.map_guess1mm = outdir+'/MAPS_1mm_'+name4file+'_'+version+'.fits'
param.zero_level.map_guess2mm = outdir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.w8.flag_lim = [3,3]
param.zero_level.flag_lim = [3,3]
param.decor.common_mode.flag_lim = [3,3]

outdir = output_dir+'iter1/'
param.output_dir = outdir
spawn, 'mkdir -p ' + outdir
param.logfile_dir = outdir 

nika_pipe_launch, param, map_combi, map_list, $
                  use_noise_from_map=1, $
                  check_flag_cor=1, check_flag_speed=1, meas_atm=1, plot_decor_toi=1, ps=1, clean=1, $
                  noskydip=1, multi=1

;;------- Analysis after the pipeline
restore, outdir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10
anapar.flux_map.noise_max = 2
anapar.snr_map.relob.a = 10
anapar.snr_map.relob.b = 10

nika_anapipe_launch, param, anapar

return
end
