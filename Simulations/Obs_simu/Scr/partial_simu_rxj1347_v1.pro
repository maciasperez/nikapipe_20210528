
;------- Properties of the source to be given here ------------------
source = 'Simulation of RXJ1347.5-1145'              ;Name of the source
version = 'v1'                                       ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_')   ;Name without space but '_'
coord_pointing = {ra:[0,0,0.0],dec:[0,0,0.0]}        ;Pointing coordinates
coord_source = {ra:[0,0,-1.0],dec:[0,0,+15.0]}      ;Pointing coordinates

;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.simu_dir+"/"+name4file
spawn, "mkdir -p "+output_dir

;------- The scans I want to use and the corresponding days
scan_num = [82,88,89,100,102,103,104,$
            78,79,81,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,$ 
            89,90,92,93,95,97,98,99,100,102,103,104,105,107,108,109,110,112,113,114,115,117,118]
day = ['20121121'+strarr(7),$
       '20121122'+strarr(25),$
       '20121123'+strarr(23)]

;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param        ;Take the analysis param
partial_simu_default_param, param, 'cluster+ps'      ;and add simulation params to the structure
param.source = source
param.name4file = name4file
param.version = version
param.coord_pointing = coord_pointing
param.coord_source = coord_source
param.output_dir = output_dir

param.atmo.tau0_a = 0.06
param.atmo.tau0_b = 0.04

param.map.reso = 5
param.map.size_ra = 600
param.map.size_dec = 600

param.glitch.nsigma = 100
param.filter.apply = 'yes'
param.filter.freq_start = 0.5
param.filter.nsigma = 3
param.filter.low_cut = [0.03,0.04]
;param.filter.cos_sin = 'yes'
param.filter.dist_off_source = 80.0

param.decor.method = 'TEST'
param.decor.common_mode.d_min = 40.0
param.w8.nsigma_cut = 4.0
param.w8.dist_off_source = 40.0
param.zero_level.dist_off_source = 80.0

bad_kids = [409,410,425,429,450,452,459,497,499,501,502,509,516,520,536, 426,446,500,532,592]

;------- Launch the pipeline -----------------------------------------
partial_simu_launch, param
;add_source = {type:'point_source',pos:[21.15,31.90],flux_a:-0.0032,flux_b:-0.0044}
nika_pipe_launch, param, map_combi, map_list, /simu, range_plot_scan_a=[-0.2,0.2],range_plot_scan_b=[-0.03,0.03],add_source=add_source, bad_kids=bad_kids, /map_per_kid

;;------- Analysis after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar
anapar.flux_map.fov = 500
anapar.flux_map.RANGE1MM = [-20,20]/1e3
anapar.flux_map.RANGE2MM = [-13,13]/1e3
anapar.flux_map.CONTS2MM = [-18,-15,-12,-9,-6,-3, 3, 6, 9]/1e3
anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10
anapar.flux_map.noise_max = 20

anapar.noise_map.fov = 500
anapar.time_map.fov = 500
anapar.snr_map.fov = 500
;anapar.snr_map.relob.b = 10

anapar.mapperkid.apply = 'yes'
anapar.mapperscan.apply = 'yes'
anapar.mapperscan.range1mm = [-100.0,100.0]*1e-3
anapar.mapperscan.range2mm = [-25.0,25.0]*1e-3
anapar.mapperscan.relob.a = 10
anapar.mapperscan.relob.b = 10
anapar.mapperkid.range1mm = [-100,100.0]*1e-3
anapar.mapperkid.range2mm = [-25,25.0]*1e-3
anapar.mapperkid.relob.a = 10
anapar.mapperkid.relob.b = 10

anapar.profile.apply = 'yes'
anapar.profile.nb_pt = 50
anapar.profile.method = 'coord'
anapar.profile.coord.ra = [0,0,-1.0]
anapar.profile.coord.dec = [0,0,+15.0]
anapar.profile.xr[0,*] = [0,300]

anapar.noise_meas.apply = 'yes'
anapar.noise_meas.jk.fov = 500
anapar.noise_meas.jk.relob.b = 10

nika_anapipe_launch, param, anapar

end

