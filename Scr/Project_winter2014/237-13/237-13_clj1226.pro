;;===============================================================
;;           Project: 237-13
;;           PI: Rémi Adam & Barbara Comis 
;;           Affiliation: LPSC 
;;           Title: Thermal Sunyaev-Zel’dovich mapping of high redshift galaxy clusters
;;           NIKA team manager: Barbara Comis
;;           IRAM manager: Carsten Kramer
;;           Target description: SZ cluster
;;===============================================================
 
;;------- Properties of the source to be given here ------------------
source = 'CL1226'                                  ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.plot_dir+"/"+name4file
spawn, "mkdir -p "+output_dir

;;------- OTF Scans Run5 Run6 --------------
;;all scans
scan_num1 = [056,058,060,062,064,066,068,070,072,074,076,078,080,082,086,088,090,092,094,096,098,100,102,104,106,108,110,112,116,118,120,122,126,128,130,132,134,136,138,140,142,144,146,148,150,152,154,156,158]
scan_num2 = [079,081,083,085,087,089,091,095,097,099,103,105,110,112,113,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131]
scan_num3 = [080,081,082,083,084,085,086,087,088,089,090,091,092,093,096,097,098,099,100,101,102,103,104,105,106,107,108,109,116,117,119,120,121,122,123,124,125,126,127,128,129,132,133,134,135,136,137,138,139,140,141,142,143,144]

scan_num = [scan_num1, scan_num2, scan_num3]
day = ['20140219'+strarr(n_elements(scan_num1)),$
       '20140220'+strarr(n_elements(scan_num2)),$
       '20140222'+strarr(n_elements(scan_num3))]
check_scan_list_exist, day, scan_num

;;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir

param.map.reso = 5
param.map.size_ra = 600
param.map.size_dec = 600

param.filter.apply = 'yes'
param.filter.freq_start = 1.5
param.filter.nsigma = 5

param.w8.nsigma_cut = 4.0
param.zero_level.per_subscan = 'yes'

param.decor.method = 'COMMON_MODE'

;;------- Launch the pipeline
;nika_pipe_launch, param, map_combi, map_list, /use_noise_from_map, /check_flag_cor, /check_flag_speed, /meas_atm, /plot_decor_toi, /ps

;;------- Analysis after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar
anapar.flux_map.relob.a = 5
anapar.flux_map.relob.b = 5
anapar.flux_map.noise_max = 1.3
anapar.flux_map.fov = 200
anapar.snr_map.relob.a = 5
anapar.snr_map.relob.b = 5
anapar.snr_map.fov = 150

anapar.noise_meas.apply = 'yes'
anapar.noise_meas.jk.relob.a = 15
anapar.noise_meas.jk.relob.b = 15

nika_anapipe_launch, param, anapar

stop
end
