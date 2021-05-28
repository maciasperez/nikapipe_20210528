; S/N instead of flux
my_multiplot, 4, 2, pp, pp1, /rev, gap_x=0.05
phi = dindgen(360)*!dtor
; map_sn is already smoothed
dp = {noerase:1, coltable:4, imrange:snr_range, legend_text:'', $ ;  NO MORE fwhm:10., $
      xmap:grid.xmap, ymap:grid.ymap, charbar:0.5, charsize:0.5, xtitle:'arcsec', ytitle:''} ; inside_bar:1}
;; dp = {noerase:1, coltable:4, imrange:[-3.,3.], legend_text:'', fwhm:10., $
;;       xmap:grid.xmap, ymap:grid.ymap, charbar:0.5, charsize:0.5,
;;       xtitle:'arcsec', ytitle:''} ; inside_bar:1}  ; Default
r = 40
;print, param.project_dir+"/iter"+strtrim(iter,2)+"/map.fits"
wind, 1, 1, /free, /large
file_plot = plot_dir+'/'+source+'_'+strtrim( method_num, 2)+version +'_iter'+ $
            strtrim( iter, 2)+'_SNR'+suffix
outplot, file=file_plot, png=(png ge 1 or pdf ge 1)
;, ps=ps not working (make the pdf out of the png) 
delvarx, output_fit_par2
delvarx, dmax_fit               ; dmax_fit = 30
;dmax_fit = 100
nk_map_photometry, grid.map_i2, grid.map_var_i2, grid.nhits_2, $
                   grid.xmap, grid.ymap, !nika.fwhm_nom[1], $
                   flux, sigma_flux, sigma_bg, output_fit_par2, output_fit_par_error2, $
                   bg_rms_source, flux_center, sigma_flux_center, /edu, $
                   grid_step=!nika.grid_step[1], map_flux = map_flux, map_var_flux = map_var_flux, $
                   dmax=dmax_fit, /noplot, param = param, truncate_map = truncate_map, map_sn = map_sn, noboost = noboost
gdpix = where( truncate_map gt 0.99, ngdpix)
imap = 3
if ngdpix ge 10 then begin
   diff_stat[imap,iter].mean   = mean(   map_sn[ gdpix])
   diff_stat[imap,iter].min    = min(    map_sn[ gdpix])
   diff_stat[imap,iter].max    = max(    map_sn[ gdpix])
   diff_stat[imap,iter].median = median( map_sn[ gdpix])
   diff_stat[imap,iter].stddev = stddev( map_sn[ gdpix])
endif

;;;;;;;;;;;;;;;;;;;  SHOULD we SMOOTH AGAIN?      No, already done
;; dp.fwhm = !nika.fwhm_nom[1]  ; 18.5
dp.legend_text=titleup+' I2'
imview, map_sn, dp=dp, position=pp[3,0,*]

nk_map_photometry, grid_jk.map_i2, grid_jk.map_var_i2, grid_jk.nhits_2, $
                   grid_jk.xmap, grid_jk.ymap, !nika.fwhm_nom[1], $
                   flux, sigma_flux, sigma_bg, output_fit_par2, output_fit_par_error2, $
                   bg_rms_source, flux_center, sigma_flux_center, /edu, $
                   grid_step=!nika.grid_step[1], map_flux = map_flux, map_var_flux = map_var_flux, $
                   dmax=dmax_fit, /noplot, param = param, truncate_map = truncate_map, map_sn = map_sn, noboost = noboost
if ngdpix ge 10 then begin
   diff_stat_jk[imap,iter].mean   = mean(   map_sn[ gdpix])
   diff_stat_jk[imap,iter].min    = min(    map_sn[ gdpix])
   diff_stat_jk[imap,iter].max    = max(    map_sn[ gdpix])
   diff_stat_jk[imap,iter].median = median( map_sn[ gdpix])
   diff_stat_jk[imap,iter].stddev = stddev( map_sn[ gdpix])
