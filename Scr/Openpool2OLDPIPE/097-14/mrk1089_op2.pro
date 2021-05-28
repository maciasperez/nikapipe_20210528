;;===============================================================
;;           Name: Mrk1089
;;           Run: 8
;;           Extended: no
;;           Flux peak: 15 mJy
;;           Target description: 
;;                 Dwarf galaxies
;;===============================================================
pro mrk1089_op2
;;--------- Some names I want to use + pointing (to be read from IMB_fits) 
source = 'Mrk1089'                                  ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;--------- The scans I want to use and the corresponding days
;; scan_num1 = [146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161]
;; scan_num2 = [28,29,30,31,32,33,34,35,36,37]
;; day1 = '20141118'+strarr(n_elements(scan_num1))
;; day2 = '20141119'+strarr(n_elements(scan_num2))
;; scan_num = [scan_num1, scan_num2]
;; day = [day1, day2]

;; ;;--------- Prepare output directory for plots and logbook 
;; output_dir = !nika.plot_dir+'/Dwarf_Galaxies/'+source
;; spawn, "mkdir -p "+output_dir
thisprojid = '097-14'
output_dir = !nika.plot_dir+'/OpenPool2/'+thisprojid+'/'+source+'/' 

thissource = source
get_scans_from_database,thisprojid ,thissource , day ,scan_num, info=info
outdir = output_dir
spawn, "mkdir -p "+outdir

;;--------- Init default param and change the ones you want to change 
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = outdir
param.logfile_dir = outdir

param.map.reso = 2
param.map.size_ra = 400
param.map.size_dec = 400

param.filter.apply = 'yes'
param.filter.freq_start = 1.0
param.filter.nsigma = 4

;param.decor.method = 'COMMON_MODE'
param.decor.method = 'COMMON_MODE_BLOCK'
param.decor.common_mode.d_min = 25.0
param.decor.common_mode.per_subscan = 'yes'
param.decor.common_mode.median = 'yes'
param.decor.common_mode.nsig_bloc = 1
param.decor.common_mode.nbloc_min = 25
param.fit_elevation = 'yes'

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 25.0
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 25.0

param.pointing.fake_subscan = 'yes'
param.flag.uncorr = 'no'

;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, $
                  use_noise_from_map=1, $
                  check_flag_cor=1, check_flag_speed=1, meas_atm=1, ps=1, clean=0, nosky=1

;;======= Plots after the pipeline
restore, outdir+'/param_'+name4file+'_'+version+'.save', /verb
nika_pipe_check_scan_flag, param

nika_anapipe_default_param, anapar

anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10
anapar.snr_map.relob.a = 10
anapar.snr_map.relob.b = 10

nika_anapipe_launch, param, anapar, /no_sat
return

end



