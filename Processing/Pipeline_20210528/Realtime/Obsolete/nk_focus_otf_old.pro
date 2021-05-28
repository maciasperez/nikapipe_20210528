


pro nk_focus_otf, scan_list, param = param, reset = reset, imbfits=imbfits, $
                  one_mm_only = one_mm_only, two_mm_only = two_mm_only, $
                  educated = educated,  noskydip = noskydip, iconic=iconic, $
                  a1_discard=a1_discard, a2_discard=a2_discard, a3_discard=a3_discard, $ 
                  xyguess=xyguess, radius=radius, mask=mask, largemap=largemap, $
                  nasmyth=nasmyth, ps=ps, nopng=nopng, rmax_keep=rmax_keep, rmin_keep=rmin_keep, $
                  get_focus_error=get_focus_error, imzoom=imzoom, noscp=noscp, focus_res=focus_res, $
                  subscan_min=subscan_min, subscan_max=subscan_max, k_noise=k_noise, output_root_dir=output_root_dir, $
                  sn_min=sn_min, sn_max=sn_max, cp1_all=cp1_all, cp2_all=cp2_all, cp3_all=cp3_all, noplot=noplot
  
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

if not keyword_set(nopng) then png=1

if not keyword_set(param) then nk_default_param, param
if keyword_set( iconic) then param.iconic = 1 
if keyword_set(noskydip) then param.do_opacity_correction = 0
if not keyword_set(output_root_dir) then output_root_dir = !nika.plot_dir

nscans = n_elements(scan_list)
if not keyword_set(k_noise) then k_noise =  0.2

focusx =  dblarr(nscans)
focusy =  dblarr(nscans)
focusz =  dblarr(nscans)

;; Process scans if necessary
nscans_processed = 0
for iscan = 0, n_elements(scan_list)-1 do begin   
   output_dir = output_root_dir+"/v_1/"+scan_list[iscan]
   file_save = output_dir+"/results.save"
   if file_test(file_save) eq 0 or keyword_set(reset) then begin
      nk_rta, scan_list[iscan], param = param, imbfits=imbfits, $
              a1_discard=a1_discard, a2_discard=a2_discard, a3_discard=a3_discard, $
              xyguess=xyguess, radius=radius, nasmyth=nasmyth, nopng=nopng, $
              mask=mask, largemap=largemap, ps=ps, iconic=iconic, rmax_keep=rmax_keep, rmin_keep=rmin_keep, noscp=noscp, $
              subscan_min=subscan_min, subscan_max=subscan_max, sn_min=sn_min, sn_max=sn_max
      nscans_processed++
   endif else begin
      print, scan_list[iscan]+" already processed."
      nscans_processed++
   endelse
endfor

if nscans_processed lt 3 then begin
   message, /info, "Note enough reduced scans to perform a fit."
   message, /info, "Please relaunch with more scans."
   return
endif

;; ;; Compute photometry on each map
;; if keyword_set(nasmyth) then begin
;;    param.map_proj = "nasmyth"
;;    !mamdlib.coltable = 3
;; endif
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
if param.plot_ps ne 1 and not keyword_set(noplot) then wind, 1, 1, xs = 1500, ys = 700, iconic=iconic

outplot, file = plot_output_dir+"/maps_focus_otf_"+strtrim(scan_list[nscans-1],2), png = png, ps = ps
ymin_multiplot = 0.3
my_multiplot, nscans, 3, pp, pp1, /rev, /full, /dry, gap_y=0.05, gap_x=0.05
fwhm_res         = dblarr(nscans, 3)
sigma_fwhm_res   = dblarr(nscans, 3)
ellipt_res       = dblarr(nscans, 3)
sigma_ellipt_res = dblarr(nscans, 3)
peak_res         = dblarr(nscans, 3)
sigma_peak_res   = dblarr(nscans, 3)

