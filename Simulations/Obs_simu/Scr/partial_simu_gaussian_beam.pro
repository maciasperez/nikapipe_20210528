
;------- Properties of the source to be given here ------------------
source = 'Simulation of a gaussian beam'           ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;The scans I want to use and the corresponding days
scan_num = [159, 159]
day = ['20130612', '20130612']

;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.simu_dir+"/"+name4file
spawn, "mkdir -p "+output_dir

;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param     ;Take the analysis param
partial_simu_default_param, param, 'point_source' ;and add simulation params to the structure
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir

param.caract_source.flux.A = 51.6
param.caract_source.flux.B = 17.9

param.map.reso = 2
param.map.size_ra = 500
param.map.size_dec = 500

param.decor.method = 'COMMON_MODE_KIDS_OUT'
param.decor.common_mode.d_min = 60.0
param.w8.dist_off_source = 60.0
param.zero_level.dist_off_source = 60.0

;------- Launch the pipeline -----------------------------------------
;partial_simu_launch, param
nika_pipe_launch, param, map_combi, map_list, /simu, /map_per_kid, /azel, /meas_atm, /save_mpkps, /show_deglitch

;;------- Analysis after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

anapar.flux_map.type = 'offset'
anapar.snr_map.type = 'offset'
anapar.noise_map.type = 'offset'
anapar.time_map.type = 'offset'

anapar.beam.apply = 'yes'
anapar.beam.fsl = 'yes'
anapar.beam.oplot = 'yes'
anapar.beam.per_kid = 'yes'
anapar.beam.amp1.A = 1
anapar.beam.amp1.B = 1
anapar.beam.beam1.A = param.caract_source.beam.a
anapar.beam.beam1.B = param.caract_source.beam.b
anapar.beam.amp2.A = 0
anapar.beam.amp2.B = 0
anapar.beam.amp3.A = 0
anapar.beam.amp3.B = 0
anapar.beam.flux.A = param.caract_source.flux.A
anapar.beam.flux.B = param.caract_source.flux.B
anapar.beam.model_ratio = 'yes'

anapar.mapperkid.apply = 'yes'
anapar.mapperscan.apply = 'yes'
anapar.mapperscan.allbar = 'yes'

anapar.noise_meas.apply = 'yes'
anapar.noise_meas.per_kid = 'yes'
anapar.noise_meas.jk.relob.a = 10
anapar.noise_meas.jk.relob.b = 10

anapar.ps_photo.apply = 'yes'

nika_anapipe_launch, param, anapar

stop
end

