;;===============================================================
;;           Project: 240-13
;;           PI: Rob Ivison
;;           Affiliation: UKATC & IAC 
;;           Title: The space density and environments of z>4 ultra-red Herschel SMGs 
;;           NIKA team manager: Francois-Xavier Desert 
;;           IRAM manager:  Carsten Kramer
;;           Target description: Point source
;;===============================================================
 
;;--------- Some names I want to use + pointing (to be read from IMB_fits) 
source = 'FLS3A'                                   ;Name of the source
version = 'V0'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'
map_coord = {ra:[17.0,06.0,46.0], dec:[58.0,46.0,52.0]}

;;--------- The scans I want to use and the corresponding days
scan_num1 = [220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283]
scan_num2 = [083,084,085,086,088,089,090,091,092,093,094,095,096,097,098,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256]

scan_num = [scan_num1, scan_num2]
day = ['20140222'+strarr(n_elements(scan_num1)), $
       '20140223'+strarr(n_elements(scan_num2))] 
check_scan_list_exist, day, scan_num

;;--------- Prepare output directory for plots and logbook 
output_dir = !nika.plot_dir+"/"+name4file
spawn, "mkdir -p "+output_dir

;;--------- Init default param and change the ones you want to change 
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir
param.coord_map = map_coord

param.map.size_ra = 600
param.map.size_dec = 600
param.map.reso = 5
param.decor.method = 'COMMON_MODE'

;;------- 1 Launch the pipeline first
;nika_pipe_launch, param, map_combi, map_list, /meas_atm, /check_flag_speed, /check_flag_cor, /ps

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
;nika_pipe_launch, param, map_combi, map_list, /ps, /make_log, /meas_atm, /check_flag_speed, /check_flag_cor

param.decor.common_mode.flag_lim = [3,3] 
;nika_pipe_launch, param, map_combi, map_list

param.decor.common_mode.flag_lim = [3,3] 
;nika_pipe_launch, param, map_combi, map_list, /ps, /make_lo, /meas_at, /check_flag_spe, /check_flag_co,/plot_dec

;;======= Plots after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar
anapar.flux_map.noise_max = 2.0
;anapar.flux_map.range1mm = [-0.005,0.02]
;anapar.flux_map.range2mm = [-0.002,0.005]
anapar.flux_map.relob.a = 10.0
anapar.flux_map.relob.b = 10.0
anapar.snr_map.relob.a = 10.0
anapar.snr_map.relob.b = 10.0

;anapar.snr_map.conts1mm = [-2.5,2.5]
;anapar.snr_map.range1mm = [-10,10]
;anapar.snr_map.conts2mm = [-2.5,2.5]
;anapar.snr_map.range2mm = [-10,10]

;;------- Find point sources within the field
anapar.search_ps.apply = 'yes'
anapar.search_ps.range1mm = [-0.015,0.015]
anapar.search_ps.range2mm = [-0.004,0.004]

cubehelix
nika_anapipe_launch, param, anapar, /no_sat
loadct,39
stop
end


