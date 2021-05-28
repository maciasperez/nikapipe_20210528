 ;;===============================================================
;;           Name: IC10
;;           Run: 10
;;           Extended: yes
;;           Flux peak: a few 10 mJy
;;           Target description: 
;;                Dwarf galaxies
;;===============================================================
 
pro ic10_op2
;;------- Properties of the source to be given here ------------------
source = 'IC10'                                    ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;------- Prepare output directory for plots and logbook --------------
;; output_dir = !nika.plot_dir+'/Dwarf_Galaxies/'+source
;; spawn, "mkdir -p "+output_dir

;; ;;------- Scans --------------
 scan_num1 = [468,471,472,473,474,475,476,477,478,479,483,484,485,486,487] ;,469,470
 scan_num2 = [01,02,03,04,05,06,07,16,17,18,19,20,21,22,23,24]
 scan_num3 = [21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38]
 day1 = '20141118'+strarr(n_elements(scan_num1))
 day2 = '20141119'+strarr(n_elements(scan_num2))
 day3 = '20141120'+strarr(n_elements(scan_num3))

 scan_num = [scan_num1, scan_num2]
 day = [day1, day2]

thisprojid = '097-14'
output_dir = !nika.plot_dir+'/OpenPool2/'+thisprojid+'/'+source+'/' 

thissource = source
;get_scans_from_database,thisprojid ,thissource , day ,scan_num, info=info
outdir = output_dir+'/iter0/'
spawn, "mkdir -p "+outdir


;;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param
param.source = source
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
param.decor.common_mode.per_subscan = 'yes'
param.decor.common_mode.median = 'yes'
param.decor.common_mode.nsig_bloc = 1.0
param.decor.common_mode.nbloc_min = 30
param.fit_elevation = 'yes'
param.decor.baseline = [1,1]

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 0.0
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 0.0

param.flag.uncorr = 'yes'


;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, $
                  use_noise_from_map=1, $
                  ps=1, clean=1, check_flag_cor=1,$
                  meas_atm=1, $
                  plot_decor_toi=1, $
                  noskydip=0, multi=0, /make_products
;nika_pipe_check_scan_flag, param

;;------- 2 Launch the pipeline by reiteration
param.decor.method = 'COMMON_MODE_KIDS_OUT'
param.decor.common_mode.map_guess1mm = outdir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.decor.common_mode.map_guess2mm = outdir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.w8.map_guess1mm = outdir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.w8.map_guess2mm = outdir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.zero_level.map_guess1mm = outdir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.zero_level.map_guess2mm = outdir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.w8.flag_lim = [3,3]
param.zero_level.flag_lim = [3,3]
param.decor.common_mode.flag_lim = [5,5]

outdir = output_dir+'iter1/'
param.output_dir = outdir
spawn, 'mkdir -p ' + outdir
param.logfile_dir = outdir 

nika_pipe_launch, param, map_combi, map_list, $
                  use_noise_from_map=1, $
                  check_flag_cor=0, check_flag_speed=0, meas_atm=0, plot_decor_toi=0, ps=1, clean=1, $
                  noskydip=1, multi=1

;;------- Analysis after the pipeline
restore, outdir+'/param_'+name4file+'_'+version+'.save', /verb
;nika_pipe_check_scan_flag, param

nika_anapipe_default_param, anapar

anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10
anapar.snr_map.relob.a = 10
anapar.snr_map.relob.b = 10

nika_anapipe_launch, param, anapar

return
end
