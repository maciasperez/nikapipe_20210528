;;===============================================================
;;           Example script 1 - DR21OH (Run5)
;;           Source properties: strong extended source
;;===============================================================

;;--------- Some names I want to use + pointing (to be read from IMB_fits) 
source = 'DR21OH'                                  ;Name of the source
version = 'Veg'                                    ;Version of the analysis
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
param.logfile_dir = output_dir        ;
param.coord_pointing = coord_pointing ;If not set, it is taken from IMBFITS
param.coord_map = coord_pointing      ;If not set, it is taken from IMBFITS

param.map.reso = 5
param.map.size_ra = 900
param.map.size_dec = 900

;;------- 1 Launch the pipeline in the simplest way
param.decor.method = 'COMMON_MODE'
nika_pipe_launch, param, map_combi, map_list, cor_calib=[0.68, 0.95], /clean

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
param.decor.common_mode.flag_lim = [3,3]

nika_pipe_launch, param, map_combi, map_list, cor_calib=[0.68,0.95], /clean

param.decor.common_mode.flag_lim = [3,3] 
nika_pipe_launch, param, map_combi, map_list, cor_calib=[0.68,0.95], /clean

param.decor.common_mode.flag_lim = [3,3] 
nika_pipe_launch, param, map_combi, map_list, cor_calib=[0.68,0.95], /ps, make_products=0, make_log=0, /check_flag_speed, /check_flag_cor, meas_atm=1, /plot_decor_toi, /clean

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
anapar.flux_map.conts1mm = [0.25,0.5,2,4,6,8]*1e3
anapar.flux_map.conts2mm = [0.05,0.1,0.25,0.5,2,4]*1e3
;anapar.flux_map.range1mm = [-0.5,0.5]*1e3
anapar.flux_map.range2mm = [-0.1,4]*1e3
anapar.snr_map.range1mm = [-10,10]
anapar.snr_map.range2mm = [-10,10]

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
anapar.spectrum.snr_cut1mm = 10
anapar.spectrum.snr_cut2mm = 30
anapar.spectrum.range = [-0.5,3.5]

;;------- Launch the analysis
loadct,39
nika_anapipe_launch, param, anapar, /no_sat

end
