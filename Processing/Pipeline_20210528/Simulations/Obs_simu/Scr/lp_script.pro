;#########################################################################################
;## Example script which starts the simulation and then the analysis for a given source ##
;#########################################################################################

;------- Properties of the source to be given here ------------------
source = 'Simulated cluster lensed'                           ;Name of the source
version = 'v1'                                                ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_')            ;Name without space but '_'
coord_pointing = {ra:[0.0,0.0,0.0],dec:[+0.0,0.0,0.0]}        ;Pointing coordinates
coord_source = {ra:[0.0,0.0,0.0],dec:[+0.0,0.0,0.0]}          ;centered source

;The scans I want to use and the corresponding days (here M87 scans)
scan_num = [104,105,107,108,109,110,112,113]  
day = '201211'+['24','24','24','24','24','24','24','24']

;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.simu_dir+"/Example_script"
spawn, "mkdir -p "+output_dir

;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param     ;Take the analysis param
partial_simu_default_param, param, 'cluster_lensing' ;and add simulation params to the structure
param.source = source
param.name4file = name4file
param.version = version
param.coord_pointing = coord_pointing
param.coord_source = coord_source
param.output_dir = output_dir

param.pulse_tube.amp *=0
param.simu_glitch.rate = 0
param.atmo.tau0_a = 0
param.atmo.tau0_b = 0
param.atmo.F_0 *= 0
param.atmo.F_el *= 0
param.elec.amp_cor *= 0
param.elec.amp_dec *= 1e-2
param.decor.method = 'none'
num_scan = n_elements(scan_num)

;------- Launch the pipeline -----------------------------------------
;Save the parameter file
save, filename=output_dir+'/param_'+name4file+'_'+version+'.save', param
partial_simu_launch, param
nika_pipe_launch, param, map_combi, map_list, /simu, /save, /png, /ps

;#########################################################################################
;------- Brief analysis examples --------------------------------------
;Restore maps, just for the example since they are here already
map_a = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 0, header)
var_a = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 1, header)
time_a = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 2, header)
map_b = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 3, header)
var_b = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 4, header)
time_b = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 5, header)
map_combi = {A:{Jy:map_a, var:var_a, time:time_a}, B:{Jy:map_b, var:var_b, time:time_b}}
restore, output_dir+'/param_'+name4file+'_'+version+'.save'   ;Param
restore, output_dir+'/maplist_'+name4file+'_'+version+'.save' ;Map per scan

;Profile
center = [-ten(coord_source.ra[0],coord_source.ra[1],coord_source.ra[2])*15.0 + $     ;Position of the source
          ten(coord_pointing.ra[0],coord_pointing.ra[1],coord_pointing.ra[2])*15.0, $ ;on the map
          ten(coord_source.dec[0],coord_source.dec[1],coord_source.dec[2]) - $
          ten(coord_pointing.dec[0],coord_pointing.dec[1],coord_pointing.dec[2])]*3600.0
nika_pipe_profile, param.map.reso, map_combi.b, prof_b, nb_prof=50, center=center
nika_pipe_profile, param.map.reso, map_combi.a, prof_a, nb_prof=50, center=center

;Integrated flux
radius_max = dindgen(15)*10+1   ;maximum radius to compute the integrated flux (arcsec)
phi_int_a = nika_pipe_yinteg(prof_a.r, prof_a.y, radius_max)
phi_int_b = nika_pipe_yinteg(prof_b.r, prof_b.y, radius_max)

;Jack-Knife map
list =  map_list[sort(randomn(seed,n_elements(map_list)))] ;Unorder the maps
map_jk = nika_pipe_jackknife(param, list)

;------- Make example plots --------------------------------------------
nx = (size(map_combi.A.Jy))[1]
ny = (size(map_combi.A.Jy))[2]

window,1, title=source+' - flux at 1 mm (mJy/Beam)'
dispim_bar, 1e3*filter_image(map_combi.a.jy, fwhm=7.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - flux at 1 mm (mJy/Beam)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'

window,2, title=source+' - flux at 2 mm (mJy/Beam)'
dispim_bar, 1e3*filter_image(map_combi.b.jy, fwhm=10.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - flux at 2 mm (mJy/Beam)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'

window,3, title=source+' - time per pixel at 1 mm (s)'
dispim_bar, filter_image(map_combi.a.time, fwhm=0.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - time per pixel at 1 mm (s)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'

window,4, title=source+' - time per pixel at 2 mm (s)'
dispim_bar, filter_image(map_combi.b.time, fwhm=0.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - time per pixel at 2 mm (s)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'

window,5, title=source+' - Jack-Knife at 1 mm (mJy/Beam)'
dispim_bar, 1e3*filter_image(map_jk.a, fwhm=7.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - Jack-Knife at 1 mm (mJy/Beam)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'

window,6, title=source+' - Jack-Knife at 2 mm (mJy/Beam)'
dispim_bar, 1e3*filter_image(map_jk.b, fwhm=10.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - Jack-Knife at 2 mm (mJy/Beam)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'

window,7, title=source+' - profile at 1 mm (Jy/Beam)'
err = prof_a.var
novar = where(err le 0, nnovar)
if nnovar ne 0 then err[where(err le 0)] = 1e3*max(prof_a.var)
ploterror, prof_a.r, prof_a.y, sqrt(err), title=source+' - profile at 1 mm (Jy/Beam)', xtitle='radius (arcsec)', ytitle='Flux (Jy/Beam)'

window,8, title=source+' - profile at 2 mm (Jy/Beam)'
err = prof_b.var
novar = where(err le 0, nnovar)
if nnovar ne 0 then err[where(err le 0)] = 1e3*max(prof_b.var)
ploterror, prof_b.r, prof_b.y, sqrt(err), title=source+' - profile at 2 mm (Jy/Beam)', xtitle='radius (arcsec)', ytitle='Flux (Jy/Beam)'

window,9, title=source+' - integrated flux at 1 mm (Jy/Beam.arcsec^2)'
plot, radius_max, phi_int_a, title=source+' - integrated flux at 1 mm (Jy/Beam.arcsec^2)',xtitle='Integration radius (arcsec)', ytitle='Flux (Jy/Beam.arcsec^2)'

window,10, title=source+' - integrated flux at 2 mm (Jy/Beam.arcsec^2)'
plot, radius_max, phi_int_b, title=source+' - integrated flux at 2 mm (Jy/Beam.arcsec^2)',xtitle='Integration radius (arcsec)', ytitle='Flux (Jy/Beam.arcsec^2)'

stop

end
