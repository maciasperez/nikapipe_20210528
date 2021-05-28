;;===============================================================
;; Run10 GRB before run
;;===============================================================
pro grb1449_op2

;;------- Properties of the source to be given here ------------------
source = 'GRB1449'                                     ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.plot_dir+'/OpenPool2/115-14/'+source+'/' 
spawn, "mkdir -p "+output_dir

;;------- Scans --------------
scan_num = [204,205,206,207,208,209,210,211,212,213,214,215]
day = '20141109'+strarr(n_elements(scan_num))

;;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir

param.map.reso = 2
param.map.size_ra = 300
param.map.size_dec = 300

param.filter.apply = 'yes'
param.filter.freq_start = 1.0
param.filter.nsigma = 4

param.decor.method = 'COMMON_MODE_BLOCK'
param.decor.common_mode.d_min = 15.0
param.decor.common_mode.per_subscan = 'yes'
param.decor.common_mode.median = 'yes'
param.decor.common_mode.nsig_bloc = 1.0
param.decor.common_mode.nbloc_min = 20
param.fit_elevation = 'yes'
param.decor.baseline = [7,4]

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 15.0
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 15.0

param.flag.uncorr = 'yes'
param.pointing.fake_subscan = 'yes'
param.pointing.liss_cross = 4

param.flag.sat = 'yes'

add_source = {type:'PS', $
              PS:{pos:[0.0,0.0], $      ;Position source 2 [arcsec]
                  flux:[0.01, 0.01]}, $ ;Flux source [Jy]
              beam:[12.5, 18.5]}        ;Beam FWHM [arcsec]

;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, $
                  use_noise_from_map=1, $
                  check_flag_cor=1, check_flag_speed=1, meas_atm=1, plot_decor_toi=1, ps=1, clean=1, $
                  noskydip=1, multi=1,$
                  add_source=0;add_source

;;------- Analysis after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10
anapar.snr_map.relob.a = 10
anapar.snr_map.relob.b = 10

anapar.noise_meas.apply = 'yes'
anapar.noise_meas.jk.relob.a = 10
anapar.noise_meas.jk.relob.b = 10

anapar.ps_photo.apply = 'yes'
anapar.ps_photo.per_scan = 'yes'

nika_anapipe_launch, param, anapar


end
