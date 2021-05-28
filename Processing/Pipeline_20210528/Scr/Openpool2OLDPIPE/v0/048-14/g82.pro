;;===============================================================
;;           Name: G82
;;           Run: 10
;;           Extended: yes
;;           Flux peak: a few 10 mJy
;;           Target description: 
;;                Mapping Herschel core molecular clouds
;;===============================================================
 
;;------- Properties of the source to be given here ------------------
source = 'G82'                                 ;Name of the source
projid = '048-14'    ; official project id
version = 'v0.1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'
obstype = 'ONTHEFLYMAP'   ; give the observing type


;;------- Scans --------------
;; scan_num = [163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,181,182,183,184,185,186,187,188]
;; day = '20141115'+strarr(n_elements(scan_num))

;; New method
restore,'$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/' + $
        'Log_Iram_tel_Run10_v0.save'
avoid_list = ['20141115s178', '20141115s179']  ; mostly saturated

indscan = nk_select_scan( scan, source, obstype, nscans, avoid = avoid_list)
scan_num = scan[indscan].scannum
day = scan[indscan].day
print, nscans, ' scans found'
print, day +'s'+strtrim(scan_num,2)
print, 'Projects found: ', scan[ indscan].projid
;; Not working  because t21, test are mixed in with
;; projid = strtrim( scan[indscan[0]].projid, 2)
print, 'Project directory: ', projid

;;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.plot_dir+'/'+projid+'/'+source
spawn, "mkdir -p "+output_dir

;;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param
param.source = source
param.logfile_dir = output_dir
param.coord_pointing = {ra:[20.0,52.0,45.8], dec:[41.0,31.0,0.8]}
param.coord_map = {ra:[20.0,52.0,45.8], dec:[41.0,31.0,0.8]}
param.coord_source = {ra:[20.0,52.0,45.8], dec:[41.0,31.0,0.8]}
param.name4file = name4file
param.version = version
param.output_dir = output_dir

param.map.reso = 2
param.map.size_ra = 500
param.map.size_dec = 500

param.filter.apply = 'yes'
param.filter.freq_start = 1.0
param.filter.nsigma = 4

param.decor.method = 'COMMON_MODE'
param.decor.common_mode.d_min = 0.0
param.decor.common_mode.per_subscan = 'yes'
param.decor.common_mode.median = 'yes'
param.decor.common_mode.nsig_bloc = 1.0
param.decor.common_mode.nbloc_min = 40
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
                 ps=1, clean=0, $
                 noskydip=1, multi=2

;;------- 2 Launch the pipeline by reiteration
param.decor.method = 'COMMON_MODE_KIDS_OUT'
param.decor.common_mode.map_guess1mm = output_dir+'/MAPS_1mm_'+name4file+'_'+version+'.fits'
param.decor.common_mode.map_guess2mm = output_dir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.w8.map_guess1mm = output_dir+'/MAPS_1mm_'+name4file+'_'+version+'.fits'
param.w8.map_guess2mm = output_dir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.zero_level.map_guess1mm = output_dir+'/MAPS_1mm_'+name4file+'_'+version+'.fits'
param.zero_level.map_guess2mm = output_dir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.w8.flag_lim = [3,3]
param.zero_level.flag_lim = [3,3]
param.decor.common_mode.flag_lim = [5,3]

nika_pipe_launch, param, map_combi, map_list, $
                 use_noise_from_map=1, $
                 ps=1, clean=1, $
                 noskydip=1, multi=1

;;------- Analysis after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10
anapar.flux_map.noise_max = 5
anapar.snr_map.relob.a = 10
anapar.snr_map.relob.b = 10

anapar.ps_photo.apply = 'yes'
anapar.ps_photo.per_scan = 'yes'

nika_anapipe_launch, param, anapar

stop
end
