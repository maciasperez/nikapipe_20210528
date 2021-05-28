
;------- Properties of the source to be given here ------------------
source = 'Simulation of Uranus'                        ;Name of the source
version = 'v1'                                                ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_')            ;Name without space but '_'
coord_pointing = {ra:[0.0,0.0,0.0],dec:[+0.0,0.0,0.0]}        ;Pointing coordinates
coord_source = {ra:[0.0,0.0,0.0],dec:[+0.0,0.0,0.0]}          ;centered source

;The scans I want to use and the corresponding days (here M87 scans)
scan_num = [222]  
day = '201211'+['22']

;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.simu_dir+"/"+name4file
spawn, "mkdir -p "+output_dir

;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param        ;Take the analysis param
partial_simu_default_param, param, 'point_source'    ;and add simulation params to the structure

param.source = source
param.name4file = name4file
param.version = version
param.coord_pointing = coord_pointing
param.coord_source = coord_source
param.output_dir = output_dir

param.caract_source.flux.A = 51.6
param.caract_source.flux.B = 17.9 

param.decor.method = 'COMMON_MODE_KIDS_OUT'
param.decor.common_mode.d_min = 40.0
param.map.reso = 2
param.map.size_ra = 600
param.map.size_dec = 600

;------- Launch the pipeline -----------------------------------------
partial_simu_launch, param
nika_pipe_launch, param, map_combi, map_list, /simu, /save, /ps
save, filename=output_dir+'/param_'+name4file+'_'+version+'.save', param


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
restore, output_dir+'/param_'+name4file+'_'+version+'.save'     ;Param
restore, output_dir+'/maplist_'+name4file+'_'+version+'.save'   ;Map per scan

;;------- Zero level correction
center = [-ten(coord_source.ra[0],coord_source.ra[1],coord_source.ra[2])*15.0 + $     ;Position of the source
          ten(coord_pointing.ra[0],coord_pointing.ra[1],coord_pointing.ra[2])*15.0, $ ;on the map
          ten(coord_source.dec[0],coord_source.dec[1],coord_source.dec[2]) - $
          ten(coord_pointing.dec[0],coord_pointing.dec[1],coord_pointing.dec[2])]*3600.0
