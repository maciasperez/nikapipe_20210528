;#########################################################################################
;## Example script which starts the simulation and then the analysis for a given source ##
;#########################################################################################

;------- Properties of the source to be given here ------------------
source = 'Simulated SZ cluster'                        ;Name of the source
version = 'v1'                                         ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_')     ;Name without space but '_'
coord_pointing = {ra:[0.0,0.0,0.0],dec:[+0.0,0.0,0.0]} ;Pointing coordinates
coord_source = {ra:[0.0,0.0,0.0],dec:[+0.0,0.0,0.0]}   ;centered source

;The scans I want to use and the corresponding days (here M87 scans)
scan_num = [89,90,92,93,94,95,97,98,99,100,102,103,104,105,107,108,109,110,112,113,114,115,117,118]
day = '201211'+strarr(n_elements(scan_num))+'23'

;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.simu_dir+"/SZ_Cluster_Simulation"
spawn, "mkdir -p "+output_dir

;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param ;Take the analysis param
partial_simu_default_param, param, 'cluster'  ;and add simulation params to the structure
param.source = source
param.name4file = name4file
param.version = version
param.coord_pointing = coord_pointing
param.coord_source = coord_source
param.output_dir = output_dir
param.decor.method = 'dual_band_freq'
param.map.reso = 5
param.w8.dist_off_source = 0
param.w8.per_subscan = 'no'

;------- Launch the pipeline -----------------------------------------
save, filename=output_dir+'/param_'+name4file+'_'+version+'.save', param
partial_simu_launch, param
nika_pipe_launch, param, map_combi, map_list, /simu, /save, /ps, /map_per_kid


;;#########################################################################################
;;########################## Brief analysis examples ######################################
;;#########################################################################################

;;------- Restore maps, just for the example since they are already there
map_a = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 0, header)
var_a = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 1, header)
time_a = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 2, header)
map_b = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 3, header)
var_b = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 4, header)
time_b = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 5, header)
map_combi = {A:{Jy:map_a, var:var_a, time:time_a}, B:{Jy:map_b, var:var_b, time:time_b}}
restore, output_dir+'/param_'+name4file+'_'+version+'.save'     ;Param
restore, output_dir+'/maplist_'+name4file+'_'+version+'.save'   ;Map per scan
restore, output_dir+'/mapperkid_'+name4file+'_'+version+'.save' ;Map per kid

;;------- Make a nice plot of the final map
fov_plot = 400.0                          ;Field of view of the nice plot
reso_plot = 2.0                           ;Resolution of the nice plot
coord_plot = [ten(0.0,0.0,0.0)*15.0,$ ;Center of the nice plot
              ten(0.0,0.0,0.0)]        ;
relob = 10.0                               ;resmoothing FWHM of the map for the plot
nsig_max = 3.0                          ;Show the map up to nsig_max times the min noise level
;;
map_plot_a = filter_image(map_a,fwhm=relob/param.map.reso,/all)                ;Smooth the map to be plotted
map_plot_b = filter_image(map_b,fwhm=relob/param.map.reso,/all)                ;
var_plot_a = var_a                                                             ;
var_plot_b = var_b                                                             ;
loc_out_var_a = where(var_a le 0, nloc_out_var_a)                              ;
loc_out_var_b = where(var_b le 0, nloc_out_var_b)                              ;
if nloc_out_var_a ne 0 then var_plot_a[loc_out_var_a] = max(var_plot_a)        ;set undef var to max(var)
if nloc_out_var_b ne 0 then var_plot_b[loc_out_var_b] = max(var_plot_b)        ;
loc_out_a = where(filter_image(var_plot_a, fwhm=10.0/param.map.reso,/all) gt $ ;get the location not shown
                  nsig_max^2*min(filter_image(var_plot_a, fwhm=10.0/param.map.reso,/all)), nloc_out_a, $
                  comp=loc_in_a)
if nloc_out_a ne 0 then map_plot_a[loc_out_a] = 10*max(map_plot_a)
loc_out_b = where(filter_image(var_plot_b, fwhm=10.0/param.map.reso,/all) gt $
                  nsig_max^2*min(filter_image(var_plot_b, fwhm=10.0/param.map.reso,/all)), nloc_out_b, $
                  comp=loc_in_b)
if nloc_out_b ne 0 then map_plot_b[loc_out_b] = 10*max(map_plot_b)

range_plot_a = minmax(map_plot_a[loc_in_a]) ;get the range for the plot
range_plot_b = minmax(map_plot_b[loc_in_b]) ;

