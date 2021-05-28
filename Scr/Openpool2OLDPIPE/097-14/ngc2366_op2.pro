;;===============================================================
;;           Name: NGC2366
;;           Run: 10
;;           Extended: yes
;;           Flux peak: a few 10 mJy
;;           Target description: 
;;                Dwarf galaxies
;;===============================================================
pro ngc2366_op2 
;;------- Properties of the source to be given here ------------------
source = 'NGC2366'                                    ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;------- Prepare output directory for plots and logbook --------------
;; output_dir = !nika.plot_dir+'/Dwarf_Galaxies/'+source
;; spawn, "mkdir -p "+output_dir

;; ;;------- Scans --------------
;; scan_num1 = [190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211]
;; day1 = '20141118'+strarr(n_elements(scan_num1))
;; scan_num = [scan_num1]
;; day = [day1]

thisprojid = '097-14'
output_dir = !nika.plot_dir+'/OpenPool2/'+thisprojid+'/'+source+'/' 

thissource = source
get_scans_from_database,thisprojid ,thissource , day ,scan_num, info=info
outdir = output_dir
spawn, "mkdir -p "+outdir


;;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = outdir

param.map.reso = 5
param.map.size_ra = 1000
param.map.size_dec = 1000

param.filter.apply = 'yes'
param.filter.freq_start = 1.0
param.filter.nsigma = 4

param.decor.method = 'COMMON_MODE'
;param.decor.method = 'COMMON_MODE_BLOCK'
param.decor.common_mode.d_min = 0.0
param.decor.common_mode.per_subscan = 'yes'
param.decor.common_mode.median = 'yes'
param.decor.common_mode.nsig_bloc = 1.0
param.decor.common_mode.nbloc_min = 70
param.fit_elevation = 'yes'

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 0.0
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 0.0

param.coord_pointing = {ra:[0.0,0.0,0.1], dec:[0.0,0.0,0.1]}
param.coord_map = {ra:[0.0,0.0,00.1], dec:[0.0,0.0,0.1]}
 param.coord_source = {ra:[0.0,0.0,00.1], dec:[0.0,0.0,0.1]}

;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, $
                  use_noise_from_map=1, $
                  ps=1, clean=1, check_flag_cor=1,$
                  meas_atm=0, $
                  plot_decor_toi=0, $
                  noskydip=1, multi=0

;;------- Analysis after the pipeline
restore, outdir+'/param_'+name4file+'_'+version+'.save', /verb
nika_pipe_check_scan_flag, param

nika_anapipe_default_param, anapar

anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10
anapar.snr_map.relob.a = 10
anapar.snr_map.relob.b = 10

nika_anapipe_launch, param, anapar

return
end