endif
dp.legend_text=titledown+' I2' & imview, map_sn,    dp=dp, position=pp[3,1,*]

; 1mm
nk_map_photometry, grid.map_i1, grid.map_var_i1, grid.nhits_1, grid.xmap, grid.ymap, $
                   !nika.fwhm_nom[0], $
                   flux, sigma_flux, sigma_bg, output_fit_par, output_fit_par_err, $
                   bg_rms_source, flux_center, sigma_flux_center, $
                   input_fit_par=output_fit_par2, /edu, grid_step=!nika.grid_step[0], $
                   map_flux = map_flux, map_var_flux = map_var_flux, $
                   /noplot, param = param, truncate_map = truncate_map, $
                   map_sn = map_sn, noboost = noboost
imap = 0
if ngdpix ge 10 then begin
   diff_stat[imap,iter].mean   = mean(   map_sn[ gdpix])
   diff_stat[imap,iter].min    = min(    map_sn[ gdpix])
   diff_stat[imap,iter].max    = max(    map_sn[ gdpix])
   diff_stat[imap,iter].median = median( map_sn[ gdpix])
   diff_stat[imap,iter].stddev = stddev( map_sn[ gdpix])
endif
mamdlib_init, 39
;;dp.fwhm = !nika.fwhm_nom[0]  ; 12.5
dp.legend_text=titleup+' I1' & dp.ytitle='arcsec' & imview,map_sn, $
   dp=dp, position=pp[0,0,*], $
   title = 'SNR '+ source+'_'+strtrim( method_num, 2) +'_iter'+ strtrim( iter, 2)+ ' '+suffix

nk_map_photometry, grid_jk.map_i1, grid_jk.map_var_i1, grid_jk.nhits_1, grid_jk.xmap, grid_jk.ymap, $
                   !nika.fwhm_nom[0], $
                   flux, sigma_flux, sigma_bg, output_fit_par, output_fit_par_err, $
                   bg_rms_source, flux_center, sigma_flux_center, $
                   input_fit_par=output_fit_par2, /edu, grid_step=!nika.grid_step[0], $
                   map_flux = map_flux, map_var_flux = map_var_flux, $
                   /noplot, param = param, truncate_map = truncate_map, map_sn = map_sn, noboost = noboost

if ngdpix ge 10 then begin
   diff_stat_jk[imap,iter].mean   = mean(   map_sn[ gdpix])
   diff_stat_jk[imap,iter].min    = min(    map_sn[ gdpix])
   diff_stat_jk[imap,iter].max    = max(    map_sn[ gdpix])
   diff_stat_jk[imap,iter].median = median( map_sn[ gdpix])
   diff_stat_jk[imap,iter].stddev = stddev( map_sn[ gdpix])
endif
dp.legend_text=titledown+' I1' & dp.ytitle='' & imview, map_sn,  dp=dp, position=pp[0,1,*], title = !day

nk_map_photometry, grid.map_i3, grid.map_var_i3, grid.nhits_1, grid.xmap, grid.ymap, $
                   !nika.fwhm_nom[0], $
                   flux, sigma_flux, sigma_bg, output_fit_par, output_fit_par_err, $
                   bg_rms_source, flux_center, sigma_flux_center, $
                   input_fit_par=output_fit_par2, /edu, grid_step=!nika.grid_step[0], $
                   map_flux = map_flux, map_var_flux = map_var_flux, $
                   /noplot, param = param, truncate_map = truncate_map, map_sn = map_sn, noboost = noboost

imap = 1
if ngdpix ge 10 then begin
   diff_stat[imap,iter].mean   = mean(   map_sn[ gdpix])
   diff_stat[imap,iter].min    = min(    map_sn[ gdpix])
   diff_stat[imap,iter].max    = max(    map_sn[ gdpix])
   diff_stat[imap,iter].median = median( map_sn[ gdpix])
   diff_stat[imap,iter].stddev = stddev( map_sn[ gdpix])
