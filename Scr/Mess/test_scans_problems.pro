
;;--------- Some names I want to use + pointing (to be read from IMB_fits) 
;source = 'Epsi_Eri'                                   ;Name of the source
source = 'TestProblems'                                   ;Name of the source
version = 'V0'                                    ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;--------- The scans I want to use and the corresponding days
;scan_num = [258,259,262]
scan_num = [178]
day = '20140219'+strarr(n_elements(scan_num))
;day = '20140220'+strarr(n_elements(scan_num))

;;--------- Prepare output directory for plots and logbook 
output_dir = !nika.save_dir+'/'+name4file
spawn, "rm -rf "+output_dir

spawn, "mkdir -p "+output_dir
print, 'SAVE DATA IN: '
print, output_dir
;;--------- Init default param and change the ones you want to change 
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir
param.logfile_dir = output_dir

param.decor.method = 'COMMON_MODE_BLOCK'
param.decor.common_mode.d_min = 20
param.decor.common_mode.nbloc_min = 15
param.decor.common_mode.nsig_bloc = 2

param.map.reso = 2
param.map.size_ra = 250
param.map.size_dec = 250
param.filter.apply = 'yes'
param.filter.cos_sin = 'yes'    ;Pour les lissajous (enleve l'elevation)

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 20
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 20

param.pointing.fake_subscan = 'yes'

param.flag.uncorr = 'no'

;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list,/use_noise_from_map,/make_log,/meas_atm, /check_flag_speed, /check_flag_cor, /plot_decor_toi, /map_per_kid

;;======= Plots after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

;;------- To plot flux maps
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
anapar.ps_photo.per_scan = 'yes'
anapar.ps_photo.beam.a = !nika.fwhm_nom[0]
anapar.ps_photo.beam.b = !nika.fwhm_nom[1]

;;------- Launch analysis using previously defined parameters
nika_anapipe_launch, param, anapar

stop
end
