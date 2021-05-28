
;------- Properties of the source to be given here ------------------
source = 'Simulation of a smooth extended beam'    ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;The scans I want to use and the corresponding days (here M87 scans)
scan_num = [222,222,222,222,222,222,222,222]
day = '201211'+['22','22','22','22','22','22','22','22']

;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.simu_dir+"/"+name4file
spawn, "mkdir -p "+output_dir

;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param        ;Take the analysis param
partial_simu_default_param, param, 'point_source_eb' ;and add simulation params to the structure
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir

param.caract_source.flux.A = 51.6
param.caract_source.flux.B = 17.9
param.caract_source.beam2.A = 30.0
param.caract_source.beam3.A = 70.0
param.caract_source.beam2.B = 45.0
param.caract_source.beam3.B = 100.0
param.caract_source.amp2.A = 6e-2
param.caract_source.amp3.A = 6e-3
param.caract_source.amp2.B = 6e-2
param.caract_source.amp3.B = 6e-3

param.decor.method = 'COMMON_MODE_KIDS_OUT'
param.decor.common_mode.d_min = 55.0

param.w8.dist_off_source = 60.0
param.zero_level.dist_off_source = 60.0

;------- Launch the pipeline -----------------------------------------
;partial_simu_launch, param
nika_pipe_launch, param, map_combi, map_list, /simu, /map_per_kid

;;------- Analysis after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save',/verb
nika_anapipe_default_param, anapar
anapar.beam.apply = 'yes'
anapar.beam.fsl = 'yes'
anapar.beam.dispersion = 'yes'
anapar.beam.oplot = 'yes'
anapar.beam.flux.A = param.caract_source.flux.A
anapar.beam.flux.B = param.caract_source.flux.B
anapar.beam.beam2.A = param.caract_source.beam2.A
anapar.beam.beam3.A = param.caract_source.beam3.A
anapar.beam.beam2.B = param.caract_source.beam2.B
anapar.beam.beam3.B = param.caract_source.beam3.B
anapar.beam.amp2.A = param.caract_source.amp2.A
anapar.beam.amp3.A = param.caract_source.amp3.A
anapar.beam.amp2.B = param.caract_source.amp2.B
anapar.beam.amp3.B = param.caract_source.amp3.B
anapar.beam.model_ratio = 'yes'

anapar.mapperkid.apply = 'yes'
anapar.mapperscan.apply = 'yes'
anapar.mapperscan.range1mm = [-1.0,55.0]
anapar.mapperscan.range2mm = [-1.0,19.0]
anapar.mapperkid.range1mm = [-1.0,55.0]
anapar.mapperkid.range2mm = [-1.0,19.0]
anapar.mapperscan.allbar = 'yes'
nika_anapipe_launch, param, anapar

stop
end

