;;===============================================================
;;           Project: 166-13
;;           PI: Sicilia-Aguilar
;;           Affiliation: UAM
;;           Title: A new Class 0 object in IC1396A: Multi-episodic star formation?
;;           NIKA team manager: Rrmi Adam
;;           IRAM manager:  Nicolas Billot
;;           Target description: Extended emmision with bright sources
;;===============================================================

;;--------- Some names I want to use + pointing (to be read from IMB_fits) 
source = 'IC1396A'                                 ;Name of the source
version = 'V0'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'
map_coord = {ra:[21.0,36.0,35.0], dec:[57.0,30.0,30.0]}

;;--------- The scans I want to use and the corresponding days
scan_num1 = [212,213,214,215,216,217,218,219,220,221,222,223,224,225,227,228,229,230,231]
scan_num2 = [210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228]
scan_num3 = [160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179]
scan_num = [scan_num1, scan_num2, scan_num3]
day = ['20140219'+strarr(n_elements(scan_num1)), $
       '20140220'+strarr(n_elements(scan_num2)), $
       '20140225'+strarr(n_elements(scan_num3))]

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
param.coord_map = map_coord

param.map.reso = 5
param.map.size_ra = 1300
param.map.size_dec = 1300

param.filter.apply = 'yes'
param.filter.freq_start = 1.5
param.filter.nsigma = 5

param.w8.nsigma_cut = 4.0
param.zero_level.per_subscan = 'yes'

param.decor.method = 'COMMON_MODE'

;;------- Launch the pipeline
;nika_pipe_launch, param, map_combi, map_list, /use_noise_from_map

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
nika_pipe_launch, param, map_combi, map_list
nika_pipe_launch, param, map_combi, map_list
nika_pipe_launch, param, map_combi, map_list, /ps, /make_log, /meas_atm, /check_flag_speed, /check_flag_cor

;;======= Plots after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

;;------- To plot flux maps
anapar.flux_map.conts1mm = (dindgen(10)*20+10)*1e-3
anapar.flux_map.conts2mm = (dindgen(10)*6+3)*1e-3
anapar.flux_map.range1mm = [-0.05,0.1]
anapar.flux_map.range2mm = [-0.01,0.05]
anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10
anapar.flux_map.noise_max = 100

;;------- SNR map
anapar.snr_map.relob.a = 10
anapar.snr_map.relob.b = 10
anapar.snr_map.range1mm = [-10,20]
anapar.snr_map.range2mm = [-10,20]
anapar.snr_map.conts1mm = [-100,100]
anapar.snr_map.conts2mm = [-100,100]

;;------- To do noise statistics
anapar.noise_meas.apply = 'yes'
anapar.noise_meas.jk.relob.a = 10
anapar.noise_meas.jk.relob.b = 10
 
;;------- Launch analysis using previously defined parameters
cubehelix
nika_anapipe_launch, param, anapar, /no_sat

stop
end
