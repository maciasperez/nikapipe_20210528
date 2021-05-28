
;------- Properties of the source to be given here ------------------
source = 'Simulation of the beam with plateau'     ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;The scans I want to use and the corresponding days (here M87 scans)
scan_num = [222];,222,222,222,222,222,222,222]
day = '201211'+['22'];,'22','22','22','22','22','22','22']

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
param.plateau.A = 0.1
param.plateau.B = 0.1

param.decor.method = 'COMMON_MODE_KIDS_OUT'
param.decor.common_mode.d_min = 55.0

param.w8.dist_off_source = 60.0
param.zero_level.dist_off_source = 60.0

;------- Launch the pipeline -----------------------------------------
partial_simu_launch, param
nika_pipe_launch, param, map_combi, map_list, /simu

;;------- Analysis after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save',/verb
nika_anapipe_default_param, anapar
anapar.beam.apply = 'yes'
anapar.beam.fsl = 'yes'
;anapar.beam.dispersion = 'yes'
anapar.beam.oplot = 'yes'
anapar.beam.amp1.A = 1
anapar.beam.amp1.B = 1
anapar.beam.beam1.A = 12.5
anapar.beam.beam1.B = 18.5
anapar.beam.amp2.A = 0
anapar.beam.amp2.B = 0
anapar.beam.amp3.A = 0
anapar.beam.amp3.B = 0
anapar.beam.flux.A = param.caract_source.flux.A
anapar.beam.flux.B = param.caract_source.flux.B
nika_anapipe_launch, param, anapar

stop
end