for iscan = 0, n_elements(scan_list)-1 do begin
   
   output_dir = output_root_dir+"/v_"+strtrim(param.version, 2)+"/"+scan_list[iscan]
   file_save = output_dir+"/results.save"
   if file_test(file_save) then begin

      restore, output_dir+"/results.save"
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
         if iscan eq 0 and iarray eq 1 then best_models = dblarr(3,nscans,n_elements(grid1.map_i1[*,0]),n_elements(grid1.map_i1[0,*]))
         wmap = where( strupcase(grid_tags) eq "MAP_I"+strtrim(iarray,2), nwmap)
         if nwmap ne 0 then begin
            whits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(iarray,2), nwhits)
            if max(grid.(whits)) gt 0 then begin
               wvar = where( strupcase(grid_tags) eq "MAP_VAR_I"+strtrim(iarray,2), nwmap)

               nk_map_photometry, grid.(wmap), grid.(wvar), grid.(whits), $
                                  grid.xmap, grid.ymap, !nika.fwhm_array[iarray-1], $
                                  flux, sigma_flux, $
                                  sigma_bg, output_fit_par, output_fit_par_error, $
                                  bg_rms, flux_center, sigma_flux_center, sigma_bg_center, $
                                  coltable=coltable, imrange=imrange_i, imzoom=imzoom,$ ;HA commented imzoom=imzoom, $
                                  educated=educated, ps_file=ps_file, position=pp[iscan,iarray-1,*], $
                                  k_noise=k_noise, param=param, noplot=noplot, $ ;/image_only, $
                                  NEFD_source=nefd, info=info, /nobar, chars=0.6, $
                                  title=strmid(param.scan,8)+" A"+strtrim(iarray,2), $
                                  xguess=xguess, yguess=yguess, /show_fit, /image, guess_fit_par=guess_fit_par, best_model=best_model

               best_models[iarray-1,iscan,*,*] = best_model
               fwhm = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma
               ellipt = max(output_fit_par[2:3])/min(output_fit_par[2:3])
               if not keyword_set(noplot) then begin
                  legendastro, 'FWHM '+string(fwhm,format='(F6.2)'), box=0, textcol=250, chars=0.6
                  if keyword_set(imzoom) and keyword_set(xyguess) then $
                     legendastro, [strtrim(string(xguess,format='(F6.1)'),2)+','+$
                                   strtrim(string(yguess,format='(F6.1)'),2)], box=0, textcol=250, chars=0.6, $
                                  psym=[1], col=[250], pos=[xguess-45, yguess+40]
                  fmt = '(F5.2)'
                  legendastro, ['Foc. X: '+string(info.focusx,format=fmt), $
                                'Foc. Y: '+string(info.focusy,format=fmt), $
                                'Foc. Z: '+string(info.focusz,format=fmt)], box=0, textcol=255, /bottom, chars=0.6
               endif
               peak_res[      iscan, iarray-1] = flux
               fwhm_res[      iscan, iarray-1] = fwhm
               ellipt_res[    iscan, iarray-1] = ellipt
               if keyword_set(xyguess) then begin
                  sigma_peak_res[iscan, iarray-1] = sigma_flux
               endif else begin
                  sigma_peak_res[iscan, iarray-1] = sigma_flux_center
               endelse

               ;; sigma_fwhm_res[iscan, iarray-1] = sqrt(output_fit_par_error[2]*output_fit_par_error[3])/!fwhm2sigma
;               sigma_fwhm_res[ iscan, iarray-1] = sqrt( abs(output_fit_par[2]*output_fit_par_error[3]) +$
;                                                        abs(output_fit_par[3]*output_fit_par_error[2]))
               sigma_fwhm_res[ iscan, iarray-1] = 0.5*fwhm*( abs(output_fit_par_error[2]/output_fit_par[2]) +$
                                                             abs(output_fit_par_error[3]/output_fit_par[3]))
               sigma_ellipt_res[iscan,iarray-1] = ellipt*(abs(output_fit_par_error[2]) + abs(output_fit_par_error[3]))

            endif
         endif
      endfor
   endif
endfor
outplot, /close
my_multiplot, /reset

if nk_stddev(focusx) ne 0 then focus_var = focusx
if nk_stddev(focusy) ne 0 then focus_var = focusy
if nk_stddev(focusz) ne 0 then focus_var = focusz
order_scans = sort(focus_var)