endif
dp.legend_text=titleup+' I3' & imview,map_sn,       dp=dp, position=pp[1,0,*]
nk_map_photometry, grid_jk.map_i3, grid_jk.map_var_i3, grid_jk.nhits_3, grid_jk.xmap, grid_jk.ymap, $
                   !nika.fwhm_nom[0], $
                   flux, sigma_flux, sigma_bg, output_fit_par, output_fit_par_err, $
                   bg_rms_source, flux_center, sigma_flux_center, $
                   input_fit_par=output_fit_par2, /edu, grid_step=!nika.grid_step[0], $
                   map_flux = map_flux, map_var_flux = map_var_flux, $
                   /noplot, param = param, truncate_map = truncate_map, map_sn = map_sn, noboost = noboost
if ngdpix ge 10 then begin
   diff_stat_jk[imap,iter].mean   = mean(   map_sn[ gdpix])
   diff_stat_jk[imap,iter].min    = min(    map_sn[ gdpix])
   diff_stat_jk[imap,iter].max    = max(    map_sn[ gdpix])
   diff_stat_jk[imap,iter].median = median( map_sn[ gdpix])
   diff_stat_jk[imap,iter].stddev = stddev( map_sn[ gdpix])
endif
dp.legend_text=titledown+' I3' & imview, map_sn,    dp=dp, position=pp[1,1,*]

nk_map_photometry, grid.map_i_1mm, grid.map_var_i_1mm, grid.nhits_1mm, grid.xmap, grid.ymap, $
                   !nika.fwhm_nom[0], $
                   flux, sigma_flux, sigma_bg, output_fit_par, output_fit_par_err, $
                   bg_rms_source, flux_center, sigma_flux_center, $
                   input_fit_par=output_fit_par2, /edu, grid_step=!nika.grid_step[0], $
                   map_flux = map_flux, map_var_flux = map_var_flux, $
                   /noplot, param = param, truncate_map = truncate_map, map_sn = map_sn, noboost = noboost

imap = 2
if ngdpix ge 10 then begin
   diff_stat[imap,iter].mean   = mean(   map_sn[ gdpix])
   diff_stat[imap,iter].min    = min(    map_sn[ gdpix])
   diff_stat[imap,iter].max    = max(    map_sn[ gdpix])
   diff_stat[imap,iter].median = median( map_sn[ gdpix])
   diff_stat[imap,iter].stddev = stddev( map_sn[ gdpix])
endif
dp.legend_text=titleup+' I 1mm' & imview, map_sn,   dp=dp, position=pp[2,0,*]
nk_map_photometry, grid_jk.map_i_1mm, grid_jk.map_var_i_1mm, grid_jk.nhits_1mm, grid_jk.xmap, grid_jk.ymap, $
                   !nika.fwhm_nom[0], $
                   flux, sigma_flux, sigma_bg, output_fit_par, output_fit_par_err, $
                   bg_rms_source, flux_center, sigma_flux_center, $
                   input_fit_par=output_fit_par2, /edu, grid_step=!nika.grid_step[0], $
                   map_flux = map_flux, map_var_flux = map_var_flux, $
                   /noplot, param = param, truncate_map = truncate_map, map_sn = map_sn, noboost = noboost
if ngdpix ge 10 then begin
   diff_stat_jk[imap,iter].mean   = mean(   map_sn[ gdpix])
   diff_stat_jk[imap,iter].min    = min(    map_sn[ gdpix])
   diff_stat_jk[imap,iter].max    = max(    map_sn[ gdpix])
   diff_stat_jk[imap,iter].median = median( map_sn[ gdpix])
   diff_stat_jk[imap,iter].stddev = stddev( map_sn[ gdpix])
endif
dp.legend_text=titledown+' I 1mm' & imview, map_sn, dp=dp, position=pp[2,1,*]
outplot, /close, /verb
