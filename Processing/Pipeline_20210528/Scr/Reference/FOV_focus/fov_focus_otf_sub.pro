

pro fov_focus_otf_sub, iproc, scan_list, beam_maps_dir, kidpar_file=kidpar_file, result_dir=result_dir, $
                       focus_error_rescaling=focus_error_rescaling, $
                       plot_output_dir=plot_output_dir, show_focus_plot=show_focus_plot
  
  if keyword_set(focus_error_rescaling) then get_focus_error = 1 else get_focus_error = 0
  
  ;; no map plots
  noplot = 1
  
  scale=1
  png=0

  if not keyword_set(result_dir) then result_dir = !nika.plot_dir+'/'+strtrim(scan_list[0],2)
  if not keyword_set(plot_output_dir) then  plot_output_dir = result_dir
  do_plot_focus = 0
  if keyword_set( show_focus_plot) then do_plot_focus = 1
  
  nscans = n_elements(scan_list)
  if not keyword_set(k_noise) then k_noise =  0.2
  
  
  nscans_processed = 0
  nkids_per_scan = dblarr(nscans)
  for iscan=0, nscans-1 do begin
     kid_maps_file = beam_maps_dir+'/Maps_kids_out/kid_maps_'+scan_list[iscan]+'_'+strtrim(iproc,2)+'.save' 
     print,kid_maps_file
     if file_test(kid_maps_file) then begin
        restore, kid_maps_file
        nkids_per_scan[iscan] = n_elements(kidpar)
        nscans_processed++
     endif else message, /info, "beammap scan "+scan_list[iscan]+" was not reduced"
  endfor
  if nscans_processed lt nscans then begin
     message, /info, "Some beammap scans have not been properly processed"
     message, /info, "Please relaunch.."
     return
  endif
  
  nkids = max(nkids_per_scan) ;; in principle, the same number of kids in each scan
  
  w = where(nkids_per_scan eq nkids)
  kid_maps_file = beam_maps_dir+'/Maps_kids_out/kid_maps_'+scan_list[w[0]]+'_'+strtrim(iproc,2)+'.save' 
  print,kid_maps_file
  restore, kid_maps_file 
  kidpar_ref = kidpar

  
  kid_flag = dblarr(nscans, nkids)+1
  ;; flag non-processed kids
  if min(nkids_per_scan) ne nkids then begin
     
     kid_flag = dblarr(nscans, nkids)
     
     for iscan=0, nscans-1 do begin
        kid_maps_file = beam_maps_dir+'/Maps_kids_out/kid_maps_'+scan_list[iscan]+'_'+strtrim(iproc,2)+'.save' 
        ;;print,kid_maps_file
        if file_test(kid_maps_file) then begin
           restore, kid_maps_file
           my_match, kidpar_ref.numdet, kidpar.numdet, suba, subb
           kid_flag[iscan, suba] = 1        
        endif else message, /info, "beammap scan "+scan_list[iscan]+" was not reduced"
     endfor

     ;; flag out kids that have not enough good scans
     ;;nkid_flag = total(kid_flag, 1)
     ;;w = where(nkid_flag lt 3., nw)
     ;;if nw gt 0 then kid_flag[*,w] = 0

  endif
  
  
;; gather all the kid maps in a table
  kid_map_azel = dblarr(nscans, nkids, grid_azel.nx, grid_azel.ny)
  kid_hit_azel = dblarr(nscans, nkids, grid_azel.nx, grid_azel.ny)
  kid_map_nas  = dblarr(nscans, nkids, grid_nasmyth.nx, grid_nasmyth.ny)
  kid_hit_nas  = dblarr(nscans, nkids, grid_nasmyth.nx, grid_nasmyth.ny)
  
  nk_default_info, info 
  focusx =  dblarr(nscans)
  focusy =  dblarr(nscans)
  focusz =  dblarr(nscans)
  
  for iscan=0, nscans-1 do begin
     kid_maps_file = beam_maps_dir+'/Maps_kids_out/kid_maps_'+scan_list[iscan]+'_'+strtrim(iproc,2)+'.save' 
     ;;print,kid_maps_file
     if file_test(kid_maps_file) then begin
        restore, kid_maps_file 
        ;;w1 = where(kid_flag[iscan, *] gt 0)
        my_match, kidpar_ref.numdet, kidpar.numdet, suba, subb
        
        kid_map_azel[iscan, suba, *, *] = map_list_azel[         subb, *, *]
        kid_hit_azel[iscan, suba, *, *] = map_list_nhits_azel[   subb, *, *]
        kid_map_nas[iscan,  suba, *, *] = map_list_nasmyth[      subb, *, *]
        kid_hit_nas[iscan,  suba, *, *] = map_list_nhits_nasmyth[subb, *, *]
        ;; focus settings
        imb_fits_file = !nika.imb_fits_dir+"/iram30m-antenna-"+scan_list[iscan]+"-imb.fits"
        nk_imbfits2info, imb_fits_file, info
        focusx[iscan] = info.focusx
        focusy[iscan] = info.focusy
        focusz[iscan] = info.focusz
     endif else message, /info, "beammap scan "+scan_list[iscan]+" was not reduced"
  endfor
  
  
