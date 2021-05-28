;;===============================================================
;;           Name: IC1396A-4
;;           Run: 10
;;           Extended: no
;;           Flux peak: a few 50 mJy
;;           Target description: 
;;                Following of OpenPool1
;;===============================================================
pro ic1396a_4_op2 
;;------- Properties of the source to be given here ------------------
source = 'IC1396A-4'                               ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;------- Prepare output directory for plots and logbook --------------
;; output_dir = !nika.plot_dir+'/'+name4file
;; spawn, "mkdir -p "+output_dir

;; ;;------- Scans --------------
;; scan_num = [407,408,409,410,411,412,413,414,415,416,417,418]
;; day = '20141118'+strarr(n_elements(scan_num))

;; Problems with all scans which seems to be fully flagged !!!

thisprojid = '056-14'
output_dir = !nika.plot_dir+'/OpenPool2/'+thisprojid+'/'+source+'/' 
thissource = source
get_scans_from_database,thisprojid ,thissource , day ,scan_num, info=info
outdir = output_dir+'iter0/'
spawn, "mkdir -p "+outdir

;;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param
param.source = source
param.logfile_dir = outdir
param.name4file = name4file
param.version = version
param.output_dir = outdir

param.map.reso = 2
param.map.size_ra = 400
param.map.size_dec = 400

param.filter.apply = 'yes'
param.filter.freq_start = 1.0
param.filter.nsigma = 4

param.decor.method = 'COMMON_MODE_KIDS_OUT'
;param.decor.method = 'COMMON_MODE'
param.decor.common_mode.d_min = 30.0
param.decor.common_mode.per_subscan = 'yes'
param.decor.common_mode.median = 'yes'
param.decor.common_mode.nsig_bloc = 1.0
param.decor.common_mode.nbloc_min = 50
param.fit_elevation = 'yes'
param.decor.baseline = [3,3]

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 30.0
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 30.0

;; param.coord_pointing = {ra:[0.0,0.0,0.1], dec:[0.0,0.0,0.1]}
;; param.coord_map = {ra:[0.0,0.0,00.1], dec:[0.0,0.0,0.1]}
;; param.coord_source = {ra:[0.0,0.0,00.1], dec:[0.0,0.0,0.1]}


;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, $
                  use_noise_from_map=1, $
                  ps=1, clean=1, $
                  noskydip=0, multi=1

; check for bad scans 
nika_pipe_check_scan_flag, param


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
                  check_flag_cor=1, check_flag_speed=1, meas_atm=1,ps=1, clean=1, $
                  noskydip=0, multi=1


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
