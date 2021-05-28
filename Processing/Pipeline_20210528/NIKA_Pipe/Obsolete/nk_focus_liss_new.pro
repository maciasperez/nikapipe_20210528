

;pro nk_focus_liss_new, scan, pako_str, param=param, $
;                       one_mm_only = one_mm_only, two_mm_only = two_mm_only, $
;                       educated=educated,  $
;                       rf = rf, xml=xml


scan = '20151010s164'
scan2daynum, scan, day, scan_num
if file_test(!nika.xml_dir+"/iram30m-scan-"+scan+".xml") eq 0 then begin
   message, /info, "copying xml file from mrt-lx1"
   spawn, "scp t22@150.214.224.59:/ncsServer/mrt/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/iram*xml $XML_DIR/."
endif
if file_test(!nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits") eq 0 then begin
   message, /info, "copying imbfits file from mrt-lx1"
   spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/*antenna*fits $IMB_FITS_DIR/."
endif

if not keyword_set(param) then nk_default_param,  param
if keyword_set(one_mm_only) then param.one_mm_only = one_mm_only
if keyword_set(two_mm_only) then param.two_mm_only = two_mm_only

param.math = "RF"

param.decor_per_subscan = 1 ; make sure here
param.interpol_common_mode = 1

param.do_plot  = 1
param.plot_png = 1

k_noise = 0.2
plot_output_dir = !nika.plot_dir+"/"+scan
spawn, "mkdir -p "+plot_output_dir

;; Process data
nk_default_info, info
nk_update_param_info, scan, param, info
nk_init_grid, param, grid
nk_scan_preproc, param, info, data, kidpar, xml = xml

;;-------------------------------------------------------------------------------------------
;; look for back-on-track and subscan done to avoid the sections when the secondary is moving
wind, 1, 1, /free, /large
plot,  data.toi[0]
;; back on track
w = where(data.scan_st eq 6,  nw) &  print,  nw
oplot, w, data[w].toi[0],  psym = 8, col = 70

;; subscan done
w = where(data.scan_st eq 5,  nw) &  print,  nw
oplot, w, data[w].toi[0],  psym = 8, col = 250

;; From Hans Ungerechts' email, Nov. 12th, 2014
;; however,  for the data selection,  to be conservative,  I recommend: 
;; for the start: antMD:subscanId.1:segmentStarted + 2.000 [s]
;;                -- start of the ramp-up leading into the Lissajous 
;;            or: antMD:subscanId.2:segmentStarted
;;                -- start of the Lissajous curve itself
;; 
;;             for the end:   antMD subscanDone - 2 slow loops ( 2*0.125 [s] )


;;;;-------------------------
;;message, /info, "fix me:"
;;data = data[where(data.subscan) gt 1]
;;stop
;;;;-------------------------

for i = long(min(data.subscan)), long(max(data.subscan)) do begin
   i1 = where(data.scan_st eq 6 and data.subscan eq i, nw)
   if nw eq 0 then i1=min(where(data.subscan eq i))
   i2 = where(data.scan_st eq 5 and data.subscan eq i, nw)
   if nw eq 0 then i2=max(where(data.subscan eq i))
   w = where(data.sample ge data[i1].sample and data.sample le data[i2].sample, nw)
   if nw eq 0 then begin
      message, /info, "No valid sample for subscan "+strtrim(i, 2)
      return
   endif
   oplot,  w,  data[w].toi[0], psym = 1, col = 150
   wcompl = where( (data.subscan eq i and data.sample lt data[i1].sample), nwcompl)
   if nwcompl ne 0 then begin
      nk_add_flag, data, 8, wcompl
      oplot, wcompl, data[wcompl].toi[0], psym = 1, col = 70
   endif
   wcompl = where( (data.subscan eq i and data.sample gt data[i2].sample), nwcompl)
   if nwcompl ne 0 then begin
      nk_add_flag, data, 8, wcompl
      oplot, wcompl, data[wcompl].toi[0], psym = 1, col = 200
   endif
endfor



d = sqrt( grid.xmap^2 + grid.ymap^2)
w = where( d lt 40) ; large because beams can be abnormally large when we're defocused
grid.mask_source = 1
grid.mask_source[w] = 0
nk_scan_reduce,  param, info, data, kidpar, grid

;; ;; Retrieve focus offset per subscan
;; nsubscans = max(data.subscan) - min(data.subscan) + 1
;; focus =  dblarr(nsubscans)
;; tags = tag_names( pako_str)
;; for i=0, nsubscans-1 do begin
;;    w = where( strupcase(tags) eq "FOFFSET"+strtrim(i,2), nw)
;;    if nw eq 0 then begin
;;       message, /info, 'No focus information for isubscan='+strtrim(i,2)
;;       return
;;    endif else begin
;;       focus[i] = pako_str.(w)
;;    endelse
;; endfor

;; Derive valid subscans from the pako_str information to discard the 1st
;; subscan if there was a tuning or keep it if not...
tags = tag_names( pako_str)
ok=1
nsubscans = 0
while ok eq 1 do begin
   w = where( strupcase(tags) eq "FOFFSET"+strtrim(i,2), nw)
   if nw eq 0 then ok=0 else nsubscans++
endwhile
print, "found nsubscan = "+strtrim(nsubscans,2)

;; Read focus info now
focus = [0.d0]
valid_subscan = [-1]
for i=long( min(data.subscan)), long(max(data.subscan)) do begin
   w = where( strupcase(tags) eq "FOFFSET"+strtrim(i,2), nw)
   if nw ne 0 then begin
      focus = [focus, pako_str.(w)]
      valid_subscan = [valid_subscan, i]
   endif
endfor
;; discard init elements
focus = focus[1:*]
valid_subscan = valid_subscan[1:*]
nsubscans = n_elements(focus)

;; Project and compute photometry for each subscan
peak_1mm = dblarr(nsubscans)
peak_2mm = dblarr(nsubscans)
fwhm_1mm = dblarr(nsubscans)
fwhm_2mm = dblarr(nsubscans)
sigma_peak_1mm = dblarr(nsubscans)
sigma_peak_2mm = dblarr(nsubscans)
sigma_fwhm_1mm = dblarr(nsubscans)
sigma_fwhm_2mm = dblarr(nsubscans)

wind, 1, 1, /free, /large
outplot, file = plot_output_dir+"/focus_liss_maps", png = param.plot_png, ps = param.plot_ps
my_multiplot, nsubscans, 2, pp, pp1, /rev
for i=0, nsubscans-1 do begin
   isubscan = valid_subscan[i]
   w = where( data.subscan eq isubscan, nw)
   if nw eq 0 then begin
      message, /info, "No data for subscan "+strtrim(isbuscan,2)+" ?!"
      return
   endif
   
   ;; Project maps
stop
   nk_projection_3, param, info, data[w], kidpar, grid
   
   ;; Compute photometry on each map
   lambda   = 1
   nefd_1mm = 1
   map_var  = double(finite(grid.map_w8_1mm))*0.d0
   w        = where( grid.map_w8_1mm gt 0, nw)
   if nw ne 0 then map_var[w] = 1.d0/grid.map_w8_1mm[w]

   nk_map_photometry, grid.map_i_1mm, map_var, grid.nhits_1mm, $
                      grid.xmap, grid.ymap, param.input_fwhm_1mm, $
                      flux_1mm, sigma_flux_1mm, $
                      sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
                      bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
                      educated=educated, ps_file=ps_file, position=pp[isubscan-1,0,*], $
                      k_noise=k_noise, noplot=noplot, param=param, $
                      title=param.scan+" 1mm, subscan "+strtrim(isubscan,2)
   peak_1mm[isubscan-1] = flux_1mm
   fwhm_1mm[isubscan-1] = sqrt( output_fit_par_1mm[2]*output_fit_par_1mm[3])
   sigma_peak_1mm[isubscan-1] = sigma_flux_center_1mm
   sigma_fwhm_1mm[isubscan-1] = sqrt(output_fit_par_error_1mm[2]*output_fit_par_error_1mm[3])/!fwhm2sigma
   
   lambda   = 2
   nefd_2mm = 1
   map_var  = double(finite(grid.map_w8_2mm))*0.d0
   w        = where( grid.map_w8_2mm gt 0, nw)
   if nw ne 0 then map_var[w] = 1.d0/grid.map_w8_2mm[w]
   nk_map_photometry, grid.map_i_2mm, map_var, grid.nhits_2mm, $
                      grid.xmap, grid.ymap, param.input_fwhm_2mm, $
                      flux_2mm, sigma_flux_2mm, $
                      sigma_bg_2mm, output_fit_par_2mm, output_fit_par_error_2mm, $
                      bg_rms_2mm, flux_center_2mm, sigma_flux_center_2mm, sigma_bg_center_2mm, $
                      educated=educated, ps_file=ps_file, position=pp[isubscan-1, 1,*], $
                      k_noise=k_noise, noplot=noplot, param=param, $
                      title=param.scan+" 2mm, subscan "+strtrim(isubscan,2)
   peak_2mm[isubscan-1] = flux_2mm
   fwhm_2mm[isubscan-1] = sqrt( output_fit_par_2mm[2]*output_fit_par_2mm[3])
   sigma_peak_2mm[isubscan-1] = sigma_flux_center_2mm
   sigma_fwhm_2mm[isubscan-1] = sqrt(output_fit_par_error_2mm[2]*output_fit_par_error_2mm[3])/!fwhm2sigma
endfor
outplot, /close

;; Fit optimal focus
cp1 = poly_fit( focus, peak_1mm, 2, measure_errors = sigma_peak_1mm)
cp2 = poly_fit( focus, peak_2mm, 2, measure_errors = sigma_peak_2mm)
cf1 = poly_fit( focus, fwhm_1mm, 2, measure_errors = sigma_fwhm_1mm)
cf2 = poly_fit( focus, fwhm_2mm, 2, measure_errors = sigma_fwhm_2mm)

xx = dindgen(100)/99*10-5
fit_p1 = xx*0.d0
fit_p2 = xx*0.d0
fit_f1 = xx*0.d0
fit_f2 = xx*0.d0
for i = 0, n_elements(cp1)-1 do begin
   fit_p1 += cp1[i]*xx^i
   fit_p2 += cp2[i]*xx^i
   fit_f1 += cf1[i]*xx^i
   fit_f2 += cf2[i]*xx^i
endfor

opt_z_p1 = -cp1[1]/(2.d0*cp1[2])
opt_z_p2 = -cp2[1]/(2.d0*cp2[2])
opt_z_f1 = -cf1[1]/(2.d0*cf1[2])
opt_z_f2 = -cf2[1]/(2.d0*cf2[2])

wind,  1,  1, /free, /large
outplot, file = plot_output_dir+"/plot_"+strtrim(scan, 2), png = param.plot_png, ps = param.plot_ps
!p.multi = [0, 2, 2]
ploterror, focus, peak_1mm, sigma_peak_1mm, psym = 8, xtitle='Focus [mm]'
oplot, xx, fit_p1, col = 250
legendastro, ['Flux 1mm', 'Opt z: '+num2string(opt_z_p1)], box = 0, chars = 2

ploterror, focus, peak_2mm, sigma_peak_1mm, psym = 8, xtitle='Focus [mm]'
oplot, xx, fit_p2, col = 250
legendastro, ['Flux 2mm', 'Opt z: '+num2string(opt_z_p2)], box = 0, chars = 2

ploterror, focus, fwhm_1mm, sigma_fwhm_2mm, psym = 8, xtitle='Focus [mm]'
oplot, xx, fit_f1, col = 250
legendastro, ['FWHM 1mm', 'Opt z: '+num2string(opt_z_f1)], box = 0, chars = 2

ploterror, focus, fwhm_2mm, sigma_fwhm_2mm, psym = 8, xtitle='Focus [mm]'
oplot, xx, fit_f2, col = 250
legendastro, ['FWHM 2mm', 'Opt z: '+num2string(opt_z_f2)], box = 0, chars = 2
!p.multi = 0
outplot, /close

;; save results for the logbook
;;nika_get_log_info, param.scan_num, param.day, data, log_info, kidpar=kidpar
fmts = "(F5.2)"
nres = 100
log_info = {scan_num:strtrim(param.scan_num, 2), $
            ut:0.d0, $
            day:param.day, $
            source:param.source, $
            scan_type:'Lissajous', $
            mean_elevation: string(info.elev, format=fmts), $
            tau_1mm: string(kidpar[0].tau_skydip, format=fmts), $
            tau_2mm: string(kidpar[0].tau_skydip, format=fmts), $
            result_name:strarr(nres), $
            result_value:dblarr(nres)+!values.d_nan, $
            comments:''}

log_info.scan_type = info.obs_type
log_info.source    = param.source
log_info.result_name[ 0] = "focus_peak_1mm"
log_info.result_value[0] = opt_z_p1
log_info.result_name[ 1] = "focus_peak_2mm"
log_info.result_value[1] = opt_z_p2
log_info.result_name[ 2] = "focus_fwhm_1mm"
log_info.result_value[2] = opt_z_f1
log_info.result_name[ 3] = "focus_fwhm_2mm"
log_info.result_value[3] = opt_z_f2

;; Create a html page with plots from this scan
save, file=plot_output_dir+"/log_info.save", log_info
nk_logbook_sub, param.scan_num, param.day

;; Update logbook
nk_logbook, param.day

print, ""
banner, "*****************************", n=1
print, "      FOCUS results"
print, ""
print, "To be used directly in PAKO"
print, "Check the best fit value"
print, ""
print, '(Flux 1mm) SET FOCUS '+strtrim( string( opt_z_p1, format='(F5.2)'),2)
print, '(Flux 2mm) SET FOCUS '+strtrim( string( opt_z_p2, format='(F5.2)'),2)
print,  ""
print, '(FWHM 1mm) SET FOCUS '+strtrim( string( opt_z_f1, format='(F5.2)'),2)
print, '(FWHM 2mm) SET FOCUS '+strtrim( string( opt_z_f2, format='(F5.2)'),2)
print, ""
banner, "*****************************", n=1





end
