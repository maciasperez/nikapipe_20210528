;;===============================================================
;;           Example script 2 - HFLS3 (Run6)
;;           Source properties: point source with lissajous maps
;;===============================================================
 
;;--------- Some names I want to use + pointing (to be read from IMB_fits) 
source = 'HFLS3'                                   ;Name of the source
version = 'Veg'                                    ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;--------- The scans I want to use and the corresponding days
scan_num = [17, 20, 21, 25, 26, 27, 28]
day = '20130618'+strarr(n_elements(scan_num))

;;--------- Prepare output directory for plots and logbook 
output_dir = !nika.plot_dir+'/Example/HFLS3'
spawn, "mkdir -p "+output_dir

;;--------- Init default param and change the ones you want to change 
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir
param.logfile_dir = output_dir

param.decor.method = 'COMMON_MODE_BLOCK2'
param.decor.common_mode.d_min = 20

param.map.reso = 2
param.map.size_ra = 250
param.map.size_dec = 250
param.filter.apply = 'yes'
param.filter.freq_start = 1
param.filter.nsigma = 3

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 20
param.w8.nsigma_cut = 3
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 20

param.pointing.fake_subscan = 'yes'
param.flag.uncorr = 'no'
param.fit_elevation = 'yes'

;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list,$
                  range_plot_scan_a=[-0.015,0.015], range_plot_scan_b=[-0.0035,0.0035], $
                  /save_mpkps, $
                  /use_noise_from_map, /make_log, $
                  /meas_atm, /check_flag_speed, /check_flag_cor,/plot_decor_toi, /ps, /clean

;;======= Plots after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

;;------- To plot flux maps
anapar.flux_map.conts1mm = [3,6,9,12,15,18]*1e-3
anapar.flux_map.conts2mm = [1,2,3,4,5,6,7,8,9]*1e-3
anapar.flux_map.range1mm = [-0.015,0.015]
anapar.flux_map.range2mm = [-0.004,0.004]
anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10

;;------- SNR map
anapar.snr_map.relob.a = 5
anapar.snr_map.relob.b = 5

;;------- To plot noise maps
anapar.noise_map.relob.a = 10
anapar.noise_map.relob.b = 10

;;------- To plot time maps
anapar.time_map.relob.a = 10
anapar.time_map.relob.b = 10

;;------- To plot map per KIDs
anapar.mapperkid.apply = 'yes'
anapar.mapperkid.range1mm = [-0.025,0.025]
anapar.mapperkid.range2mm = [-0.010,0.010]
anapar.mapperkid.relob.a = 10
anapar.mapperkid.relob.b = 10

;;------- To plot map per scan
anapar.mapperscan.apply = 'yes'
anapar.mapperscan.range1mm = [-0.015,0.015]
anapar.mapperscan.range2mm = [-0.005,0.005]
anapar.mapperscan.relob.a = 10
anapar.mapperscan.relob.b = 10

;;------- To do noise statistics
anapar.noise_meas.apply = 'yes'
anapar.noise_meas.per_kid = 'yes'
anapar.noise_meas.jk.range1mm = [-0.015,0.015]
anapar.noise_meas.jk.range2mm = [-0.004,0.004]
anapar.noise_meas.jk.relob.a = 10
anapar.noise_meas.jk.relob.b = 10
 
;;------- Point source photometry 
anapar.ps_photo.apply = 'yes'
anapar.ps_photo.allow_shift = 'no'
anapar.ps_photo.per_scan = 'yes'
anapar.ps_photo.beam.a = !nika.fwhm_nom[0]
anapar.ps_photo.beam.b = !nika.fwhm_nom[1]

;;------- Find point sources within the field
anapar.search_ps.apply = 'yes'
anapar.search_ps.range1mm = [-0.015,0.015]
anapar.search_ps.range2mm = [-0.004,0.004]

;;------- Launch analysis using previously defined parameters
nika_anapipe_launch, param, anapar

stop
end
