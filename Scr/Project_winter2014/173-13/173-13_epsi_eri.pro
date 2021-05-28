;;===============================================================
;;           Project: 173-13
;;           PI: Jean-Francois Lestrade
;;           Affiliation: Observatoire de Paris 
;;           Title: Modelling the azimuthal structures of the debris disk around SZepsilon Eri
;;           NIKA team manager: Francois-Xavier Desert 
;;           IRAM manager: Nicolas Billot 
;;           Target description: Faint (~mJy) extended (~40") disk
;;===============================================================
 
;;--------- Some names I want to use + pointing (to be read from IMB_fits) 
source = 'Epsi Eri 20140221'                       ;Name of the source
version = 'V0'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;--------- The scans I want to use and the corresponding days
scan_num1 = [234,235,236,238,239,240,241,242,243,244,245,257,258,259,260,261,262]
scan_num2 = [232,233,234,235,236,237,238,239,240,241,242,243,247,248,249,250,251,252,253,254,255,256]
scan_num3 = [138,139,140,141,142,143,144,145,146,147,148,149]

day1 = '20140219'+strarr(n_elements(scan_num1))
day2 = '20140220'+strarr(n_elements(scan_num2))
day3 = '20140221'+strarr(n_elements(scan_num3))

scan_num = scan_num3
day = day3

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
param.decor.common_mode.d_min = 25.0
param.decor.common_mode.nbloc_min = 30
param.decor.common_mode.nsig_bloc = 2

param.map.reso = 4
param.map.size_ra = 250
param.map.size_dec = 250
param.filter.apply = 'yes'
param.filter.cos_sin = 'yes'

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 0.0
param.w8.nsigma_cut = 3.0
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 0.0

param.pointing.fake_subscan = 'yes'

param.flag.uncorr = 'no'

;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, /use_noise_from_map, /make_log, /meas_atm, /check_flag_speed, /check_flag_cor, /ps, /plot_decor_toi

;;======= Plots after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

;;------- To plot flux maps
;;anapar.flux_map.conts1mm = [3,6,9,12,15,18]*1e-3
;;anapar.flux_map.conts2mm = [1,2,3,4,5,6,7,8,9]*1e-3
;;anapar.flux_map.range1mm = [-0.015,0.015]
;;anapar.flux_map.range2mm = [-0.004,0.004]
anapar.flux_map.relob.a = 4
anapar.flux_map.relob.b = 4
anapar.flux_map.noise_max = 1.3
anapar.flux_map.fov = 200
anapar.snr_map.fov = 200
anapar.snr_map.range1mm = [-3,3]

;;------- SNR map
anapar.snr_map.relob.a = 4
anapar.snr_map.relob.b = 4

;;------- To plot noise maps
anapar.noise_map.relob.a = 10
anapar.noise_map.relob.b = 10

;;------- To plot time maps
anapar.time_map.relob.a = 10
anapar.time_map.relob.b = 10

;;------- To do noise statistics
anapar.noise_meas.apply = 'yes'
anapar.noise_meas.jk.relob.a = 10
anapar.noise_meas.jk.relob.b = 10
 
;;------- Diffuse photometry
anapar.dif_photo.apply = 'yes'
anapar.dif_photo.nb_source = 1
anapar.dif_photo.method = 'coord'
anapar.dif_photo.per_scan = 'no'
anapar.dif_photo.coord[0].ra = [3.0,32.0,54.9]
anapar.dif_photo.coord[0].dec = [-9.0,27.0,29.0]
anapar.dif_photo.r0[0] = [40.0]
anapar.dif_photo.r1[0] = [60.0]

;;------- Radial profile
anapar.profile.apply = 'yes'
anapar.profile.method = 'coord'
anapar.profile.nb_pt = 50
anapar.profile.xr[0,*] = [0,60]
anapar.profile.coord[0].ra = [3.0,32.0,54.9]
anapar.profile.coord[0].dec = [-9.0,27.0,29.0]

;;------- Launch analysis using previously defined parameters
nika_anapipe_launch, param, anapar

stop
end

