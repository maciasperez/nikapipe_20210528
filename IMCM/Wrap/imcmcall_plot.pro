; give fmax= [fluxmax1mm, fluxmax2mm]
; Truncate output map
mamdlib_init, 39
flor = [0, 2, 3, 1]
my_multiplot, 4, 2, pp, pp1, /rev, gap_x=0.05
phi = dindgen(360)*!dtor
flux_list     = dblarr(4)
err_flux_list = dblarr(4)
flux_center_list     = dblarr(4)
err_flux_center_list = dblarr(4)
sigboostarr = dblarr(4)
dp = {noerase:1, coltable:4, imrange:[-1.,1.]*fmax[1], legend_text:'', fwhm:10., $
      xmap:grid.xmap, ymap:grid.ymap, charbar:0.5, charsize:0.5, xtitle:'arcsec', ytitle:''} ; inside_bar:1}
r = 40
;print, param.project_dir+"/iter"+strtrim(iter,2)+"/map.fits"
junk = grid
nk_truncate_filter_map, param, -1, junk, truncate_map = truncate_map
wind, 1, 1, /free, /large
file_plot = plot_dir+'/'+source+'_'+strtrim( method_num, 2) +version+'_iter'+ $
         strtrim( iter, 2)+suffix
outplot, file=file_plot, png=(png ge 1 or pdf ge 1)
;, ps=ps not working (make the pdf out of the png) 
dp.fwhm = !nika.fwhm_nom[1]  ; 18.5
dp.imrange = [-1,1]*fmax[1]  ;; Default is [-1,1]*1d-3
dp.legend_text=titleup+' I2'
imview, grid.map_i2,       dp=dp, position=pp[3,0,*]
delvarx, output_fit_par2
delvarx, dmax_fit               ; dmax_fit = 30
dmax_fit = 100
nk_map_photometry, grid.map_i2, grid.map_var_i2, grid.nhits_2, $
                   grid.xmap, grid.ymap, !nika.fwhm_nom[1], param = param, $
                   flux, sigma_flux, sigma_bg, output_fit_par2, output_fit_par_error2, $
                   bg_rms_source, flux_center, sigma_flux_center, /edu, $
                   grid_step=!nika.grid_step[1], $
                   dmax=dmax_fit, /noplot, truncate_map = truncate_map, $
                   noboost = noboost, sigma_boost = sigma_boost
sigboostarr[3] = sigma_boost
;oplot, output_fit_par2[4] + r*cos(phi), output_fit_par2[5] + r*sin(phi), col=255
flux_list[1]            = 1000.*flux
err_flux_list[1]        = 1000.*sigma_flux
flux_center_list[1]     = 1000.*flux_center
err_flux_center_list[1] = 1000.*sigma_flux_center
;print, '2mm flux, errflux: ', flux_list[1], err_flux_list[1]

dp.legend_text=titledown+' I2' & imview, grid_jk.map_i2,    dp=dp, position=pp[3,1,*]
;oplot, output_fit_par2[4] + r*cos(phi), output_fit_par2[5] + r*sin(phi), col=255

dp.imrange = [-1,1]*fmax[0]  ;; default is [-1,1]*5.d-3
dp.fwhm = !nika.fwhm_nom[0]  ;12.5
dp.legend_text=titleup+' I1' & dp.ytitle='arcsec' & imview, grid.map_i1,       dp=dp, position=pp[0,0,*], $
   title = source+'_'+strtrim( method_num, 2) +'_iter'+ strtrim( iter, 2)+ ' '+suffix
;oplot, output_fit_par2[4] + r*cos(phi), output_fit_par2[5] + r*sin(phi), col=255
dp.legend_text=titledown+' I1' & dp.ytitle='' & imview, grid_jk.map_i1,    dp=dp, position=pp[0,1,*], $
   title = 'Iter '+strtrim(iter, 2)
;oplot, output_fit_par2[4] + r*cos(phi), output_fit_par2[5] + r*sin(phi), col=255
dp.legend_text=titleup+' I3' & imview, grid.map_i3,       dp=dp, position=pp[1,0,*], $
   title = !day
