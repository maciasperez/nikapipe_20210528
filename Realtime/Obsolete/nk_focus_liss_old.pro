


pro nk_focus_liss_old, scan_list, param = param, reset = reset, imbfits=imbfits, $
                       one_mm_only = one_mm_only, two_mm_only = two_mm_only, $
                       educated = educated,  noskydip = noskydip, iconic=iconic, $
                       a1_discard=a1_discard, a2_discard=a2_discard, a3_discard=a3_discard, $ 
                       xyguess=xyguess, radius=radius, mask=mask, largemap=largemap, $
                       nasmyth=nasmyth, ps=ps, nopng=nopng, rmax_keep=rmax_keep, rmin_keep=rmin_keep, $
                       get_focus_error=get_focus_error, imzoom=imzoom
  
;; LP add: one can get an error estimate on the fitted optimal focus 
;; in setting the "get_focus_error" keyword
;; LP add: imzoom: zoom in the source by displaying a 2x2 arcmin
;; square map
   
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

png = 1
noskydip = 1

xml = 1 ; default
if keyword_set(imbfits) then xml = 0
if keyword_set(nopng) then png = 0

if keyword_set(ps) then begin
   png = 0
   ps = 1
endif else ps=0

if not keyword_set(param) then nk_default_param,  param
if keyword_set( iconic) then param.iconic = 1 

if keyword_set(noskydip) then param.do_opacity_correction = 0

nscans = n_elements(scan_list)
peak_1mm = dblarr(nscans)
peak_2mm = dblarr(nscans)
fwhm_1mm = dblarr(nscans)
fwhm_2mm = dblarr(nscans)
sigma_peak_1mm = dblarr(nscans)
sigma_peak_2mm = dblarr(nscans)
sigma_fwhm_1mm = dblarr(nscans)
sigma_fwhm_2mm = dblarr(nscans)

k_noise = 0.2

focusx =  dblarr(nscans)
focusy =  dblarr(nscans)
focusz =  dblarr(nscans)

;; Process scans if necessary
for iscan = 0, n_elements(scan_list)-1 do begin   
   output_dir = param.project_dir+"/v_"+strtrim(param.version, 2)+"/"+scan_list[iscan]
   file_save = output_dir+"/results.save"
   if file_test(file_save) eq 0 or keyword_set(reset) then begin
      param.educated = 1
      nk_rta, scan_list[iscan], param = param, imbfits=imbfits, $
              a1_discard=a1_discard, a2_discard=a2_discard, a3_discard=a3_discard, $
              xyguess=xyguess, radius=radius, nasmyth=nasmyth, $
              mask=mask, largemap=largemap, ps=ps, iconic=iconic, rmax_keep=rmax_keep, rmin_keep=rmin_keep
   endif else begin
      print, scan_list[iscan]+" already processed."
   endelse
endfor

;; Compute photometry on each map
if keyword_set(nasmyth) then begin
   param.map_proj = "nasmyth"
   !mamdlib.coltable = 3
endif
;; more accurate initial values of the beam fit for small maps
if keyword_set(rmax_keep) then begin
   param.rmax_keep = rmax_keep
   if (param.rmax_keep le 100. and strupcase( param.map_proj) eq "NASMYTH") then guess_fit_par=1. 
endif
param.plot_ps  = 0
if keyword_set(ps) then begin
   param.plot_ps = 1
   png=0
