;;===============================================================
;;           Example script 4 - APM (Run7)
;;           Source properties: point source with OTF maps
;;===============================================================
 
;;--------- Some names I want to use 
source = 'APM'                                     ;Name of the source
version = 'Veg'                                    ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;--------- The scans I want to use and the corresponding days
scan_num = [290, 291, 292, 293]
day = '20140127'+strarr(n_elements(scan_num))

;;--------- Prepare output directory for plots and logbook 
output_dir = !nika.plot_dir+'/Example/APM'
spawn, "mkdir -p "+output_dir

;;--------- Init default param and change the ones you want to change 
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir
param.logfile_dir = output_dir

param.map.reso = 2
param.map.size_ra = 250
param.map.size_dec = 250
param.filter.apply = 'yes'
param.filter.freq_start = 1
param.filter.nsigma = 3

param.decor.method ='COMMON_MODE_BLOCK2'
param.decor.common_mode.d_min = 20.0

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 20
param.w8.nsigma_cut = 3
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 20

param.flag.uncorr = 'no'

;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, meas_atm=1, check_flag_speed=1, check_flag_cor=1, range_plot_scan_a=[-0.05,0.05], range_plot_scan_b=[-0.015,0.015], use_noise_from_map=1, ps=1, make_log=1, map_per_kid=1, check_toi_out=1

;;======= Plots after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

;;------- To plot flux maps
anapar.flux_map.noise_max = 2
anapar.flux_map.conts1mm = [5,10,15,20]*1e-3
anapar.flux_map.conts2mm = [2,4,6,8]*1e-3
anapar.flux_map.range1mm = [-0.02,0.02]
anapar.flux_map.range2mm = [-0.005,0.005]
anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10

;;------- SNR map
anapar.snr_map.relob.a = 10
anapar.snr_map.relob.b = 10

;;------- To plot noise maps
anapar.noise_map.relob.a = 10
anapar.noise_map.relob.b = 10

;;------- To plot time maps
anapar.time_map.relob.a = 10
anapar.time_map.relob.b = 10

;;------- To do noise statistics
anapar.noise_meas.apply = 'yes'
anapar.noise_meas.per_kid = 'yes'
anapar.noise_meas.jk.relob.a = 10
anapar.noise_meas.jk.relob.b = 10
 
;;------- Point source photometry 
anapar.ps_photo.apply = 'yes'
anapar.ps_photo.allow_shift = 'no'
anapar.ps_photo.beam.a = !nika.fwhm_nom[0]
anapar.ps_photo.beam.b = !nika.fwhm_nom[1]

;;------- launch analysis using previously defined parameters
nika_anapipe_launch, param, anapar

stop
end