nx = (size(map_a))[1]           
ny = (size(map_a))[2]           
xmap = param.map.reso*(replicate(1, ny) ## dindgen(nx)) - param.map.reso*(nx-1)/2.0 - center[0]
ymap = param.map.reso*(replicate(1, nx) #  dindgen(ny)) - param.map.reso*(ny-1)/2.0 - center[1]
rmap = sqrt(xmap^2 + ymap^2)  
zer_a = mean(map_a[where(rmap gt 50.0 and var_a gt 0)])
zer_b = mean(map_b[where(rmap gt 50.0 and var_b gt 0)])

map_a = map_a - zer_a
map_b = map_b - zer_b
map_combi = {A:{Jy:map_a, var:var_a, time:time_a}, B:{Jy:map_b, var:var_b, time:time_b}}

;;------- Fit Gaussien du beam
beamfit_a = GAUSS2DFIT(map_a, coeff_a, /tilt) 
beamfit_b = GAUSS2DFIT(map_b, coeff_b, /tilt) 
fwhm_a = max(coeff_a[2:3]) / !fwhm2sigma * param.map.reso
fwhm_b = max(coeff_b[2:3]) / !fwhm2sigma * param.map.reso

beam_mod_a = exp(-rmap^2/2.0/(fwhm_a*!fwhm2sigma)^2)
beam_mod_b = exp(-rmap^2/2.0/(fwhm_b*!fwhm2sigma)^2)

;;------- Profile
nika_pipe_profile, param.map.reso, map_combi.b, prof_b, nb_prof=50, center=center
nika_pipe_profile, param.map.reso, map_combi.a, prof_a, nb_prof=50, center=center

prof_gauss_a = coeff_a[1]*exp(-prof_a.r^2/(2.0*(fwhm_a * !fwhm2sigma)^2)) ;Model of the beam
prof_gauss_b = coeff_b[1]*exp(-prof_b.r^2/(2.0*(fwhm_b * !fwhm2sigma)^2))

;;------- Integrated flux
rmax = 200.0
radius_max = dindgen(100)/99*rmax+5 ;maximum radius to compute the integrated flux (arcsec)
phi_int_a = nika_pipe_integmap(map_a, param.map.reso, radius_max)
phi_int_b = nika_pipe_integmap(map_b, param.map.reso, radius_max)
phi_int_fit_a = nika_pipe_integmap(beam_mod_a, param.map.reso, radius_max)
phi_int_fit_b = nika_pipe_integmap(beam_mod_b, param.map.reso, radius_max)

;;------- Make a nice plot of the final map
fov_plot = 400.0                          ;Field of view of the nice plot
reso_plot = 2.0                           ;Resolution of the nice plot
coord_plot = [ten(coord_pointing.ra[0],coord_pointing.ra[1],coord_pointing.ra[2])*15.0,$ ;Center of the nice plot
              ten(coord_pointing.dec[0],coord_pointing.dec[1],coord_pointing.dec[2])]    ;
relob = 0.0                               ;resmoothing FWHM of the map for the plot
nsig_max = 40.0                           ;Show the map up to nsig_max times the min noise level
;;
map_plot_a = filter_image(map_a, fwhm=relob/param.map.reso,/all) - coeff_a[0]  ;Smooth the map to be plotted
map_plot_b = filter_image(map_b, fwhm=relob/param.map.reso,/all) - coeff_b[0]  ;
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
                        range=range_plot_a, conts1=[-1e6,-1.0/[10,100,1000],1.0/[1000,100,10],1e6]*max(range_plot_a),$
                        colconts1=[255],thickcont1=1.5,conts2=[-1e10,1e10],$  
                        ;anotconts1='max/'+strmid(strtrim([-1e6,10,100,1000,10000,1e6],2),0,4),$
                        ;anothick1=1,$         
                        beam=sqrt(12.5^2+relob^2), bg1=10*max(range_plot_a)

overplot_radec_bar_map, map_plot_b, header, map_plot_b, header, fov_plot, reso_plot, coord_plot,$
                        postscript=output_dir+'/'+name4file+'_2mm.ps', title=source+' at 2.05 mm',$
                        bartitle='Jy/Beam', xtitle='!4a!X!I2000!N (hr)', ytitle='!4d!X!I2000!N (degree)',$
                        barcharthick=2, mapcharthick=2, barcharsize=1, mapcharsize=1,$
                        range=range_plot_b, conts1=[-1e6,-1.0/[10,100,1000],1.0/[1000,100,10],1e6]*max(range_plot_B),$
                        colconts1=255, thickcont1=1.5,conts2=[-1e10,1e10],$         
                        ;anotconts1='max/'+strmid(strtrim([-1e6,10,100,1000,10000,1e6],2),0,4),$
                        ;anothick1=1,$          
                        beam=sqrt(12.5^2+relob^2), bg1=1e5*max(range_plot_b)

;;-------------- Make example plots ---------------------------------
ps = 'yes'

!p.charthick=2

if ps eq 'yes' then set_plot, 'PS'

;;Profile 1mm
if ps ne 'yes' then window,1, title=source+' - profile at 1 mm (Jy/Beam)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_profile_1mm.ps'
err = prof_a.var
novar = where(err le 0, nnovar)
if nnovar ne 0 then err[where(err le 0)] = 1e3*max(prof_a.var)
ploterror, prof_a.r, prof_a.y/coeff_a[1], sqrt(err)/coeff_a[1], $
           title=source+' - normalized profile at 1 mm', $
           xtitle='radius (arcsec)', ytitle='Normalized flux',$
           psym=1, /xlog,/ylog,yrange=[1e-7,1],xrange=[1,300], ystyle=1, xstyle=1,/nodata
oploterror, prof_a.r, abs(prof_a.y)/coeff_a[1], sqrt(err)/coeff_a[1], col=200, errcolor=100,errthick=2,$
            psym=8, symsize=0.7 ;abs(data)
oploterror, prof_a.r, prof_a.y/coeff_a[1], sqrt(err)/coeff_a[1], col=50, errcolor=100,errthick=2,$
            psym=8, symsize=0.7 ;data
oplot, prof_a.r, prof_gauss_a/coeff_a[1], col=250
legend,['Data', '- Data', 'Gaussian model'],charsize=1,charthick=3,bthick=3,col=[50,200,250], psym=[8,8,0],$
          thick=[1,1,5],symsize=[1,1,3], /left,/bottom
if ps eq 'yes' then device,/close

;;Profile 2mm
if ps ne 'yes' then window,2, title=source+' - profile at 2 mm (Jy/Beam)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_profile_2mm.ps'
err = prof_b.var
novar = where(err le 0, nnovar)
if nnovar ne 0 then err[where(err le 0)] = 1e3*max(prof_b.var)
ploterror, prof_b.r, prof_b.y/coeff_b[1], sqrt(err)/coeff_b[1], $
           title=source+' - normalized profile at 2 mm', $
           xtitle='radius (arcsec)', ytitle='Normalized flux',$
           psym=1, /xlog,/ylog,yrange=[1e-7,1],xrange=[1,300], ystyle=1, xstyle=1,/nodata
oploterror, prof_b.r, abs(prof_b.y)/coeff_b[1], sqrt(err)/coeff_b[1], col=200, errcolor=100,errthick=2,$
            psym=8, symsize=0.7 ;abs(data)
oploterror, prof_b.r, prof_b.y/coeff_b[1], sqrt(err)/coeff_b[1], col=50, errcolor=100,errthick=2,$
            psym=8, symsize=0.7
oplot, prof_b.r, prof_gauss_b/coeff_b[1], col=250
legend,['Data', '- Data', 'Gaussian model'],charsize=1,charthick=3,bthick=3,col=[50, 200, 250], psym=[8,8,0],$
          thick=[1,1,5],symsize=[1,1,3], /left,/bottom
if ps eq 'yes' then device,/close

;;Flux integre 1mm
if ps ne 'yes' then window,3, title=source+' - integrated flux at 1 mm (Jy/Beam.arcsec^2)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_integrated_flux_1mm.ps'
plot, radius_max, phi_int_a, title=source+' - integrated flux at 1 mm (Jy/Beam.arcsec!U2!N)',xtitle='Integration radius (arcsec)', ytitle='Flux (Jy/Beam.arcsec!U2!N)', /nodata
oplot, radius_max, phi_int_a, col=50, thick=2
oplot, radius_max, phi_int_fit_a*coeff_a[1], col=250, thick=2
oplot, radius_max, radius_max*0 + 2*!pi*(fwhm_a*!fwhm2sigma)^2*coeff_a[1], col=150, line=2, thick=2
legend,['Data', 'Gaussian model of the beam','Total flux limit from the gaussian model'],$
       charsize=1,charthick=3,bthick=3,col=[50,250,150], psym=[0,0,0],$
       thick=[8,8,8],symsize=[1,1,1],line=[0,0,1], /right, /bottom
if ps eq 'yes' then device,/close

;;Flux integ 2mm
if ps ne 'yes' then window,4, title=source+' - integrated flux at 2 mm (Jy/Beam.arcsec^2)'
if ps eq 'yes' then device,/color, bits_per_pixel=256, filename=output_dir+'/'+name4file+'_integrated_flux_2mm.ps'
plot, radius_max, phi_int_b, title=source+' - integrated flux at 2 mm (Jy/Beam.arcsec!U2!N)',xtitle='Integration radius (arcsec)', ytitle='Flux (Jy/Beam.arcsec!U2!N)', /nodata
oplot, radius_max, phi_int_b, col=50, thick=2
oplot, radius_max, phi_int_fit_b*coeff_b[1], col=250, thick=2
oplot, radius_max, radius_max*0 + 2*!pi*(fwhm_b*!fwhm2sigma)^2*coeff_b[1], col=150, line=2, thick=2
legend,['Data', 'Gaussian model of the beam','Total flux limit from the gaussian model'],$
       charsize=1,charthick=3,bthick=3,col=[50,250,150], psym=[0,0,0],$
       thick=[8,8,8],symsize=[1,1,1],line=[0,0,1], /right, /bottom
if ps eq 'yes' then device,/close

set_plot, 'X'

stop
end

