;;------- Properties of the source to be given here ------------------
source = 'Beam Run8'                               ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'
coord_pointing = {ra:[0,0,0.001],dec:[0,0,0.001]} ;Pointing coordinates

;;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.plot_dir+"/"+name4file
spawn, "mkdir -p "+output_dir

;;------- OTF Scans Run5 Run6 --------------
scan_num = [161]               
day = ['20140221']

;;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir
param.coord_pointing = coord_pointing
param.coord_map = coord_pointing

param.map.reso = 4
param.map.size_ra = 600
param.map.size_dec = 600
param.decor.method = 'COMMON_MODE_KIDS_OUT'
param.decor.common_mode.d_min = 70.0

param.w8.dist_off_source = 100.0
param.zero_level.dist_off_source = 0.0
param.zero_level.per_subscan = 'yes'
param.zero_level.DIST_OFF_SOURCE = 100

;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, /meas_atm, /check_flag_speed, /check_flag_cor, /ps, /plot_decor,/azel, /map_per_kid

;;------- Analysis after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

anapar.flux_map.type = 'offset'
anapar.snr_map.type = 'offset'
anapar.noise_map.type = 'offset'
anapar.time_map.type = 'offset'

anapar.beam.apply = 'yes'
;anapar.beam.per_kid = 'yes'
;anapar.beam.fsl = 'yes'
anapar.beam.dispersion = 'yes'
;anapar.beam.make_products = 'yes'

;anapar.mapperkid.apply = 'yes'
;anapar.mapperscan.apply = 'yes'
anapar.mapperscan.range1mm = [-1.0,35.0]
anapar.mapperscan.range2mm = [-1.0,15.0]
anapar.mapperkid.range1mm = [-1,35.0]
anapar.mapperkid.range2mm = [-1,15.0]
anapar.mapperscan.allbar = 'yes'

anapar.cor_zerolevel.a = 36e-4
anapar.cor_zerolevel.b = 15e-4

nika_anapipe_launch, param, anapar

stop
end