endif
plot_output_dir = !nika.plot_dir+"/Logbook/Scans/"+scan_list[nscans-1]
spawn, "mkdir -p "+plot_output_dir
if param.plot_ps ne 1 then wind, 1, 1, xs = 1500, ys = 700, iconic=iconic
outplot, file = plot_output_dir+"/plot_"+strtrim(scan_list[nscans-1],2), png = png, ps = ps
ymin_multiplot = 0.3
my_multiplot, nscans, 3, pp, pp1, /rev, /full, /dry, ymin=ymin_multiplot
fwhm_res       = dblarr(nscans, 3)
sigma_fwhm_res = dblarr(nscans, 3)
peak_res       = dblarr(nscans, 3)
sigma_peak_res = dblarr(nscans, 3)
for iscan = 0, n_elements(scan_list)-1 do begin
   
   output_dir = param.project_dir+"/v_"+strtrim(param.version, 2)+"/"+scan_list[iscan]
   file_save = output_dir+"/results.save"

   if file_test(file_save) then begin

      restore, output_dir+"/results.save", /v
      param = param1
      grid = grid1
      info = info1
      kidpar = kidpar1

      focusx[iscan] = info.focusx
      focusy[iscan] = info.focusy
      focusz[iscan] = info.focusz
      if keyword_set(xyguess) then begin
         xguess = info.NASMYTH_OFFSET_X
         yguess = info.NASMYTH_OFFSET_Y
      endif
      
      educated = 1
      grid_tags = tag_names(grid)
      for iarray=1, 3 do begin
         wmap = where( strupcase(grid_tags) eq "MAP_I"+strtrim(iarray,2), nwmap)
         if nwmap ne 0 then begin
            whits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(iarray,2), nwhits)
            if max(grid.(whits)) gt 0 then begin
               wvar = where( strupcase(grid_tags) eq "MAP_VAR_I"+strtrim(iarray,2), nwmap)
                  
               nk_map_photometry_10934, grid.(wmap), grid.(wvar), grid.(whits), $
                                  grid.xmap, grid.ymap, !nika.fwhm_array[iarray-1], $
                                  flux_1mm, sigma_flux_1mm, $
                                  sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
                                  bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
                                  coltable=coltable, imrange=imrange_i_1mm, imzoom=imzoom,$ ;HA commented imzoom=imzoom, $
                                  educated=educated, ps_file=ps_file, position=pp[iscan,iarray-1,*], $
                                  k_noise=k_noise, param=param, noplot=noplot, $ ;/image_only, $
                                  NEFD_source=nefd_1mm, info=info, /nobar, chars=0.6, $
                                  title=strmid(param.scan,8)+" A"+strtrim(iarray,2), $
                                  xguess=xguess, yguess=yguess, /show_fit, /image, guess_fit_par=guess_fit_par

               fwhm = sqrt( output_fit_par_1mm[2]*output_fit_par_1mm[3])/!fwhm2sigma
               legendastro, 'FWHM '+string(fwhm,format='(F6.2)'), box=0, textcol=250, chars=0.6
               if keyword_set(imzoom) and keyword_set(xyguess) then $
                  legendastro, [strtrim(string(xguess,format='(F6.1)'),2)+','+$
                                strtrim(string(yguess,format='(F6.1)'),2)], box=0, textcol=250, chars=0.6, $
                               psym=[1], col=[250], pos=[xguess-45, yguess+40]
               fmt = '(F5.2)'
               legendastro, ['Foc. X: '+string(info.focusx,format=fmt), $
                             'Foc. Y: '+string(info.focusy,format=fmt), $
                             'Foc. Z: '+string(info.focusz,format=fmt)], box=0, textcol=255, /bottom, chars=0.6
               peak_res[      iscan, iarray-1] = flux_1mm
               fwhm_res[      iscan, iarray-1] = fwhm
               if keyword_set(xyguess) then sigma_peak_res[iscan, iarray-1] = sigma_flux_1mm $
               else sigma_peak_res[iscan, iarray-1] = sigma_flux_center_1mm
               sigma_fwhm_res[iscan, iarray-1] = sqrt(output_fit_par_error_1mm[2]*output_fit_par_error_1mm[3])/!fwhm2sigma
            endif
         endif
      endfor
   endif
endfor
;outplot, /close
my_multiplot, /reset

;; Check if it's a focus x,y,z
if max(focusz)-min(focusz) ne 0 then begin
   focus = focusz
   focus_type =  "Z"
endif
if max(focusx)-min(focusx) ne 0 then begin
   focus = focusx
   focus_type =  "X"
endif
if max(focusy)-min(focusy) ne 0 then begin
   focus = focusy
   focus_type =  "Y"
endif

;; save results for the logbook
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

