;;==============================================================
project_name = '193-13'

;;--------- Some names I want to use + pointing (to be read from IMB_fits) 
source = 'NGC1569'                                 ;Name of the source
;;;version = 'V1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;--------- The scans I want to use and the corresponding days
scan_num3 = [330,331,332,333,334,335,336,337,338] ;OTF

scan_num = [scan_num3]
day = ['20140226'+strarr(n_elements(scan_num3))]

;;------- The directory where to save the results
project_dir = !nika.save_dir+'/Project_winter2014/'+project_name 
print, "WORKING ON PROJECT: "
print, file_basename(project_dir)
;;; version = 'V0'
output_dir = project_dir+'/'+version
direxist = FILE_TEST(output_dir, /DIRECTORY)
if (direxist lt 1) then spawn, "mkdir -p "+output_dir 

;;--------- Init default param and change the ones you want to change 
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir
param.logfile_dir = output_dir

param.decor.method = 'COMMON_MODE_KIDS_OUT'
param.decor.common_mode.d_min = 25.0 
;; param.decor.method = 'COMMON_MODE_BLOCK'
;; param.decor.common_mode.d_min = 25.0
;; param.decor.common_mode.nbloc_min = 15
;; param.decor.common_mode.nsig_bloc = 2
param.map.reso = 2
param.map.size_ra = 450
param.map.size_dec = 450

param.filter.apply = 'yes'
;;; param.filter.cos_sin = 'yes'
;;; param.filter.dist_off_source = 25.0
param.filter.low_cut = [0.08,0.1]

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 10
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 30.0
param.w8.nsigma_cut = 3.0

;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, /use_noise_from_map, /make_log, /meas_atm, /check_flag_speed, /check_flag_cor, /ps, /plot_decor_toi; ,/make_prod

;;======= Plots after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

;;------- To plot flux maps
;; anapar.flux_map.conts1mm = [3,6,9,12,15,18]*1e-3
;; anapar.flux_map.conts2mm = [1,2,3,6,9,12,15,18]*1e-3
anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10
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
nika_anapipe_launch, param, anapar, /no_sat


end