overplot_radec_bar_map, map_plot_a, header, map_plot_a, header, fov_plot, reso_plot, coord_plot,$
                        postscript=output_dir+'/'+name4file+'_1mm.ps', title=source+' at 1.25 mm',$
                        bartitle='Jy/Beam', xtitle='!4a!X!I2000!N (hr)', ytitle='!4d!X!I2000!N (degree)',$
                        barcharthick=2, mapcharthick=2, barcharsize=1, mapcharsize=1,$
                        range=range_plot_a, conts1=[-1e5,-0.6,-0.4,-0.2,0.2,0.4,0.6,1e5]*max(range_plot_a),$
                        colconts1=0, thickcont1=1.5,conts2=[-1e10,1e10],$         
                        ;anotconts1=strmid(strtrim([-1e5,0.05,0.1,0.2,0.4,0.6,0.8,1e5]*100.0,2),0,4)+'%',$
                        ;anothick1=3,$         
                        beam=sqrt(12.5^2+relob^2),/type, bg1=1e5*max(range_plot_a)

overplot_radec_bar_map, map_plot_b, header, map_plot_b, header, fov_plot, reso_plot, coord_plot,$
                        postscript=output_dir+'/'+name4file+'_2mm.ps', title=source+' at 2.05 mm',$
                        bartitle='Jy/Beam', xtitle='!4a!X!I2000!N (hr)', ytitle='!4d!X!I2000!N (degree)',$
                        barcharthick=2, mapcharthick=2, barcharsize=1, mapcharsize=1,$
                        range=range_plot_b, conts1=[-1e5,-0.6,-0.4,-0.2,0.2,0.4,0.6,1e5]*max(range_plot_B),$
                        colconts1=0, thickcont1=1.5,conts2=[-1e10,1e10],$         
                        ;anotconts1=strmid(strtrim([-1e5,0.05,0.1,0.2,0.4,0.6,0.8,1e5]*100.0,2),0,4)+'%',$
                        ;anothick1=3,$          
                        beam=sqrt(12.5^2+relob^2),/type, bg1=1e5*max(range_plot_b)

;;------- Profile
center = [-ten(coord_source.ra[0],coord_source.ra[1],coord_source.ra[2])*15.0 + $     ;Position of the source
          ten(coord_pointing.ra[0],coord_pointing.ra[1],coord_pointing.ra[2])*15.0, $ ;on the map
          ten(coord_source.dec[0],coord_source.dec[1],coord_source.dec[2]) - $
          ten(coord_pointing.dec[0],coord_pointing.dec[1],coord_pointing.dec[2])]*3600.0
nika_pipe_profile, param.map.reso, map_combi.b, prof_b, nb_prof=50, center=center
nika_pipe_profile, param.map.reso, map_combi.a, prof_a, nb_prof=50, center=center

;;------- Integrated flux
radius_max = dindgen(15)*10+1   ;maximum radius to compute the integrated flux (arcsec)
phi_int_a = nika_pipe_yinteg(prof_a.r, prof_a.y, radius_max)
phi_int_b = nika_pipe_yinteg(prof_b.r, prof_b.y, radius_max)

;;------- Jack-Knife map
;list =  map_list[sort(randomn(seed,n_elements(map_list)))] ;Random order of the maps
list =  map_list[[0,1,4,5,2,3,6,7]]                        ;2 azim and 2 elev VS 2 azim and 2 elev
map_jk = nika_pipe_jackknife(param, list)

;;-------------- Make example plots ---------------------------------
ps = 'yes'
nx = (size(map_combi.A.Jy))[1]
ny = (size(map_combi.A.Jy))[2]

if ps eq 'yes' then set_plot, 'PS'

