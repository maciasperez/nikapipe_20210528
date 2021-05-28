;;===============================================================
;;           Name: G34.3
;;           Run: 10
;;           Extended: ??
;;           Flux peak: a few ??  mJy
;;           Target description: 
;;                Core
;;===============================================================
 
pro g34_4_op2
;;------- Properties of the source to be given here ------------------
source = 'G34.3'                               ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;------- Prepare output directory for plots and logbook --------------
;; output_dir = !nika.plot_dir+'/Core_NKGT/'+name4file
;; spawn, "mkdir -p "+output_dir

;; ;;------- Scans --------------
;; scan_num1 = [318,319,320,321,322,323,324,325,326,327,328,329,330, 331,332,334,335,336,337,338,339,340,341]
;; day1 = '20141116'+strarr(n_elements(scan_num1))

;; scan_num = [scan_num1]
;; day = [day1]

output_dir = !nika.plot_dir+'/OpenPool2/047-14/'+source+'/' 

thisprojid = '047-14'
thissource = source
get_scans_from_database,thisprojid ,thissource , day ,scan_num, info=info

day_remove=['20141117']
scan_num_remove=[323]
remove_bad_scans,scan_num,day,scan_num_remove,day_remove


outdir = output_dir+'iter0/'
spawn, "mkdir -p "+outdir



;;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param
param.source = source
param.logfile_dir = outdir
; pointing from IMBFITSFILES
;; param.coord_pointing = {ra:[90.0,0.0,0.0], dec:[90.0,0.0,0.0]}
;; param.coord_map = {ra:[90.0,0.0,0.0], dec:[90.0,0.0,0.0]}
;; param.coord_source = {ra:[90.0,0.0,0.0], dec:[90.0,0.0,0.0]}
param.name4file = name4file
param.version = version
param.output_dir = outdir

param.map.reso = 2
param.map.size_ra = 400
param.map.size_dec = 400

param.filter.apply = 'yes'
param.filter.freq_start = 1.0
param.filter.nsigma = 4

param.decor.method = 'COMMON_MODE'
param.decor.common_mode.per_subscan = 'yes'
param.decor.common_mode.median = 'yes'
param.fit_elevation = 'yes'
param.decor.baseline = [0,8]

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 20.0
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 20.0

param.flag.uncorr = 'yes'
param.flag.sat = 'yes'


;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, $
                  use_noise_from_map=1, $
                  check_flag_cor=1, check_flag_speed=1, ps=1, clean=1, $
                  noskydip=0, multi=1

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
param.decor.common_mode.flag_lim = [5,5]

outdir = output_dir+'iter1/'
param.output_dir = outdir
spawn, 'mkdir -p ' + outdir
param.logfile_dir = outdir 
nika_pipe_launch, param, map_combi, map_list, $
                  use_noise_from_map=1, $
                  check_flag_cor=1, check_flag_speed=1, meas_atm=1, ps=1, clean=1, $
                  noskydip=1, multi=1

;;------- Analysis after the pipeline
restore, outdir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10
anapar.snr_map.relob.a = 10
anapar.snr_map.relob.b = 10

nika_anapipe_launch, param, anapar

return
end
