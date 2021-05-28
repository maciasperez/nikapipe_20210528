
;------- Properties of the source to be given here ------------------
source = 'Compact cluster'                             ;Name of the source
version = 'v1'                                         ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_')     ;Name without space but '_'
coord_pointing = {ra:[13.0,47.0,32.0],dec:[-11.0,45.0,42.0]} ;Pointing coordinates
coord_source = {ra:[13.0,47.0,31.0],dec:[-11.0,45.0,30.0]}   ;Center of the source coordinates

;The scans I want to use and the corresponding days (here M87 scans)
scan_num = [82,88,89,90,100,102,103,104];,$
            ;78,79,81,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,$ 
            ;89,90,92,93,95,97,98,99,100,102,103,104,105,107,108,109,110,112,113,114,115,117,118]
day = ['20121121'+strarr(8)];, '20121122'+strarr(25),'20121123'+strarr(23)]

;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.simu_dir+"/"+name4file
spawn, "mkdir -p "+output_dir

;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param        ;Take the analysis param
partial_simu_default_param, param, 'CLUSTER'    ;and add simulation params to the structure

param.source = source
param.name4file = name4file
param.version = version
param.coord_pointing = coord_pointing
param.coord_source = coord_source
param.output_dir = output_dir

param.caract_source.z = 0.45
param.caract_source.P0 = 526*1e-12*0.5/3.28
param.caract_source.rs = 406.0*1500.0/406.0

param.atmo.f_0 *= 0
param.atmo.f_el *= 0
param.elec.amp_cor *= 0
param.elec.amp_dec = [15.0, 12.0]*1e-3

param.map.reso = 2
param.map.size_ra = 600
param.map.size_dec = 600

param.decor.method = 'none';'DUAL_BAND_SIMPLE'

param.filter.apply = 'no'
param.filter.freq_start = 0.5
param.filter.width = 200
param.filter.nsigma = 3
param.filter.cos_sin = 'no'
param.glitch.nsigma = 3
param.filter.low_cut = [0.01,0.02]
param.fit_elevation = 'yes'

param.w8.dist_off_source = 0.0
param.w8.per_subscan = 'yes'

;------- Launch the pipeline -----------------------------------------
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

;;------- Zero level correction
nika_pipe_map0level, coord_pointing, coord_source, param, map_combi, 100.0

;;------- Profile
nika_pipe_profile, param.map.reso, map_combi.b, prof_b, nb_prof=50, center=center
nika_pipe_profile, param.map.reso, map_combi.a, prof_a, nb_prof=50, center=center

;;------- Integrated flux
rmax = 180.0
radius_max = dindgen(100)/99*rmax+2 ;maximum radius to compute the integrated flux (arcsec)
phi_int_a = nika_pipe_integmap(map_combi.A.Jy, param.map.reso, radius_max)
phi_int_b = nika_pipe_integmap(map_combi.B.Jy, param.map.reso, radius_max)

;;------- JK
ordre =  map_list[sort(randomn(seed,n_elements(scan_num)))] ;The 2 sets are equivalent
map_jk = nika_pipe_jackknife(param, ordre)

;;------- Noise map from JK
nika_pipe_noisefromjk, map_jk.A/2.0, map_combi.A.time, stddev_map_a, noise_a, $
                       ps=output_dir+'/'+name4file+'_sensitivity_hist_1mm.ps',nbins=50
nika_pipe_noisefromjk, map_jk.B/2.0, map_combi.B.time, stddev_map_b, noise_b, $
                       ps=output_dir+'/'+name4file+'_sensitivity_hist_2mm.ps',nbins=500

;;************** Make plots **************
;;------- Make a nice plot of the final map
nika_pipe_nicemaps, 300.0, 2, [10.0,10.0], 2, coord_pointing, header, param, map_combi, $
                    output_dir, name4file, source,/sz,range_plot_b=[-13,13]*1e-3,cont_b=[-1e5,-9,-6,-3,3,1e5]*1e-3

;;------- Time per pixel
nika_pipe_plotmapps, map_combi.A.time, output_dir+'/'+name4file+'_time_map_1mm.ps', $
                     source+' - time per pixel at 1 mm (s)', param.map.reso, 0.0
nika_pipe_plotmapps, map_combi.B.time, output_dir+'/'+name4file+'_time_map_2mm.ps', $
                     source+' - time per pixel at 2 mm (s)', param.map.reso, 0.0

;;------- Jack-Knife
nika_pipe_plotmapps, map_jk.A, output_dir+'/'+name4file+'_jk_map_1mm.ps', $
                     source+' - Jack-Knife at 1 mm (Jy/Beam)', param.map.reso, 0.0, range=[-50,50]*1e-3
nika_pipe_plotmapps, map_jk.B, output_dir+'/'+name4file+'_jk_map_2mm.ps', $
                     source+' - Jack-Knife at 2 mm (Jy/Beam)', param.map.reso, 0.00, range=[-10,10]*1e-3

;;------- Noise
nika_pipe_plotmapps, stddev_map_a, output_dir+'/'+name4file+'_stddev_map_1mm.ps', $
                     source+' - Standard deviation at 1 mm (Jy/Beam)', param.map.reso, 0.0, range=[0,50]*1e-3
nika_pipe_plotmapps, stddev_map_b, output_dir+'/'+name4file+'_stddev_map_2mm.ps', $
                     source+' - Standard deviation at 2 mm (Jy/Beam)', param.map.reso, 0.0, range=[0,10]*1e-3

;;------- Profiles
nika_pipe_plotprofileps, prof_a, output_dir+'/'+name4file+'_profile_1mm.ps', source+' - profile at 1 mm (Jy/Beam)',xr=[0,180]
nika_pipe_plotprofileps, prof_b, output_dir+'/'+name4file+'_profile_2mm.ps', source+' - profile at 2 mm (Jy/Beam)',xr=[0,180];,yr=[-0.017,0.00]

;;------- Flux integres
nika_pipe_plotfluxintegps, radius_max, phi_int_a, output_dir+'/'+name4file+'_integrated_flux_1mm.ps', $
                           source+' - integrated flux at 1 mm (Jy/Beam.arcsec!U2!N)'
nika_pipe_plotfluxintegps, radius_max, phi_int_b, output_dir+'/'+name4file+'_integrated_flux_2mm.ps', $
                           source+' - integrated flux at 2 mm (Jy/Beam.arcsec!U2!N)'


stop
end

