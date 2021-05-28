;;===============================================================
;;           Name: M99
;;           Run: 10
;;           Extended: yes
;;           Flux peak: a few 10 mJy
;;           Target description: 
;;                Face-on galaxie
;;===============================================================
 
pro m99_op2
;;------- Properties of the source to be given here ------------------
source = 'M99'                                     ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;;------- Prepare output directory for plots and logbook --------------
;; output_dir = !nika.plot_dir+'/Nearby_Galaxies_NKGT/'+name4file
;; spawn, "mkdir -p "+output_dir

;; ;------- Scans --------------
;; scan_num1 = [147,148,149,150,151,153,154,155,156,157,158,159,160,161,162,163,164,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,255,256,257,258,259,260,261,262,263,264,265,266]152
;; scan_num2 = [565,566,567,568,569,570,571,572,573,574,575,576,577,578,579,580,581,582,583,584,585,586,587,588,589,590,591,592,593,594]
;; day1 = '20141116'+strarr(n_elements(scan_num1))
;; day2 = '20141119'+strarr(n_elements(scan_num2))
;; scan_num = [scan_num1, scan_num2]
;; day = [day1, day2]

thisprojid = '095-14'
output_dir = !nika.plot_dir+'/OpenPool2/'+thisprojid+'/'+source+'/' 
thissource = source
get_scans_from_database,thisprojid ,thissource , day ,scan_num, info=info
outdir = output_dir+'iter0/'
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

;param.decor.method = 'COMMON_MODE_BlOCK'
param.decor.method = 'COMMON_MODE'
param.decor.common_mode.d_min = 40.0
param.decor.common_mode.per_subscan = 'yes'
param.decor.common_mode.median = 'yes'
param.decor.common_mode.nsig_bloc = 0.5
param.decor.common_mode.nbloc_min = 110
param.fit_elevation = 'yes'
param.decor.baseline = [0,8]

param.w8.per_subscan = 'no'
param.w8.dist_off_source = 0.0
param.zero_level.per_subscan = 'no'
param.zero_level.dist_off_source = 0.0

; Defining pointing coordinates ??
;; param.coord_pointing = {ra:[0.0,0.0,0.1], dec:[0.0,0.0,0.1]}
;; param.coord_map = {ra:[0.0,0.0,00.1], dec:[0.0,0.0,0.1]}
;; param.coord_source = {ra:[0.0,0.0,00.1], dec:[0.0,0.0,0.1]}

;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, $
                  use_noise_from_map=1, $
                  check_flag_cor=1, check_flag_speed=1, ps=1, clean=0, $
                  noskydip=1, multi=0



; check for bad scans 
nika_pipe_check_scan_flag, param

; do iteration
;param.decor.method = 'COMMON_MODE_KIDS_OUT'
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

anapar.flux_map.relob.a = 20
anapar.flux_map.relob.b = 20
anapar.snr_map.relob.a = 20
anapar.snr_map.relob.b = 20

nika_anapipe_launch, param, anapar

return
end