if not(keyword_set(noplot)) then begin
   window,18,xsize=1200,ysize=700
   outplot, file = plot_output_dir+"/residuals_focus_otf_"+strtrim(scan_list[nscans-1],2), png = png, ps = ps
   ymin_multiplot = 0.3
   my_multiplot, nscans, 3, pp, pp1, /rev, /full, /dry, gap_y=0.05, gap_x=0.05
   for iscan = 0, n_elements(scan_list)-1 do begin
      output_dir = output_root_dir+"/v_"+strtrim(param.version, 2)+"/"+scan_list[iscan]
      file_save = output_dir+"/results.save"
      if file_test(file_save) then begin
         restore, output_dir+"/results.save"
         param = param1
         grid = grid1
         info = info1
         kidpar = kidpar1
         for iarray=1, 3 do begin
            wmap = where( strupcase(grid_tags) eq "MAP_I"+strtrim(iarray,2), nwmap)
            map_data = grid.(wmap)
            map_model = best_models[iarray-1,iscan,*,*]
            wpos = where(order_scans eq iscan)
            if iscan eq 0 and iarray eq 1 then rangeA1 = minmax(map_data-map_model)
            if iscan eq 0 and iarray eq 2 then rangeA2 = minmax(map_data-map_model)
            if iscan eq 0 and iarray eq 3 then rangeA3 = minmax(map_data-map_model)
            
            if iarray eq 1 then imrange = rangeA1
            if iarray eq 2 then imrange = rangeA2
            if iarray eq 3 then imrange = rangeA3
            
            imview, map_data-map_model, xmap=xmap, ymap=ymap, position=pp[wpos,iarray-1,*], /noerase, imrange=imrange, $
                    title=strmid(param.scan,8)+" A"+strtrim(iarray,2), xtitle=xtitle, ytitle=ytitle, /noclose, postscript=ps_file, chars=0.6, inside_bar=inside_bar, orientation=orientation, nobar=1, $
                    charbar=charsize,xr=[120,180],yr=[120,180],coltable=39
            fmt = '(F5.2)'
            legendastro, ['Foc. X: '+string(info.focusx,format=fmt), $
                          'Foc. Y: '+string(info.focusy,format=fmt), $
                          'Foc. Z: '+string(info.focusz,format=fmt)], box=0, textcol=0, /bottom, chars=0.6
         endfor
      endif
   endfor
   outplot, /close
   my_multiplot, /reset
endif

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
if param.plot_ps eq 0 then wind, 1, 1, /free, /large
outplot, file = plot_output_dir+"/plot_"+strtrim(scan_list[nscans-1],2), png = png, ps = ps
if not(keyword_set(noplot)) then my_multiplot, 3, 3, pp, pp1, /rev, gap_x=0.05, ymargin=0.05, gap_y=0.05
focus_res = dblarr(3,3)
err_focus_res = 0
if keyword_set(get_focus_error) then err_focus_res = dblarr(3,3)
;; cp1_all = dblarr(3,n_elements(peak_res[*,0]))
;; cp2_all = dblarr(3,n_elements(peak_res[*,0]))
;; cp3_all = dblarr(3,n_elements(peak_res[*,0]))

;; LP modif
nparams = 3. ; parabolic fit
;; cp1_all = dblarr(3,n_elements(peak_res[0,*]))
;; cp2_all = dblarr(3,n_elements(peak_res[0,*]))
;; cp3_all = dblarr(3,n_elements(peak_res[0,*]))

cp1_all = dblarr(3,nparams)
cp2_all = dblarr(3,nparams)
cp3_all = dblarr(3,nparams)