;; input kidpar
  kp = mrdfits(kidpar_file, 1)
  my_match, kp.numdet, kidpar_ref.numdet, suba, subb
  kp = kp[suba]
  
  
;; fit the focus for each kid
  for ikid = 0, nkids-1 do begin

     if noplot eq 0 then begin
        wind, 1, 1, /free, xsize=1200, ysize=400
        outplot, file = plot_output_dir+"/maps_focus_otf_"+strtrim(scan_list[nscans-1],2)+"_"+strtrim(kp[ikid].numdet,2), png = png, ps = ps
        ymin_multiplot = 0.3
     endif
     my_multiplot, nscans, 1, pp, pp1, /rev, /full, /dry, gap_y=0.05, gap_x=0.05

     
     fwhm_res         = dblarr(nscans)
     sigma_fwhm_res   = dblarr(nscans)
     ellipt_res       = dblarr(nscans)
     sigma_ellipt_res = dblarr(nscans)
     peak_res         = dblarr(nscans)
     sigma_peak_res   = dblarr(nscans)

     flux_res         = dblarr(nscans)
     sigma_flux_res   = dblarr(nscans)
     
     chi2_res            = dblarr(nscans)
     flux_ratio          = dblarr(nscans)
     residual_ampl_ratio = dblarr(nscans)
     max_res1 = 0.
     max_res2 = 0.
     max_res3 = 0.
     
     r_in_tab=[6., 15., 6.]
     scan_ok = intarr(nscans)
     for iscan = 0, nscans-1 do begin

        iarray = kp[ikid].array
        
        map = reform(kid_map_nas[iscan, ikid, *, *])
        hit = reform(kid_hit_nas[iscan, ikid, *, *])
        
        if max(hit) gt 0 then begin
           scan_ok[iscan] = 1
           bg_mask = (grid_nasmyth.xmap)*0.d0
           d = sqrt( (grid_nasmyth.xmap - kp[ikid].nas_x)^2 + (grid_nasmyth.ymap - kp[ikid].nas_y)^2)
           wbg = where( d gt 90. and d le 250. and map ne 0.d0, nwbg)
           if nwbg eq 0 then begin
              txt = "Cannot compute the variance map on the background"
              nk_error, info, txt
              return
           endif else begin
              bg_mask[wbg] = 1
           endelse
           nk_bg_var_map, map, hit, bg_mask, var
           nk_map_photometry, map, var, hit, $
                              grid_nasmyth.xmap, grid_nasmyth.ymap, !nika.fwhm_array[iarray-1], $
                              flux, sigma_flux, $
                              sigma_bg, output_fit_par, output_fit_par_error, $
                              bg_rms, flux_center, sigma_flux_center, sigma_bg_center, $
                              integ_time_center, sigma_beam_pos, grid_step=!nika.grid_step[iarray-1], $
                              coltable=coltable, imzoom=0,$ 
                              educated=educated, ps_file=ps_file, position=reform(pp[iscan,0, *]), $
                              k_noise=k_noise, param=param, noplot=noplot, $ ;/image_only, $
                              NEFD_source=nefd, info=info, /nobar, chars=0.6, $
                              title=strmid(scan_list[iscan],8)+" A"+strtrim(iarray,2), $
                              xguess=kp[ikid].nas_x, yguess=kp[ikid].nas_y, /show_fit, /image, $
                              guess_fit_par=guess_fit_par, best_model=map_fit
          
           
           ;; Fit only near the very center and far from it to
           ;; avoid side lobes
           d = sqrt( (grid_nasmyth.xmap-output_fit_par[4])^2 + (grid_nasmyth.ymap-output_fit_par[5])^2)
           rbg = 100.
                                ;wfit = where( (grid.(wmap) gt 0.5*flux and d le rbg) or (d ge rbg and grid.(wvar) lt mean(grid.(wvar))), nwfit, compl=wout)
                                ;print, 'side lobe mask r_in =', 0.5*flux
                                ;rbg = 150.
                                ;wfit = where( (grid.(wmap) gt 0.2*flux_center and d le rbg) or (d ge rbg and grid.(wvar) lt mean(grid.(wvar))), nwfit, compl=wout)
           wfit = where( (d le r_in_tab[iarray-1]) or (d ge rbg and var lt mean(var) ), nwfit, compl=wout)
           
           map_var = var
           ;;map_var[wout] = 0.d0
           ;; nk_fitmap, map, map_var, grid_nasmyth.xmap, grid_nasmyth.ymap, output_fit_par, covar, output_fit_par_error, $
           ;;            educated=1, k_noise=k_noise, status=status, dmax=150., $
           ;;            xguess=output_fit_par[4], yguess=output_fit_par[5], guess_fit_par=guess_fit_par, $
           ;;            sigma_guess=input_sigma_beam, map_fit=map_fit
           
           if noplot eq 0 then begin
              phi = dindgen(100)/99.*2*!dpi
              cosphi = cos(phi)
              sinphi = sin(phi)
              oplot, output_fit_par[4]+output_fit_par[2]/!fwhm2sigma*cosphi, $
                     output_fit_par[5]+output_fit_par[3]/!fwhm2sigma*sinphi, col=250
           endif
              
           fwhm = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma
           ellipt = max(output_fit_par[2:3])/min(output_fit_par[2:3])
              
           peak_res[  iscan] = output_fit_par[1]
           fwhm_res[  iscan] = fwhm
           ellipt_res[iscan] = ellipt

           flux_res[      iscan] = flux
           sigma_flux_res[iscan] = sigma_flux
           
           main_beam_flux = output_fit_par[1]*(2.d0*!dpi*(fwhm*!fwhm2sigma)^2)
           
           ;; Look at residuals
           ;;map_fit = nika_gauss2( grid_nasmyth.xmap, grid_nasmyth.ymap, output_fit_par)
           map_residuals = map_fit*0.d0
           w = where( hit ne 0 and finite(var))
           map_residuals[w] = (map-map_fit)[w]
           
           ;; signal to noise
           map_sn = map_fit*0.d0
           map_sn[w] = abs( (map[w])/sqrt( var[w]))
           wsig3 = where( map_sn ge 3, nwsig3)
           if nwsig3 eq 0 then message, "No pixel with S/N >= 3"
           
           wchi2 = where( finite(map_var) and map_var gt 0.d0 and d le rbg, nwchi2)
           if nwchi2 eq 0 then message, "No pixel with finite and non zero variance"
           chi2_res[            iscan] = total( map_residuals[wchi2]^2/map_var[wchi2])/total(1./map_var[wchi2])
           flux_ratio[          iscan] = total( map_residuals[wchi2]*grid_nasmyth.map_reso^2)/main_beam_flux
           residual_ampl_ratio[ iscan] = max(   map_residuals[wsig3])/output_fit_par[1]
           
           if iarray eq 1 then begin
              if max(abs(map_residuals[wchi2])) gt max_res1 then max_res1 = max(abs(map_residuals[wchi2]))
           endif else if iarray eq 2 then begin
              if max(abs(map_residuals[wchi2])) gt max_res2 then max_res2 = max(abs(map_residuals[wchi2]))
           endif else begin
              if max(abs(map_residuals[wchi2])) gt max_res3 then max_res3 = max(abs(map_residuals[wchi2]))
           endelse
           
           
           if noplot eq 0 then begin
              legendastro, 'FWHM '+string(fwhm,format='(F6.2)'), box=0, textcol=250, chars=0.6
              fmt = '(F5.2)'
              legendastro, ['Foc. X: '+string(focusx[iscan],format=fmt), $
                            'Foc. Y: '+string(focusy[iscan],format=fmt), $
                            'Foc. Z: '+string(focusz[iscan],format=fmt)], box=0, textcol=255, /bottom, chars=0.6
           endif
           
           sigma_fwhm_res[  iscan] = 0.5*fwhm*( abs(output_fit_par_error[2]/output_fit_par[2]) +$
                                                abs(output_fit_par_error[3]/output_fit_par[3]))
           sigma_ellipt_res[iscan] = ellipt*(abs(output_fit_par_error[2]) + abs(output_fit_par_error[3]))

           sigma_peak_res[  iscan] = output_fit_par_error[1]
           
        endif else scan_ok[iscan] = 0 
        
     endfor ;; scans
     outplot, /close
     my_multiplot, /reset
     
