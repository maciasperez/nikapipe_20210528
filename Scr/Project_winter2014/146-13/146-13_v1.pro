;;===============================================================
;;           Project:  146-13
;;           PI: P. Andre
;;           Affiliation: SAP-CEA
;;           Title: Probing the inner structure of the Taurus main filament (NIKA guaranteed time proposal)
;;           NIKA team manager:  Nicolas Ponthieu
;;           IRAM manager: Nicolas Billot 
;;           Target description: Extended emission
;;===============================================================

project_name = '146-13'

;; Reshaped using Remi's taurus_filament.pro (Apr 30th, 2014)

;;--------- Some names I want to use + pointing (to be read from IMB_fits) 
source = 'Taurus'                                  ;Name of the source
version = 'V0'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'
map_coord = {ra:[4.0,19.0,51.4], dec:[27.0,11.0,40.0]}

;;--------- The scans I want to use and the corresponding days
scan_num1 = [269,270,271,272,294,295,296,297,298,299,300,301,302,303,304,310,311,312,316]
scan_num2 = [310,311,312,320,321,322,323,324,329,331,332,333,334,336,337,338,339,340,346,347,349]
;scan_num3 =
;[340,341,342,343,344,345,346,347,349,350,402,403,404,405,408,409,410,411,412,413,414,415,416,419,420,421,422,423,424,425,426,427,428]

;; get rid of scan 424 (very bad pointing)
scan_num3 = [340,341,342,343,344,345,346,347,349,350,402,403,404,405,408,409,410,411,412,413,414,415,416,419,420,421,422,423,425,426,427,428]

scan_num = [scan_num1, scan_num2, scan_num3]
day = ['20140219'+strarr(n_elements(scan_num1)), $
       '20140220'+strarr(n_elements(scan_num2)),$ 
       '20140222'+strarr(n_elements(scan_num3))]

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

param.map.size_ra = 1000
param.map.size_dec = 1000
param.map.reso = 5
param.decor.method = 'COMMON_MODE'

;;------- 1 Launch the pipeline first
nika_pipe_launch, param, map_combi, map_list, /meas_atm, /check_flag_speed, /check_flag_cor, /ps, range_plot_scan_a=[-0.05,0.05],range_plot_scan_b=[-0.015,0.015]
stop

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
;nika_pipe_launch, param, map_combi, map_list

param.decor.common_mode.flag_lim = [3,3] 
;nika_pipe_launch, param, map_combi, map_list

param.decor.common_mode.flag_lim = [6,6] 
;nika_pipe_launch, param, map_combi, map_list, /ps, /make_log, /meas_atm, /check_flag_speed, /check_flag_cor, /make_produ

;;======= Plots after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar
anapar.flux_map.noise_max = 2
;anapar.flux_map.range1mm = [-0.005,0.02]
;anapar.flux_map.range2mm = [-0.002,0.005]
anapar.flux_map.relob.a = 10.0
anapar.flux_map.relob.b = 10.0
anapar.noise_map.relob.a = 10.0
anapar.noise_map.relob.b = 10.0
anapar.time_map.relob.a = 10.0
anapar.time_map.relob.b = 10.0
anapar.snr_map.relob.a = 10.0
anapar.snr_map.relob.b = 10.0

anapar.snr_map.conts1mm = indgen(10)*3-6
;anapar.snr_map.range1mm = [-10,10]
anapar.snr_map.conts2mm = indgen(10)*3-6
;anapar.snr_map.range2mm = [-10,10]

anapar.mapperscan.apply = 'yes'
anapar.mapperscan.allbar = 'no'
anapar.mapperscan.range1mm = [-0.05,0.05]
anapar.mapperscan.range2mm = [-0.015,0.015]

anapar.cor_zerolevel.a = 0.003
anapar.cor_zerolevel.b = 0.001

cubehelix
nika_anapipe_launch, param, anapar, /no_sat
loadct,39

end
