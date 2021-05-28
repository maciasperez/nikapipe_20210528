;;===============================================================
;;           Project:  193-13
;;           PI: Hermelo
;;           Affiliation: IRAM
;;           Title: The dust SED of dwarf galaxies: NGC1569 and NGC4449
;;           NIKA team manager:  Francois-Xavier Desert
;;           IRAM manager:  Israel Hermelo 
;;           Target description: Extended Emission
;;===============================================================

;;--------- Some names I want to use + pointing (to be read from IMB_fits) 
source = 'NGC1569'                                 ;Name of the source
version = 'V0'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;--------- The scans I want to use and the corresponding days
scan_num = [111,113,114,116,117,118,119,120,121,122,123,124,125,126,127,128]
day = ['20140221'+strarr(n_elements(scan_num))]

;;--------- Prepare output directory for plots and logbook 
output_dir = !nika.plot_dir+'/'+name4file
spawn, "mkdir -p "+output_dir

;;--------- Init default param and change the ones you want to change 
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir
param.logfile_dir = output_dir

param.decor.method = 'COMMON_MODE_BLOCK'
param.decor.common_mode.d_min = 30
param.decor.common_mode.nbloc_min = 15
param.decor.common_mode.nsig_bloc = 3

param.map.reso = 2
param.map.size_ra = 350
param.map.size_dec = 350
param.filter.apply = 'yes'
param.filter.cos_sin = 'yes'

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 30
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 30

param.pointing.fake_subscan = 'yes'

param.flag.uncorr = 'yes'

;;------- Launch the pipeline
;nika_pipe_launch, param, map_combi, map_list, /use_noise_from_map, /make_log, /meas_atm, /check_flag_speed, /check_flag_cor, /ps, /plot_decor_toi

;;======= Plots after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

;;------- To plot flux maps
anapar.flux_map.conts1mm = [1,2,3,6,9,12,15,18]*1e-3
anapar.flux_map.conts2mm = [1,2,3,6,9,12,15,18]*1e-3
anapar.flux_map.range1mm = [-0.005,0.02]
anapar.flux_map.range2mm = [-0.005,0.02]
anapar.flux_map.relob.a = 5
anapar.flux_map.relob.b = 5
anapar.flux_map.noise_max = 2
anapar.flux_map.fov = 350
anapar.snr_map.fov = 350

;;------- SNR map
anapar.snr_map.relob.a = 10
anapar.snr_map.relob.b = 10

;;------- To plot noise maps
anapar.noise_map.relob.a = 10
anapar.noise_map.relob.b = 10

;;------- To plot time maps
anapar.time_map.relob.a = 10
anapar.time_map.relob.b = 10

;;------- Diffuse photometry
anapar.dif_photo.apply = 'yes'
anapar.dif_photo.nb_source = 2
anapar.dif_photo.method = 'coord'
anapar.dif_photo.per_scan = 'yes'
anapar.dif_photo.coord[0].ra = [4,30,50.5]
anapar.dif_photo.coord[0].dec = [64,50,55.0]
anapar.dif_photo.r0[0] = [100.0]
anapar.dif_photo.r1[0] = [120.0]

;;------- To do noise statistics
anapar.noise_meas.apply = 'yes'
anapar.noise_meas.jk.relob.a = 10
anapar.noise_meas.jk.relob.b = 10
 
anapar.spectrum.apply = 'yes'
anapar.spectrum.reso = 20.0
anapar.spectrum.snr_cut1mm = 3
anapar.spectrum.snr_cut2mm = 3
anapar.spectrum.range = [-1,2]
anapar.spectrum.fov = 200

;;------- Launch analysis using previously defined parameters
nika_anapipe_launch, param, anapar

stop
end