for iarray=1,3 do begin
   
   if not(keyword_set(get_focus_error)) then begin

      cp1 = poly_fit( focus, peak_res[*,iarray-1], 2, measure_errors = sigma_peak_res[*,iarray-1])

      ;; Renormalize error bars
      ;; LP notes: error bars should be renormalized so that the
      ;; reduced chi2 (chi2/(nscans-nparams)) equals 1. 
      fit_value = focus*0.d0
      n = n_elements(focus)
      for i = 0, n_elements(cp1)-1 do fit_value += cp1[i]*focus^i
      chi2 = total( (peak_res[*,iarray-1]-fit_value)^2/sigma_peak_res[*,iarray-1]^2)/(n-1)
      sigma_peak_res[*,iarray-1] *= sqrt( (n-1)*chi2)
      cp1 = poly_fit( focus, peak_res[*,iarray-1], 2, measure_errors = sigma_peak_res[*,iarray-1], chisq=unreducedchi2)
      ;;print,unreducedchi2
      
      cp2 = poly_fit( focus, fwhm_res[*,iarray-1], 2, measure_errors = sigma_fwhm_res[*,iarray-1])
      fit_value = focus*0.d0
      n = n_elements(focus)
      for i = 0, n_elements(cp2)-1 do fit_value += cp2[i]*focus^i
      chi2 = total( (fwhm_res[*,iarray-1]-fit_value)^2/sigma_fwhm_res[*,iarray-1]^2)/(n-1)
      sigma_fwhm_res[*,iarray-1] *= sqrt( (n-1)*chi2)
      cp2 = poly_fit( focus, fwhm_res[*,iarray-1], 2, measure_errors = sigma_fwhm_res[*,iarray-1])

      cp3 = poly_fit( focus, ellipt_res[*,iarray-1], 2, measure_errors = sigma_ellipt_res[*,iarray-1])
      fit_value = focus*0.d0
      n = n_elements(focus)
      for i = 0, n_elements(cp3)-1 do fit_value += cp3[i]*focus^i
      chi2 = total( (ellipt_res[*,iarray-1]-fit_value)^2/sigma_ellipt_res[*,iarray-1]^2)/(n-1)
      sigma_ellipt_res[*,iarray-1] *= sqrt( (n-1)*chi2)
      cp3 = poly_fit( focus, ellipt_res[*,iarray-1], 2, measure_errors = sigma_ellipt_res[*,iarray-1])

   endif else begin
      nscans = n_elements(peak_res[*, iarray-1])
      ;; first iteration to get the chi2
      cp1_1 = poly_fit( focus, peak_res[*,iarray-1], 2, measure_errors = sigma_peak_res[*,iarray-1], $
                        SIGMA=sigma_cp1_1, chisq=chi2_cp1_1, covar=var_cp1_1)
      cp2_1 = poly_fit( focus, fwhm_res[*,iarray-1], 2, measure_errors = sigma_fwhm_res[*,iarray-1], $
                        SIGMA=sigma_cp2_1, chisq=chi2_cp2_1, covar=var_cp2_1)
      cp2_1 = poly_fit( focus, ellipt_res[*,iarray-1], 2, measure_errors = sigma_ellipt_res[*,iarray-1], $
                        SIGMA=sigma_cp3_1, chisq=chi2_cp3_1, covar=var_cp3_1)
      ;; second iteration using tweaked errors
      nddl = nscans - nparams
      tweaky_cp1 = sqrt(chi2_cp1_1/nddl)
      cp1 = poly_fit( focus, peak_res[*,iarray-1], 2, measure_errors = sigma_peak_res[*,iarray-1]*tweaky_cp1, $
                      SIGMA=sigma_cp1, chisq=chi2_cp1, covar=var_cp1)
      tweaky_cp2 = sqrt(chi2_cp2_1/nddl)
      cp2 = poly_fit( focus, fwhm_res[*,iarray-1], 2, measure_errors = sigma_fwhm_res[*,iarray-1]*tweaky_cp2, $
                      SIGMA=sigma_cp2, chisq=chi2_cp2, covar=var_cp2)
      tweaky_cp3 = sqrt(chi2_cp3_1/nddl)
      cp3 = poly_fit( focus, ellipt_res[*,iarray-1], 2, measure_errors = sigma_ellipt_res[*,iarray-1]*tweaky_cp3, $
                      SIGMA=sigma_cp3, chisq=chi2_cp3, covar=var_cp3)
   endelse

   cp1_all[iarray-1,*] = cp1
   cp2_all[iarray-1,*] = cp2
   cp3_all[iarray-1,*] = cp3

   fit_p1 = xx*0.d0
   fit_p2 = xx*0.d0
   fit_p3 = xx*0.d0
   for i = 0, n_elements(cp1)-1 do begin
      fit_p1 += cp1[i]*xx^i
      fit_p2 += cp2[i]*xx^i
      fit_p3 += cp3[i]*xx^i
   endfor
   xra = minmax(focus) + [-0.2,0.2]*(max(focus)-min(focus))
   opt_z_p1 = -cp1[1]/(2.d0*cp1[2])
   opt_z_p2 = -cp2[1]/(2.d0*cp2[2])
   opt_z_p3 = -cp3[1]/(2.d0*cp3[2])
   
   focus_res[iarray-1, 0] = opt_z_p1
   focus_res[iarray-1, 1] = opt_z_p2
   focus_res[iarray-1, 2] = opt_z_p3
   if keyword_set(get_focus_error) then begin
      ;; using the covmat
      aa = [0.d0, -1.d0/(2.d0*cp1[2]),cp1[1]/(2.d0*cp1[2]^2)]
      var_opt_z_p1 = aa#var_cp1#aa
      aa = [0.d0, -1.d0/(2.d0*cp2[2]),cp2[1]/(2.d0*cp2[2]^2)]
      var_opt_z_p2= aa#var_cp2#aa
      aa = [0.d0, -1.d0/(2.d0*cp3[2]),cp3[1]/(2.d0*cp3[2]^2)]
      var_opt_z_p3= aa#var_cp3#aa
      err_opt_z_p1 = sqrt(var_opt_z_p1)
      err_opt_z_p2 = sqrt(var_opt_z_p2)
      err_opt_z_p3 = sqrt(var_opt_z_p3)
      
      err_focus_res[iarray-1, 0] = err_opt_z_p1
      err_focus_res[iarray-1, 1] = err_opt_z_p2
      err_focus_res[iarray-1, 2] = err_opt_z_p3
      
      pm=string(43B)
   endif
   
   nn = n_elements(peak_res)
   if not keyword_set(noplot) then begin
      yra = minmax([fit_p1, reform(peak_res,nn)])
      yra =[0,max([fit_p1, reform(peak_res,nn)])]
      ploterror, focus, peak_res[*,iarray-1], sigma_peak_res[*,iarray-1], $
                 psym = 8, xtitle='Focus [mm]', position=pp[iarray-1,0,*], /noerase, chars=0.6, /xs, $
                 xra=xra, yra=yra
      xyouts, focus-0.05, peak_res[*,iarray-1]+0.05, strmid(scan_list,9), orient=90, chars=0.6
      
      oplot, xx, fit_p1, col = 250
      oplot, [1,1]*opt_z_p1, [-1,1]*1e10, col=70
      if not(keyword_set(get_focus_error)) then begin
         legendastro, ['Flux A'+strtrim(iarray,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p1)], box = 0, chars = 0.6
      endif else begin
         legendastro, ['Flux A'+strtrim(iarray,2), $
                       'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p1)+'!9'+pm+'!x'+num2string(err_opt_z_p1),$
                       'FOR SAMUEL'], $
                      box = 0, chars = 0.6, /bottom
      endelse
      yra = minmax([fit_p2, reform(fwhm_res,nn)])
      ploterror, focus, fwhm_res[*,iarray-1], sigma_fwhm_res[*,iarray-1], $
                 psym = 8, xtitle='Focus [mm]',position=pp[iarray-1,1,*], /noerase, chars=0.6, /xs
      oplot, xx, fit_p2, col = 250
      oplot, [1,1]*opt_z_p2, [-1,1]*1e10, col=70
      if not(keyword_set(get_focus_error)) then begin
         legendastro, ['FWHM A'+strtrim(iarray,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p2)], box = 0, chars = 0.6
      endif else begin
         legendastro, ['FWHM A'+strtrim(iarray,2), $
                       'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p2)+'!9'+pm+'!x'+num2string(err_opt_z_p2)], $
                      box = 0, chars = 0.6
      endelse

      yra = minmax([fit_p3, reform(ellipt_res,nn)])
      ploterror, focus, ellipt_res[*,iarray-1], sigma_ellipt_res[*,iarray-1], $
                 psym=8, xtitle='Focus [mm]', position=pp[iarray-1,2,*], /noerase, /xs, chars=0.6
      oplot, xx, fit_p3, col=250
      oplot, [1,1]*opt_z_p3, [-1,1]*1e10, col=70
      legendastro, ['Ellipt A'+strtrim(iarray,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p3)], box = 0, chars = 0.6
   endif
   
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
   print, "Ellipticity A"+strtrim(iarray,2)+": "+string( focus_res[iarray-1,2], format='(F5.2)')
endfor

end
