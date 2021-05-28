
;------- Properties of the source to be given here ------------------
source = 'Simulation of a disk'                        ;Name of the source
version = 'v1'                                         ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_')     ;Name without space but '_'
coord_pointing = {ra:[23.0,23.0,27.85],dec:[58.0,48.0,42.8]}  ;Pointing coordinates
coord_source = {ra:[23.0,23.0,27.85],dec:[58.0,48.0,42.8]}    ;Center of the source coordinates

;The scans I want to use and the corresponding days (here M87 scans)
scan_num = [44, 46, 47, 49]
day = '20130618'+['', '', '', '']

;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.simu_dir+"/"+name4file
spawn, "mkdir -p "+output_dir

;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param        ;Take the analysis param
partial_simu_default_param, param, 'disk'            ;and add simulation params to the structure

param.source = source
param.name4file = name4file
param.version = version
param.coord_pointing = coord_pointing
param.coord_source = coord_source
param.output_dir = output_dir

param.caract_source.flux.A = 0.5
param.caract_source.flux.B = 0.8
param.caract_source.radius = 180.0

param.decor.method = 'COMMON_MODE_KIDS_OUT'
param.decor.common_mode.d_min = 50.0
param.map.reso = 5
param.map.size_ra = 900
param.map.size_dec = 900

param.w8.dist_off_source = 180.0
param.w8.per_subscan = 'no'

;;------- Launch the pipeline -----------------------------------------
;partial_simu_launch, param
;nika_pipe_launch, param, map_combi, map_list, /simu, /save, /ps
;save, filename=output_dir+'/param_'+name4file+'_'+version+'.save', param


;;#########################################################################################
;;########################## Brief analysis examples ######################################
;;#########################################################################################
;;------- Position of the source on the map
center = [-ten(coord_source.ra[0],coord_source.ra[1],coord_source.ra[2])*15.0 + $
          ten(coord_pointing.ra[0],coord_pointing.ra[1],coord_pointing.ra[2])*15.0, $
          ten(coord_source.dec[0],coord_source.dec[1],coord_source.dec[2]) - $
          ten(coord_pointing.dec[0],coord_pointing.dec[1],coord_pointing.dec[2])]*3600.0

;;------- Restore maps, just for the example since they are already there
nika_pipe_restore_maps, output_dir, name4file, version, $
                        param, map_list, map_combi, header

;;------- Profile
nika_pipe_profile, param.map.reso, map_combi.b, prof_b, nb_prof=200, center=center
nika_pipe_profile, param.map.reso, map_combi.a, prof_a, nb_prof=200, center=center

;;------- Make a nice plot of the final map
nika_pipe_nicemaps, 800.0, 5, [0.0,0.0], 5, coord_pointing, header, param, map_combi, $
                    output_dir, name4file, source;, range_plot_b=[-7,7]*1e-3, cont_b=[-1e5,-5,-3,-1,1,3,5,1e5]*1e-3

;;------- Profiles
nika_pipe_plotprofileps, prof_a, output_dir+'/'+name4file+'_profile_1mm.ps', source+' - profile at 1 mm (Jy/Beam)',xr=[0,200]
nika_pipe_plotprofileps, prof_b, output_dir+'/'+name4file+'_profile_2mm.ps', source+' - profile at 2 mm (Jy/Beam)',xr=[0,200];,yr=[-0.013,0.005]


stop
end

