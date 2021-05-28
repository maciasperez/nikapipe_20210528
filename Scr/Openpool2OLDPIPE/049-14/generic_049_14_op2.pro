pro generic_049_14_op2, source

print, source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.plot_dir+'/PreProtocluster/'+name4file
spawn, "mkdir -p "+output_dir

;;------- Scans --------------
;; scan_num = [443,444,445,446,447,448,449,450,451,452,453,454]
;; day = '20141117'+strarr(n_elements(scan_num))

thisprojid = '049-14'
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
param.output_dir = output_dir

param.map.reso = 2
param.map.size_ra = 240
param.map.size_dec = 240

param.filter.apply = 'yes'
param.filter.freq_start = 1.0
param.filter.nsigma = 4

param.decor.method = 'COMMON_MODE_KIDS_OUT'
param.decor.common_mode.d_min = 30.0
param.decor.common_mode.per_subscan = 'yes'
param.decor.common_mode.median = 'yes'

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 30.0
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 30.0

param.coord_pointing = {ra:[0.0,0.0,0.1], dec:[0.0,0.0,0.1]}
param.coord_map = {ra:[0.0,0.0,00.1], dec:[0.0,0.0,0.1]}
param.coord_source = {ra:[0.0,0.0,00.1], dec:[0.0,0.0,0.1]}

;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, $
                  use_noise_from_map=1, $
                  ps=1, $
                  clean=1, $
                  multi=1



;;------- Analysis after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
; check for bad scans 
nika_pipe_check_scan_flag, param

nika_anapipe_default_param, anapar

anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10
anapar.snr_map.relob.a = 10
anapar.snr_map.relob.b = 10

nika_anapipe_launch, param, anapar

return
end