;oplot, output_fit_par2[4] + r*cos(phi), output_fit_par2[5] + r*sin(phi), col=255
dp.legend_text=titledown+' I3' & imview, grid_jk.map_i3,    dp=dp, position=pp[1,1,*]
;oplot, output_fit_par2[4] + r*cos(phi), output_fit_par2[5] + r*sin(phi), col=255
dp.legend_text=titleup+' I 1mm' & imview, grid.map_i_1mm,    dp=dp, position=pp[2,0,*]
;oplot, output_fit_par2[4] + r*cos(phi), output_fit_par2[5] + r*sin(phi), col=255
dp.legend_text=titledown+' I 1mm' & imview, grid_jk.map_i_1mm, dp=dp, position=pp[2,1,*]
;oplot, output_fit_par2[4] + r*cos(phi), output_fit_par2[5] + r*sin(phi), col=255
outplot, /close, /verb

nk_map_photometry, grid.map_i1, grid.map_var_i1, grid.nhits_1, grid.xmap, grid.ymap, $
                   !nika.fwhm_nom[0], param = param, $
                   flux, sigma_flux, sigma_bg, output_fit_par, output_fit_par_err, $
                   bg_rms_source, flux_center, sigma_flux_center, $
                   input_fit_par=output_fit_par2, /edu, grid_step=!nika.grid_step[0], $
                   /noplot, truncate_map = truncate_map, $
                   noboost = noboost, sigma_boost = sigma_boost
sigboostarr[0] = sigma_boost
flux_list[0]            = 1000.*flux
err_flux_list[0]        = 1000.*sigma_flux
flux_center_list[0]     = 1000.*flux_center
err_flux_center_list[0] = 1000.*sigma_flux_center

nk_map_photometry, grid.map_i3, grid.map_var_i3, grid.nhits_3, grid.xmap, grid.ymap, $
                   !nika.fwhm_nom[0], param = param, $
                   flux, sigma_flux, sigma_bg, output_fit_par, output_fit_par_err, $
                   bg_rms_source, flux_center, sigma_flux_center, $
                   input_fit_par=output_fit_par2, /edu, grid_step=!nika.grid_step[2], $
                   /noplot, truncate_map = truncate_map, $
                   noboost = noboost, sigma_boost = sigma_boost
sigboostarr[1] = sigma_boost
flux_list[2]            = 1000.*flux
err_flux_list[2]        = 1000.*sigma_flux
flux_center_list[2]     = 1000.*flux_center
err_flux_center_list[2] = 1000.*sigma_flux_center

nk_map_photometry, grid.map_i_1mm, grid.map_var_i_1mm, grid.nhits_1mm, grid.xmap, grid.ymap, $
                   !nika.fwhm_nom[0], param = param, $
                   flux, sigma_flux, sigma_bg, output_fit_par, output_fit_par_err, $
                   bg_rms_source, flux_center, sigma_flux_center, $
                   input_fit_par=output_fit_par2, /edu, grid_step=!nika.grid_step[2], $
                   /noplot, truncate_map = truncate_map, $
                   noboost = noboost, sigma_boost = sigma_boost
sigboostarr[2] = sigma_boost
flux_list[3]     = 1000.*flux
err_flux_list[3] = 1000.*sigma_flux
flux_center_list[3]     = 1000.*flux_center
err_flux_center_list[3] = 1000.*sigma_flux_center

print, ''
if keyword_set(dmask) then print, 'dmask= '+strtrim(dmask,2)
print, source
;print, param.project_dir+'/iter'+strtrim(iter,2)
print, 'flux (mJy) A1, A3, 1mm, A2:        ', flux_list[flor], format = '(A,4F9.3)'
print, 'err_flux (mJy)            :        ', err_flux_list[flor], format = '(A,4F9.3)'
print, 'flux_center (mJy) A1, A3, 1mm, A2: ', flux_center_list[flor], format = '(A,4F9.3)'
print, 'err_flux_center (mJy)            : ', err_flux_center_list[flor], format = '(A,4F9.3)'