;; Check if it's a focus x,y,z
     foc_corr = 0.d0
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
     
     
     
     
;; Fit optimal focus
     dxfocus = (max(focus)-min(focus))
     xx = dindgen(100)/99*dxfocus*1.4 + min(focus)-dxfocus*0.2

     if do_plot_focus gt 0 then begin
        wind, 1, 1, /free, /large
        scan_plot_file = plot_output_dir+"/plot_"+strtrim(scan_list[nscans-1],2)+"_"+strtrim(kp[ikid].numdet,2)
     
        outplot, file = scan_plot_file, png = png, ps = ps
        my_multiplot, 1, 4, pp, pp1, /rev, gap_x=0.05, ymargin=0.05, gap_y=0.05
     endif
     
     focus_res = dblarr(4)
     err_focus_res = 0
     if get_focus_error gt 0 then err_focus_res = dblarr(4)
     
      
     iarray=kp[ikid].array

     ;;sort_focus=sort(focus)
     ;;focus = focus[sort_focus]

     wok = where(scan_ok gt 0, nwok)
     if nwok gt 2 then begin

        focus = focus[wok]
        peak_res = peak_res[wok]
        sigma_peak_res = sigma_peak_res[wok]
        fwhm_res = fwhm_res[wok]
        sigma_fwhm_res = sigma_fwhm_res[wok]
        ellipt_res = ellipt_res[wok]
        sigma_ellipt_res = sigma_ellipt_res[wok]
        flux_res = flux_res[wok]
        sigma_flux_res = sigma_flux_res[wok]
        
        nscans = n_elements(peak_res[*])
        nparams = 3
        cp1_all = dblarr(nparams)
        cp2_all = dblarr(nparams)
        cp3_all = dblarr(nparams)
        cp4_all = dblarr(nparams)
        
        if get_focus_error eq 0 then begin
           cp1 = poly_fit( focus, peak_res, 2, measure_errors = sigma_peak_res)
           
           ;; Renormalize error bars
           fit_value = focus*0.d0
           n = n_elements(focus)
           for i = 0, n_elements(cp1)-1 do fit_value += cp1[i]*focus^i
           chi2 = total( (peak_res[*]-fit_value)^2/sigma_peak_res[*]^2)/(n-1)
           sigma_peak_res[*] *= sqrt( (n-1)*chi2)
           cp1 = poly_fit( focus, peak_res[*], 2, measure_errors = sigma_peak_res[*])
           
           cp2 = poly_fit( focus, fwhm_res[*], 2, measure_errors = sigma_fwhm_res[*])
           fit_value = focus*0.d0
           n = n_elements(focus)
           for i = 0, n_elements(cp2)-1 do fit_value += cp2[i]*focus^i
           chi2 = total( (fwhm_res[*]-fit_value)^2/sigma_fwhm_res[*]^2)/(n-1)
           sigma_fwhm_res[*] *= sqrt( (n-1)*chi2)
           cp2 = poly_fit( focus, fwhm_res[*], 2, measure_errors = sigma_fwhm_res[*])
           
           cp3 = poly_fit( focus, ellipt_res[*], 2, measure_errors = sigma_ellipt_res[*])
           fit_value = focus*0.d0
           n = n_elements(focus)
           for i = 0, n_elements(cp3)-1 do fit_value += cp3[i]*focus^i
           chi2 = total( (ellipt_res[*]-fit_value)^2/sigma_ellipt_res[*]^2)/(n-1)
           sigma_ellipt_res[*] *= sqrt( (n-1)*chi2)
           cp3 = poly_fit( focus, ellipt_res[*], 2, measure_errors = sigma_ellipt_res[*])
           
           cp4 = poly_fit( focus,flux_res[*], 2, measure_errors = sigma_flux_res[*])
           fit_value = focus*0.d0
           n = n_elements(focus)
           for i = 0, n_elements(cp4)-1 do fit_value += cp4[i]*focus^i
           chi2 = total( (flux_res[*]-fit_value)^2/sigma_flux_res[*]^2)/(n-1)
           sigma_flux_res[*] *= sqrt( (n-1)*chi2)
           cp4 = poly_fit( focus, flux_res[*], 2, measure_errors = sigma_flux_res[*])
        endif else begin
           
           ;; first iteration to get the chi2
           cp1_1 = poly_fit( focus, peak_res[*], 2, measure_errors = sigma_peak_res[*], $
                             SIGMA=sigma_cp1_1, chisq=chi2_cp1_1, covar=var_cp1_1)
           cp4_1 = poly_fit( focus, flux_res[*], 2, measure_errors = sigma_flux_res[*], $
                             SIGMA=sigma_cp4_1, chisq=chi2_cp4_1, covar=var_cp4_1)
           cp2_1 = poly_fit( focus, fwhm_res[*], 2, measure_errors = sigma_fwhm_res[*], $
                             SIGMA=sigma_cp2_1, chisq=chi2_cp2_1, covar=var_cp2_1)
           cp3_1 = poly_fit( focus, ellipt_res[*], 2, measure_errors = sigma_ellipt_res[*], $
                             SIGMA=sigma_cp3_1, chisq=chi2_cp3_1, covar=var_cp3_1)
           ;; second iteration using tweaked errors
           if nscans eq 3 then nparams=2
           nddl = float(nscans - nparams)
           tweaky_cp1 = sqrt(chi2_cp1_1/nddl)
           cp1 = poly_fit( focus, peak_res[*], 2, measure_errors = sigma_peak_res[*]*tweaky_cp1, $
                           SIGMA=sigma_cp1, chisq=chi2_cp1, covar=var_cp1)
           tweaky_cp4 = sqrt(chi2_cp4_1/nddl)
           cp4 = poly_fit( focus, flux_res[*], 2, measure_errors = sigma_flux_res[*]*tweaky_cp4, $
                           SIGMA=sigma_cp4, chisq=chi2_cp4, covar=var_cp4)
           tweaky_cp2 = sqrt(chi2_cp2_1/nddl)
           cp2 = poly_fit( focus, fwhm_res[*], 2, measure_errors = sigma_fwhm_res[*]*tweaky_cp2, $
                           SIGMA=sigma_cp2, chisq=chi2_cp2, covar=var_cp2)
           tweaky_cp3 = sqrt(chi2_cp3_1/nddl)
           cp3 = poly_fit( focus, ellipt_res[*], 2, measure_errors = sigma_ellipt_res[*]*tweaky_cp3, $
                           SIGMA=sigma_cp3, chisq=chi2_cp3, covar=var_cp3)
        endelse
        
        wcp1 = where(finite(cp1) gt 0, ncp1)
        if ncp1 gt 0 then cp1_all[wcp1] = cp1[wcp1]
        wcp2 = where(finite(cp2) gt 0, ncp2)
        if ncp1 gt 0 then cp2_all[wcp2] = cp2[wcp2]
        wcp3 = where(finite(cp3) gt 0, ncp3)
        if ncp3 gt 0 then cp3_all[wcp3] = cp3[wcp3]
        wcp4 = where(finite(cp4) gt 0, ncp4)
        if ncp4 gt 0 then cp4_all[wcp4] = cp4[wcp4]
        
        fit_p1 = xx*0.d0
        fit_p2 = xx*0.d0
        fit_p3 = xx*0.d0
        fit_p4 = xx*0.d0
        for i = 0, n_elements(cp1)-1 do begin
           fit_p1 += cp1[i]*xx^i
           fit_p2 += cp2[i]*xx^i
           fit_p3 += cp3[i]*xx^i
           fit_p4 += cp4[i]*xx^i
        endfor
        xra = minmax(focus) + [-0.2,0.2]*(max(focus)-min(focus))
        opt_z_p1 = -cp1[1]/(2.d0*cp1[2])
        opt_z_p2 = -cp2[1]/(2.d0*cp2[2])
        opt_z_p3 = -cp3[1]/(2.d0*cp3[2])
        opt_z_p4 = -cp4[1]/(2.d0*cp4[2])
        
        ;; Adding foc_corr to compute the best "average" focus over the arrays rather
        ;; than the best "central" focus (Apr. 18th, 2017)
        focus_res[0] = opt_z_p1 + foc_corr
        focus_res[1] = opt_z_p2 + foc_corr
        focus_res[2] = opt_z_p3 + foc_corr
        focus_res[3] = opt_z_p4 + foc_corr
        if get_focus_error gt 0 then begin
        ;; using the covmat
           aa = [0.d0, -1.d0/(2.d0*cp1[2]),cp1[1]/(2.d0*cp1[2]^2)]
           var_opt_z_p1 = aa#var_cp1#aa
           aa = [0.d0, -1.d0/(2.d0*cp2[2]),cp2[1]/(2.d0*cp2[2]^2)]
           var_opt_z_p2= aa#var_cp2#aa
           aa = [0.d0, -1.d0/(2.d0*cp3[2]),cp3[1]/(2.d0*cp3[2]^2)]
           var_opt_z_p3= aa#var_cp3#aa
           aa = [0.d0, -1.d0/(2.d0*cp4[2]),cp4[1]/(2.d0*cp4[2]^2)]
           var_opt_z_p4 = aa#var_cp4#aa
           err_opt_z_p1 = sqrt(var_opt_z_p1)
           err_opt_z_p2 = sqrt(var_opt_z_p2)
           err_opt_z_p3 = sqrt(var_opt_z_p3)
           err_opt_z_p4 = sqrt(var_opt_z_p4)
           
           err_focus_res[0] = err_opt_z_p1
           err_focus_res[1] = err_opt_z_p2
           err_focus_res[2] = err_opt_z_p3
           err_focus_res[3] = err_opt_z_p4
           
           pm=string(43B)
        endif
        
        nn = n_elements(peak_res)
        if do_plot_focus gt 0  then begin
           dyra = max([fit_p1,peak_res]) - min([fit_p1, peak_res])
           yra = minmax([fit_p1, peak_res]) + [-0.3,0.5]*dyra
           ploterror, focus, peak_res, sigma_peak_res, $
                      psym = 8, xtitle='Focus [mm]', position=pp[0,0,*], /noerase, chars=0.6, /xs, $
                      xra=xra, yra=yra, /ys
           xyouts, focus-0.05, peak_res+0.05, strmid(scan_list,9), orient=90, chars=0.6
           ;;lfit = linfit( focus, peak_res, measure_errors=sigma_peak_res)
           ;;oplot, [-10,10], lfit[0] + lfit[1]*[-10,10], line=2
           
           oplot, xx, fit_p1, col = 250
           oplot, [1,1]*opt_z_p1, [-1,1]*1e10, col=70
           if not(keyword_set(get_focus_error)) then begin
              leg_txt = ['Peak A'+strtrim(iarray,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p1)]
              if foc_corr ne 0.d0 then leg_txt = [leg_txt, 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p1+foc_corr)]
           endif else begin
              leg_txt = ['Peak A'+strtrim(iarray,2), $
                         'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p1)+'!9'+pm+'!x'+num2string(err_opt_z_p1)]
              if foc_corr ne 0.d0 then leg_txt = [leg_txt, $
                                                  'Opt. AVG '+strtrim(focus_type,2)+': '+$
                                                  num2string(opt_z_p1+foc_corr)+'!9'+pm+'!x'+num2string(err_opt_z_p1)]
           endelse
           legendastro, leg_txt, box = 0, chars = 0.6
           
           dyra = max([fit_p4,flux_res]) - min([fit_p4, flux_res])
           yra = minmax([fit_p4, flux_res]) + [-0.3,0.5]*dyra
           ploterror, focus, flux_res, sigma_flux_res, $
                      psym = 8, xtitle='Focus [mm]', position=pp[0,1,*], /noerase, chars=0.6, /xs, $
                      xra=xra, yra=yra, /ys
           xyouts, focus-0.05, flux_res+0.05, strmid(scan_list,9), orient=90, chars=0.6
           ;;lfit = linfit( focus, peak_res, measure_errors=sigma_peak_res)
           ;;oplot, [-10,10], lfit[0] + lfit[1]*[-10,10], line=2
           
           oplot, xx, fit_p4, col = 250
           oplot, [1,1]*opt_z_p4, [-1,1]*1e10, col=70
           if not(keyword_set(get_focus_error)) then begin
              leg_txt = ['Flux A'+strtrim(iarray,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p4)]
              if foc_corr ne 0.d0 then leg_txt = [leg_txt, 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p4+foc_corr)]
           endif else begin
              leg_txt = ['Flux A'+strtrim(iarray,2), $
                         'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p4)+'!9'+pm+'!x'+num2string(err_opt_z_p4)]
              if foc_corr ne 0.d0 then leg_txt = [leg_txt, $
                                                  'Opt. AVG '+strtrim(focus_type,2)+': '+$
                                                  num2string(opt_z_p4+foc_corr)+'!9'+pm+'!x'+num2string(err_opt_z_p4)]
           endelse
           legendastro, leg_txt, box = 0, chars = 0.6
           
           yra = minmax([fit_p2, fwhm_res])
           ploterror, focus, fwhm_res, sigma_fwhm_res, $
                      psym = 8, xtitle='Focus [mm]',position=pp[0, 2,*], /noerase, chars=0.6, /xs, xra=xra
           oplot, xx, fit_p2, col = 250
           oplot, [1,1]*opt_z_p2, [-1,1]*1e10, col=70
           ;;lfit = linfit( focus, fwhm_res, measure_errors=sigma_fwhm_res)
           ;;oplot, [-10,10], lfit[0] + lfit[1]*[-10,10], line=2
           if get_focus_error eq 0 then begin
              leg_txt = ['FWHM A'+strtrim(iarray,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p2)]
              if foc_corr ne 0.d0 then leg_txt = [leg_txt, 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p2+foc_corr)]
           endif else begin
              leg_txt = ['FWHM A'+strtrim(iarray,2), $
                         'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p2)+'!9'+pm+'!x'+num2string(err_opt_z_p2)]
              if foc_corr ne 0.d0 then leg_txt = [leg_txt, $
                                                  'Opt. AVG '+strtrim(focus_type,2)+': '+$
                                                  num2string(opt_z_p2+foc_corr)+'!9'+pm+'!x'+num2string(err_opt_z_p2)]
           endelse
           legendastro, leg_txt, box = 0, chars = 0.6
           
           yra = minmax([fit_p3, ellipt_res])
           ploterror, focus, ellipt_res, sigma_ellipt_res, $
                      psym=8, xtitle='Focus [mm]', position=pp[0, 3,*], /noerase, /xs, chars=0.6, xra=xra
           oplot, xx, fit_p3, col=250
           oplot, [1,1]*opt_z_p3, [-1,1]*1e10, col=70
           ;;lfit = linfit( focus, ellipt_res, measure_errors=sigma_ellipt_res)
           ;;oplot, [-10,10], lfit[0] + lfit[1]*[-10,10], line=2
           leg_txt = ['Ellipt A'+strtrim(iarray,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p3)]
           if foc_corr ne 0.d0 then leg_txt = [leg_txt, 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p3+foc_corr)]
           legendastro, leg_txt, box = 0, chars = 0.6
           
        endif
        
     
        result_file = result_dir+"/focus_results_"+strtrim(kp[ikid].numdet, 2)+".save"
        save, focus_res, err_focus_res, focus_type, focus, cp1_all, peak_res, sigma_peak_res, $
              cp2_all, fwhm_res, sigma_fwhm_res, cp3_all, ellipt_res, sigma_ellipt_res, $
              cp4_all, flux_res, sigma_flux_res, file=result_file
        
        outplot, /close

     endif ;; enough scans (nscan_ok > 2)
        
  endfor ;; kids
  
end