if ps ne 'yes' then window,1, title=source+' - flux at 1 mm (mJy/Beam)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_flux_map_1mm.ps'
dispim_bar, 1e3*filter_image(map_combi.a.jy, fwhm=7.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - flux at 1 mm (mJy/Beam)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'
if ps eq 'yes' then device,/close

if ps ne 'yes' then window,2, title=source+' - flux at 2 mm (mJy/Beam)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_flux_map_2mm.ps'
dispim_bar, 1e3*filter_image(map_combi.b.jy, fwhm=10.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - flux at 2 mm (mJy/Beam)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'
if ps eq 'yes' then device,/close

if ps ne 'yes' then window,3, title=source+' - time per pixel at 1 mm (s)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_time_map_1mm.ps'
dispim_bar, filter_image(map_combi.a.time, fwhm=0.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - time per pixel at 1 mm (s)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'
if ps eq 'yes' then device,/close

if ps ne 'yes' then window,4, title=source+' - time per pixel at 2 mm (s)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_time_map_2mm.ps'
dispim_bar, filter_image(map_combi.b.time, fwhm=0.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - time per pixel at 2 mm (s)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'
if ps eq 'yes' then device,/close

if ps ne 'yes' then window,5, title=source+' - Jack-Knife at 1 mm (mJy/Beam)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_jack-knife_1mm.ps'
dispim_bar, 1e3*filter_image(map_jk.a, fwhm=7.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - Jack-Knife at 1 mm (mJy/Beam)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'
if ps eq 'yes' then device,/close

if ps ne 'yes' then window,6, title=source+' - Jack-Knife at 2 mm (mJy/Beam)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_jack-knife_2mm.ps'
dispim_bar, 1e3*filter_image(map_jk.b, fwhm=10.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - Jack-Knife at 2 mm (mJy/Beam)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'
if ps eq 'yes' then device,/close

if ps ne 'yes' then window,7, title=source+' - profile at 1 mm (Jy/Beam)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_profile_1mm.ps'
err = prof_a.var
novar = where(err le 0, nnovar)
if nnovar ne 0 then err[where(err le 0)] = 1e3*max(prof_a.var)
ploterror, prof_a.r, prof_a.y, sqrt(err), title=source+' - profile at 1 mm (Jy/Beam)', xtitle='radius (arcsec)', ytitle='Flux (Jy/Beam)'
if ps eq 'yes' then device,/close

if ps ne 'yes' then window,8, title=source+' - profile at 2 mm (Jy/Beam)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_profile_2mm.ps'
err = prof_b.var
novar = where(err le 0, nnovar)
if nnovar ne 0 then err[where(err le 0)] = 1e3*max(prof_b.var)
ploterror, prof_b.r, prof_b.y, sqrt(err), title=source+' - profile at 2 mm (Jy/Beam)', xtitle='radius (arcsec)', ytitle='Flux (Jy/Beam)'
if ps eq 'yes' then device,/close

if ps ne 'yes' then window,9, title=source+' - integrated flux at 1 mm (Jy/Beam.arcsec^2)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_integrated_flux_1mm.ps'
plot, radius_max, phi_int_a, title=source+' - integrated flux at 1 mm (Jy/Beam.arcsec!U2!N)',xtitle='Integration radius (arcsec)', ytitle='Flux (Jy/Beam.arcsec^2)'
if ps eq 'yes' then device,/close

if ps ne 'yes' then window,10, title=source+' - integrated flux at 2 mm (Jy/Beam.arcsec^2)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_integrated_flux_2mm.ps'
plot, radius_max, phi_int_b, title=source+' - integrated flux at 2 mm (Jy/Beam.arcsec!U2!N)',xtitle='Integration radius (arcsec)', ytitle='Flux (Jy/Beam.arcsec^2)'
if ps eq 'yes' then device,/close

if ps ne 'yes' then window,11, title=source+' - map KID1 (mJy/Beam)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_mapKID1.ps'
dispim_bar, 1e3*filter_image(map_per_kid[1].jy, fwhm=10.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - map KID1 (mJy/Beam)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'
if ps eq 'yes' then device,/close

if ps ne 'yes' then window,12, title=source+' - map KID2 (mJy/Beam)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_mapKID2.ps'
dispim_bar, 1e3*filter_image(map_per_kid[2].jy, fwhm=10.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - map KID1 (mJy/Beam)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'
if ps eq 'yes' then device,/close

if ps ne 'yes' then window,13, title=source+' - map KID3 (mJy/Beam)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_mapKID3.ps'
dispim_bar, 1e3*filter_image(map_per_kid[3].jy, fwhm=10.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - map KID1 (mJy/Beam)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'
if ps eq 'yes' then device,/close

if ps ne 'yes' then window,14, title=source+' - map KID4 (mJy/Beam)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_mapKID4.ps'
dispim_bar, 1e3*filter_image(map_per_kid[4].jy, fwhm=10.0/param.map.reso,/all), /aspect, /nocont, xmap=dindgen(nx)*param.map.reso - nx/2*param.map.reso, ymap=dindgen(ny)*param.map.reso - nx/2*param.map.reso, title=source+' - map KID1 (mJy/Beam)', xtitle='R.A. offset (arcsec)', ytitle='DEC. offset (arcsec)'
if ps eq 'yes' then device,/close


set_plot, 'X'
stop
end

