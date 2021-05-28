

;;;; Quicklook en RTA
;;scan_num_list =  [269, 270, 271, 294, 295, 296, 297];, 298, 299, 300, 301, 302, 303, 304, 310, 311, 312, 316]
;;scan_num_list =  [269, 270, 294, 295, 296, 297];, 298, 299, 300, 301, 302, 303, 304, 310, 311, 312, 316]

scan_list = '20140219s'+strtrim([269, 270, 271, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 310, 311, 312, 316], 2)

;; All scans with common orientation
scan_list =  '20140219s'+strtrim([269,  270,  271,  294,  295,  296,  297,  298,  299,  300], 2)
scan_list =  '20140219s'+strtrim([269,  270,  294,  295,  296,  297,  298,  299,  300], 2)

;; Need to init a slightly larger map
r        = strsplit( scan_list[0], "s", /extract)
day      = r[0]
scan_num = r[1]
nika_pipe_default_param, scan_num, day, param
param.map.size_ra  = 600
param.map.size_dec = 600

reset = 0
combine_scans, scan_list, reset=reset, param=param



;;======================================================================================================
;;======================================================================================================
stop


;; Script to reduce Ph. Andre's project on NIKA Run8 pool
;; Friend of Project Nico.
;;===========================================================================

;;--------- Some names I want to use + pointing (to be read from IMB_fits) 
source = 'Taurus'                                  ;Name of the source
version = 'V0'                                    ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'
coord_pointing = {ra:[20,39,1.1],dec:[42,22,50.2]} ;Pointing coordinates

;;--------- The scans I want to use and the corresponding days
scan_num = [161, 162]         
day = '201211'+['20', '20']

;;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.plot_dir+'/'+name4file
spawn, "mkdir -p "+output_dir

;;--------- Init default param and change the ones you want to change 
nika_pipe_default_param, scan_num, day, param
param.source = source                 ;If not set, the name is taken from IMBFITS
param.name4file = name4file           ;If not set, the name is taken from IMBFITS
param.version = version               ;If not set, the default value is used
param.output_dir = output_dir         ;If not set, the name is taken from IMBFITS
param.coord_pointing = coord_pointing ;If not set, it is taken from IMBFITS
param.coord_map = coord_pointing      ;If not set, it is taken from IMBFITS

param.map.reso = 5
param.map.size_ra = 900
param.map.size_dec = 900

;;------- 1 Launch the pipeline in the simplest way
param.decor.method = 'COMMON_MODE'

nika_pipe_launch, param, map_combi, map_list, cor_calib=[0.68, 0.95]

;;------- 2 Launch the pipeline by reiteration
param.decor.method = 'COMMON_MODE_KIDS_OUT_MAP'
param.decor.common_mode.map_guess1mm = output_dir+'/MAPS_1mm_'+name4file+'_'+version+'.fits'
param.decor.common_mode.map_guess2mm = output_dir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.w8.map_guess1mm = output_dir+'/MAPS_1mm_'+name4file+'_'+version+'.fits'
param.w8.map_guess2mm = output_dir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.zero_level.map_guess1mm = output_dir+'/MAPS_1mm_'+name4file+'_'+version+'.fits'
param.zero_level.map_guess2mm = output_dir+'/MAPS_2mm_'+name4file+'_'+version+'.fits'
param.w8.flag_lim = [3,3]
param.zero_level.flag_lim = [3,3]
param.decor.common_mode.flag_lim = [3,3]

nika_pipe_launch, param, map_combi, map_list, cor_calib=[0.68,0.95]

param.decor.common_mode.flag_lim = [3,3] 
nika_pipe_launch, param, map_combi, map_list, cor_calib=[0.68,0.95]

param.decor.common_mode.flag_lim = [3,3] 
nika_pipe_launch, param, map_combi, map_list, cor_calib=[0.68,0.95], /ps, /make_products, /make_log, /meas_atm, /check_flag_speed, /check_flag_cor

;;======= Analysis after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

;;------- Maps Field of view
anapar.flux_map.fov = 700
anapar.noise_map.fov = 700
anapar.time_map.fov = 700
anapar.snr_map.fov = 700
anapar.spectrum.fov = 700

;;------- Contours and ranges
anapar.flux_map.conts1mm = [0.25,0.5,2,4,6,8]
anapar.flux_map.conts2mm = [0.05,0.1,0.25,0.5,2,4]
anapar.flux_map.range1mm = [-0.5,3.5]
anapar.flux_map.range2mm = [-0.5,5.5]

anapar.flux_map.relob.a = 10.0
anapar.flux_map.relob.b = 10.0
anapar.noise_map.relob.a = 10.0
anapar.noise_map.relob.b = 10.0

anapar.mapperscan.apply = 'yes'
anapar.mapperscan.allbar = 'yes'

;;------- Diffuse photometry
anapar.dif_photo.apply = 'yes'
anapar.dif_photo.nb_source = 2
anapar.dif_photo.method = 'coord'
anapar.dif_photo.per_scan = 'yes'
anapar.dif_photo.coord[0].ra = [20,39,1.1]
anapar.dif_photo.coord[0].dec = [42,22,50.2]
anapar.dif_photo.coord[1].ra = [20,39,1.1]
anapar.dif_photo.coord[1].dec = [42,19,45]
anapar.dif_photo.r0[0] = [80.0]
anapar.dif_photo.r1[0] = [100.0]
anapar.dif_photo.r0[1] = [80.0]
anapar.dif_photo.r1[1] = [100.0]

;;------- Spectral index
anapar.spectrum.apply = 'yes'
anapar.spectrum.reso = 21
anapar.spectrum.snr_cut1mm = 13
anapar.spectrum.snr_cut2mm = 12
anapar.spectrum.range = [-0.5,2]

;;------- Launch the analysis
nika_anapipe_launch, param, anapar


end