;; Fit optimal focus
xx = dindgen(100)/99*10-5
my_multiplot, 6, 1, pp, pp1, ymax=ymin_multiplot, gap_x=0.02
focus_res = dblarr(3,2)
err_focus_res = 0
if keyword_set(get_focus_error) then err_focus_res = dblarr(3,2)
for iarray=1,3 do begin
   
   if not(keyword_set(get_focus_error)) then begin
      cp1 = poly_fit( focus, peak_res[*,iarray-1], 2, measure_errors = sigma_peak_res[*,iarray-1])
      cp2 = poly_fit( focus, fwhm_res[*,iarray-1], 2, measure_errors = sigma_fwhm_res[*,iarray-1])
   endif else begin
      ;; first iteration to get the chi2
      cp1_1 = poly_fit( focus, peak_res[*,iarray-1], 2, measure_errors = sigma_peak_res[*,iarray-1], SIGMA=sigma_cp1_1, chisq=chi2_cp1_1, covar=var_cp1_1)
      cp2_1 = poly_fit( focus, fwhm_res[*,iarray-1], 2, measure_errors = sigma_fwhm_res[*,iarray-1], SIGMA=sigma_cp2_1, chisq=chi2_cp2_1, covar=var_cp2_1)
      ;; second iteration using tweaked errors
      nddl = 5.-3.
      tweaky_cp1 = sqrt(chi2_cp1_1/nddl)
      cp1 = poly_fit( focus, peak_res[*,iarray-1], 2, measure_errors = sigma_peak_res[*,iarray-1]*tweaky_cp1, SIGMA=sigma_cp1, chisq=chi2_cp1, covar=var_cp1)
      tweaky_cp2 = sqrt(chi2_cp2_1/nddl)
      cp2 = poly_fit( focus, fwhm_res[*,iarray-1], 2, measure_errors = sigma_fwhm_res[*,iarray-1]*tweaky_cp2, SIGMA=sigma_cp2, chisq=chi2_cp2, covar=var_cp2)
   endelse

   fit_p1 = xx*0.d0
   fit_p2 = xx*0.d0
   for i = 0, n_elements(cp1)-1 do begin
      fit_p1 += cp1[i]*xx^i
      fit_p2 += cp2[i]*xx^i
   endfor

   opt_z_p1 = -cp1[1]/(2.d0*cp1[2])
   opt_z_p2 = -cp2[1]/(2.d0*cp2[2])

   focus_res[iarray-1, 0] = opt_z_p1
   focus_res[iarray-1, 1] = opt_z_p2
   if keyword_set(get_focus_error) then begin
      ;; using the covmat
      aa = [0.d0, -1.d0/(2.d0*cp1[2]),cp1[1]/(2.d0*cp1[2]^2)]
      var_opt_z_p1 = aa#var_cp1#aa
      aa = [0.d0, -1.d0/(2.d0*cp2[2]),cp2[1]/(2.d0*cp2[2]^2)]
      var_opt_z_p2= aa#var_cp2#aa
      err_opt_z_p1 = sqrt(var_opt_z_p1)
      err_opt_z_p2 = sqrt(var_opt_z_p2)
      
      err_focus_res[iarray-1, 0] = err_opt_z_p1
      err_focus_res[iarray-1, 1] = err_opt_z_p2

      pm=string(43B)
   endif
   
   ploterror, focus, peak_res[*,iarray-1], sigma_peak_res[*,iarray-1], $
              psym = 8, xtitle='Focus [mm]', position=pp1[iarray-1,*], /noerase, chars=0.6
   xyouts, focus-0.05, peak_res[*,iarray-1]+0.05, strmid(scan_list,9), orient=90, chars=0.6
   oplot, xx, fit_p1, col = 250
   if not(keyword_set(get_focus_error)) then begin
      legendastro, ['Flux A'+strtrim(iarray,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p1)], box = 0, chars = 0.6
   endif else begin
      legendastro, ['Flux A'+strtrim(iarray,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p1)+'!9'+pm+'!x'+num2string(err_opt_z_p1)], box = 0, chars = 0.6, /bottom
   endelse
   ploterror, focus, fwhm_res[*,iarray-1], sigma_fwhm_res[*,iarray-1], $
              psym = 8, xtitle='Focus [mm]',position=pp1[(iarray-1)+3,*], /noerase, chars=0.6
   oplot, xx, fit_p2, col = 250
   if not(keyword_set(get_focus_error)) then begin
      legendastro, ['FWHM A'+strtrim(iarray,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p2)], box = 0, chars = 0.6
   endif else begin
      legendastro, ['FWHM A'+strtrim(iarray,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p2)+'!9'+pm+'!x'+num2string(err_opt_z_p2)], box = 0, chars = 0.6
   endelse
   
   if not(keyword_set(get_focus_error)) then begin
      log_info.result_name[ 2*(iarray-1)    ] = "focus_peak_A"+strtrim(iarray,2)
      log_info.result_name[ 2*(iarray-1) + 1] = "focus_fwhm_A"+strtrim(iarray,2)   
      log_info.result_value[ 2*(iarray-1)    ] = opt_z_p1
      log_info.result_value[ 2*(iarray-1) + 1] = opt_z_p2
   endif else begin
      log_info.result_name[ 4*(iarray-1)    ] = "focus_peak_A"+strtrim(iarray,2)
      log_info.result_name[ 4*(iarray-1) + 1] = "focus_fwhm_A"+strtrim(iarray,2)
      log_info.result_name[ 4*(iarray-1) + 2] = "err_focus_peak_A"+strtrim(iarray,2)
      log_info.result_name[ 4*(iarray-1) + 3] = "err_focus_fwhm_A"+strtrim(iarray,2)
      log_info.result_value[ 4*(iarray-1)    ] = opt_z_p1
      log_info.result_value[ 4*(iarray-1) + 1] = opt_z_p2
      log_info.result_value[ 4*(iarray-1) + 2] = err_opt_z_p1
      log_info.result_value[ 4*(iarray-1) + 3] = err_opt_z_p2
   endelse

endfor
outplot, /close

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
for iarray=1,3 do begin
   print, "Flux A"+strtrim(iarray,2)+": "+string( focus_res[iarray-1,0], format='(F5.2)')
   print, "FWHM A"+strtrim(iarray,2)+": "+string( focus_res[iarray-1,1], format='(F5.2)')
endfor






end
