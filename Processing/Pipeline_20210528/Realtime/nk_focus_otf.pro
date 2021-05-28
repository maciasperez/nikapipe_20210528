

pro nk_focus_otf, scan_list, param = param, reset = reset, imbfits=imbfits, $
                  one_mm_only = one_mm_only, two_mm_only = two_mm_only, $
                  educated = educated,  noskydip = noskydip, iconic=iconic, $
                  a1_discard=a1_discard, a2_discard=a2_discard, a3_discard=a3_discard, $ 
                  xyguess=xyguess, radius=radius, mask=mask, largemap=largemap, $
                  nasmyth=nasmyth, ps=ps, nopng=nopng, rmax_keep=rmax_keep, rmin_keep=rmin_keep, $
                  get_focus_error=get_focus_error, imzoom=imzoom, noscp=noscp, focus_res=focus_res, $
                  subscan_min=subscan_min, subscan_max=subscan_max, k_noise=k_noise, output_root_dir=output_root_dir, $
                  sn_min=sn_min, sn_max=sn_max, cp1_all=cp1_all, cp2_all=cp2_all, cp3_all=cp3_all, noplot=noplot, $
                  scale=scale, iter=iter, plot_output_dir=plot_output_dir, doscp=doscp
  
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

if not keyword_set(scale) then scale=1
if not keyword_set(nopng) then png=1

if not keyword_set(output_root_dir) then output_root_dir = !nika.plot_dir

nscans = n_elements(scan_list)
if not keyword_set(k_noise) then k_noise =  0.2

focusx =  dblarr(nscans)
focusy =  dblarr(nscans)
focusz =  dblarr(nscans)

nscans_processed = 0
for iscan=0, n_elements(scan_list)-1 do begin
   output_dir = output_root_dir+"/v_1/"+scan_list[iscan]
   file_save = output_dir+"/results.save"
   print,file_save
   if file_test(file_save) then nscans_processed++ else message, /info, "scan "+scan_list[iscan]+" was not reduced"
endfor

if nscans_processed lt 3 then begin
   message, /info, "Not enough reduced scans to perform a fit."
   message, /info, "Please relaunch with more scans."
   return
endif

if not keyword_set(plot_output_dir) then plot_output_dir = !nika.plot_dir+"/Logbook/Scans/"+scan_list[nscans-1]
spawn, "mkdir -p "+plot_output_dir
if keyword_set(ps) and not keyword_set(noplot) then wind, 1, 1, xs = 1500, ys = 700, iconic=iconic


array_list = [1, 2, 3]
if keyword_set(one_mm_only) then array_list = [1, 3]
if keyword_set(two_mm_only) then array_list = [2]
if keyword_set(a1_discard) then array_list = array_list[where(array_list ne 1)]
if keyword_set(a2_discard) then array_list = array_list[where(array_list ne 2)]
if keyword_set(a3_discard) then array_list = array_list[where(array_list ne 3)]

narrays = n_elements(array_list)


wind, 1, 1, /free, /large
outplot, file = plot_output_dir+"/maps_focus_otf_"+strtrim(scan_list[nscans-1],2), png = png, ps = ps
ymin_multiplot = 0.3
my_multiplot, nscans, 3, pp, pp1, /rev, /full, /dry, gap_y=0.05, gap_x=0.05
fwhm_res         = dblarr(nscans, 3)
sigma_fwhm_res   = dblarr(nscans, 3)
ellipt_res       = dblarr(nscans, 3)
sigma_ellipt_res = dblarr(nscans, 3)
peak_res         = dblarr(nscans, 3)
sigma_peak_res   = dblarr(nscans, 3)

chi2_res            = dblarr(nscans, 3)
flux_ratio          = dblarr(nscans, 3)
residual_ampl_ratio = dblarr(nscans, 3)

max_res1 = 0.
max_res2 = 0.
max_res3 = 0.

for iscan = 0, n_elements(scan_list)-1 do begin
   
   output_dir = output_root_dir+"/v_1/"+scan_list[iscan]
   file_save = output_dir+"/results.save"
   if file_test(file_save) then begin

      restore, output_dir+"/results.save"
      param = param1
      grid = grid1
      info = info1
      kidpar = kidpar1 

      if keyword_set( iconic) then param.iconic = 1 
      if keyword_set(noskydip) then param.do_opacity_correction = 0
      if keyword_set(rmax_keep) then begin
         param.rmax_keep = rmax_keep
         if (param.rmax_keep le 100. and strupcase( param.map_proj) eq "NASMYTH") then guess_fit_par=1. 
      endif
      param.plot_ps  = 0
      if keyword_set(ps) then begin
         param.plot_ps = 1
         png=0
      endif
      
      focusx[iscan] = info.focusx
      focusy[iscan] = info.focusy
      focusz[iscan] = info.focusz

      educated = 1
      if keyword_set(xyguess) then begin
         xguess = info.NASMYTH_OFFSET_X
         yguess = info.NASMYTH_OFFSET_Y
      endif

      grid_tags = tag_names(grid)
      r_in_tab=[6., 15., 6.]
      for jarray=0, narrays-1 do begin
         iarray = array_list[jarray]
         print, '***'
         print, 'A', strtrim(iarray,2)
         if defined(best_models) eq 0 then begin
            best_models = dblarr(3,nscans,n_elements(grid1.map_i1[*,0]),n_elements(grid1.map_i1[0,*]))
         endif
         wmap = where( strupcase(grid_tags) eq "MAP_I"+strtrim(iarray,2), nwmap)
         if nwmap ne 0 then begin
            whits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(iarray,2), nwhits)
            if max(grid.(whits)) gt 0 then begin
               wvar = where( strupcase(grid_tags) eq "MAP_VAR_I"+strtrim(iarray,2), nwmap)

               delvarx, imrange_i
               nk_map_photometry, grid.(wmap), grid.(wvar), grid.(whits), $
                                  grid.xmap, grid.ymap, !nika.fwhm_array[iarray-1], $
                                  flux, sigma_flux, $
                                  sigma_bg, output_fit_par, output_fit_par_error, $
                                  bg_rms, flux_center, sigma_flux_center, sigma_bg_center, $
                                  coltable=coltable, imrange=imrange_i, imzoom=imzoom,$ ;HA commented imzoom=imzoom, $
                                  educated=educated, ps_file=ps_file, position=pp[iscan,iarray-1,*], $
                                  k_noise=k_noise, param=param, noplot=noplot, $ ;/image_only, $
                                  NEFD_source=nefd, info=info, /nobar, chars=0.7, $
                                  title=strmid(param.scan,8)+" A"+strtrim(iarray,2), $
                                  xguess=xguess, yguess=yguess, /show_fit, /image, guess_fit_par=guess_fit_par, $
                                  best_model=best_model, grid_step=!nika.grid_step[iarray-1]


               ;; Fit only near the very center and far from it to
               ;; avoid side lobes
               d = sqrt( (grid.xmap-output_fit_par[4])^2 + (grid.ymap-output_fit_par[5])^2)
               rbg = 100.
               ;wfit = where( (grid.(wmap) gt 0.5*flux and d le rbg) or (d ge rbg and grid.(wvar) lt mean(grid.(wvar))), nwfit, compl=wout)
               print, 'side lobe mask r_in =', 0.5*flux
               ;rbg = 150.
               ;wfit = where( (grid.(wmap) gt 0.2*flux_center and d le rbg) or (d ge rbg and grid.(wvar) lt mean(grid.(wvar))), nwfit, compl=wout)
               wfit = where( (d le r_in_tab[iarray-1]) or (d ge rbg and grid.(wvar) lt mean(grid.(wvar))), nwfit, compl=wout)
               print, 'side lobe mask r_in (fixed) =',  r_in_tab[iarray-1]
               map_var = grid.(wvar)
               map_var[wout] = 0.d0

               ;;----------------
               ;; Under bad weather, this fit is less robust than the
               ;; previous one, so we should not do it and overwrite
               ;; output_fit_par.
               ;; NP. Sept. 22nd, 2018.
;;               nk_fitmap, grid.(wmap), map_var, grid.xmap, grid.ymap, output_fit_par
;;               phi = dindgen(100)/99.*2*!dpi
;;               cosphi = cos(phi)
;;               sinphi = sin(phi)
;;               oplot, output_fit_par[4]+output_fit_par[2]/!fwhm2sigma*cosphi, $
;;                      output_fit_par[5]+output_fit_par[3]/!fwhm2sigma*sinphi, col=250
               ;;----------------
               
               fwhm = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma
               ellipt = max(output_fit_par[2:3])/min(output_fit_par[2:3])
               
               peak_res[  iscan,iarray-1] = output_fit_par[1]
               fwhm_res[  iscan,iarray-1] = fwhm
               ellipt_res[iscan,iarray-1] = ellipt

               main_beam_flux = output_fit_par[1]*(2.d0*!dpi*(fwhm*!fwhm2sigma)^2)

               ;; Look at residuals
               map_fit = nika_gauss2( grid.xmap, grid.ymap, output_fit_par)
               map_residuals = map_fit*0.d0
               w = where( grid.(whits) ne 0 and finite(grid.(wvar)))
               map_residuals[w] = (grid.(wmap)-map_fit)[w]

               ;; signal to noise
               map_sn = map_fit*0.d0
               map_sn[w] = abs( (grid.(wmap))[w])/sqrt( (grid.(wvar))[w])
               wsig3 = where( map_sn ge 3, nwsig3)
               if nwsig3 eq 0 then message, "No pixel with S/N >= 3"

               wchi2 = where( finite(map_var) and map_var gt 0.d0 and d le rbg, nwchi2)
               if nwchi2 eq 0 then message, "No pixel with finite and non zero variance"
               chi2_res[            iscan, iarray-1] = total( map_residuals[wchi2]^2/map_var[wchi2])/total(1./map_var[wchi2])
               flux_ratio[          iscan, iarray-1] = total( map_residuals[wchi2]*grid.map_reso^2)/main_beam_flux
               residual_ampl_ratio[ iscan, iarray-1] = max(   map_residuals[wsig3])/output_fit_par[1]

               if iarray eq 1 then begin
                  if max(abs(map_residuals[wchi2])) gt max_res1 then max_res1 = max(abs(map_residuals[wchi2]))
               endif else if iarray eq 2 then begin
                  if max(abs(map_residuals[wchi2])) gt max_res2 then max_res2 = max(abs(map_residuals[wchi2]))
               endif else begin
                  if max(abs(map_residuals[wchi2])) gt max_res3 then max_res3 = max(abs(map_residuals[wchi2]))
               endelse
               
               best_models[iarray-1,iscan,*,*] = map_fit ;best_model
               if not keyword_set(noplot) then begin
                  legendastro, 'FWHM '+string(fwhm,format='(F6.2)'), box=0, textcol=250, chars=0.7
                  if keyword_set(imzoom) and keyword_set(xyguess) then $
                     legendastro, [strtrim(string(xguess,format='(F6.1)'),2)+','+$
                                   strtrim(string(yguess,format='(F6.1)'),2)], box=0, textcol=250, chars=0.7, $
                                  psym=[1], col=[250], pos=[xguess-45, yguess+40]
                  fmt = '(F5.2)'
                  legendastro, ['Foc. X: '+string(info.focusx,format=fmt), $
                                'Foc. Y: '+string(info.focusy,format=fmt), $
                                'Foc. Z: '+string(info.focusz,format=fmt)], box=0, textcol=255, /bottom, chars=0.7
               endif
               ;; peak_res[      iscan, iarray-1] = flux
               ;; fwhm_res[      iscan, iarray-1] = fwhm
               ;; ellipt_res[    iscan, iarray-1] = ellipt
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
;;                print, "output_fit_par_error: ", $
;;                       output_fit_par_error
;;                print, "sigma_fwhm_res["+strtrim(iscan,2)+", "+strtrim(iarray-1,2)+"]: ", $
;;                       sigma_fwhm_res[ iscan, iarray-1]
;;                print, "sigma_ellipt_res["+strtrim(iscan,2)+", "+strtrim(iarray-1,2)+"]: ", $
;;                       sigma_ellipt_res[iscan,iarray-1]
;;               stop
            endif
         endif
      endfor
   endif
endfor
outplot, /close
my_multiplot, /reset


;; Discard scans that may have returned a NaN value
scan_discard = intarr(nscans)
for iarray=1, 3 do begin
   w = where( finite(peak_res[*,iarray-1]) eq 0, nw)
   if nw ne 0 then begin
      for i=0, nw-1 do message, /info, "Scan "+scan_list[i]+" returned infinite flux estimate"
      scan_discard[w] = 1
   endif
   w = where( finite(fwhm_res[*,iarray-1]) eq 0, nw)
   if nw ne 0 then begin
      for i=0, nw-1 do message, /info, "Scan "+scan_list[i]+" returned infinite FWHM estimate"
      scan_discard[w] = 1
   endif
   w = where( finite(ellipt_res[*,iarray-1]) eq 0, nw)
   if nw ne 0 then begin
      for i=0, nw-1 do message, /info, "Scan "+scan_list[i]+" returned infinite ellipticity estimate"
      scan_discard[w] = 1
   endif
endfor

wkeep = where( scan_discard eq 0, nwkeep)
if nwkeep lt 3 then begin
   message, /info, "Not enough valid scans to fit, please relaunch the focus sequence"
   return
endif
scan_list = scan_list[wkeep]
nscans = n_elements(scan_list)
peak_res = peak_res[wkeep,*]
fwhm_res = fwhm_res[wkeep,*]
ellipt_res = ellipt_res[wkeep,*]
sigma_peak_res   = sigma_peak_res[wkeep,*]
sigma_fwhm_res   = sigma_fwhm_res[wkeep,*]
sigma_ellipt_res = sigma_ellipt_res[wkeep,*]
focusx = focusx[wkeep]
focusy = focusy[wkeep]
focusz = focusz[wkeep]

;; If the beam fit returned 0 or NaN values for error bars (while the
;; fit may look good sometimes... ?!), discard the scan for the fit
for jarray=0, narrays-1 do begin
   iarray = array_list[jarray]
   w = where( sigma_peak_res[*,iarray-1] eq 0. or $
              sigma_peak_res[*,iarray-1] gt 1000, nw)
   if nw ne 0 then begin
      message, /info, ""
      message, /info, "sigma_peak_res["+strtrim(w,2)+", "+strtrim(iarray-1,2)+"] = "+$
               strtrim(sigma_peak_res[w,iarray-1])
      message, /info, "is likely to crash the fit."
      message, /info, "press .c to try anyway or discard "+scan_list[w]+" from scan_list and relaunch"
      stop
   endif

   w = where( sigma_fwhm_res[*,iarray-1] eq 0. or $
              sigma_fwhm_res[*,iarray-1] gt 1000, nw)
   if nw ne 0 then begin
      message, /info, ""
      ;;message, /info, "sigma_fwhm_res["+strtrim(w,2)+", "+strtrim(iarray-1,2)+"] = "+$
      ;;         strtrim(sigma_fwhm_res[w,iarray-1])
      message, /info, "is likely to crash the fit."
      ;;message, /info, "press .c to try anyway or discard "+scan_list[w]+" from scan_list and relaunch"
      stop
   endif

   w = where( sigma_ellipt_res[*,iarray-1] eq 0. or $
              sigma_ellipt_res[*,iarray-1] gt 1000, nw)
   if nw ne 0 then begin
      message, /info, ""
      ;;lp
      ;;message, /info, "sigma_ellipt_res["+strtrim(w,2)+", "+strtrim(iarray-1,2)+"] = "+$
      ;;         strtrim(sigma_ellipt_res[w,iarray-1])
      message, /info, "is likely to crash the fit."
      ;;message, /info, "press .c to try anyway or discard "+scan_list[w]+" from scan_list and relaunch"
      stop
   endif
endfor

if nk_stddev(focusx) ne 0 then focus_var = focusx
if nk_stddev(focusy) ne 0 then focus_var = focusy
if nk_stddev(focusz) ne 0 then focus_var = focusz
order_scans = sort(focus_var)

xmap = grid.map_reso*(replicate(1, grid.nx) ## dindgen(grid.nx)) - grid.map_reso*(grid.nx-1)/2.0
ymap = transpose(xmap)
rmap = sqrt(xmap^2+ymap^2)
rad_off_center = 100.
wimrange = where(rmap lt rad_off_center)
wind, 1, 1, /free, xsize=1200, ysize=700
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
      for jarray=0, narrays-1 do begin
         iarray = array_list[jarray]
         wmap = where( strupcase(grid_tags) eq "MAP_I"+strtrim(iarray,2), nwmap)
         map_data = grid.(wmap)
         map_model = best_models[iarray-1,iscan,*,*]
         wpos = where(order_scans eq iscan)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
         resid_map=map_data-map_model[0,0,*,*]
         resid_size=size(resid_map)
         resid_centre=[resid_size[1]/2,resid_size[2]/2]
         xc = double(findgen(resid_size[1]))+1.0-resid_centre[0]   ;
         yc = double(findgen(resid_size[2]))+1.0-resid_centre[1]   ;
         x = xc # (yc*0 +1)   ; array of X-values (centered)
         y = (xc*0 +1) # yc   ; array of Y-values (centered)
;         r = sqrt(x^2 + y^2)
         posind=where(resid_map gt 0 and x gt -30 and x lt 30 and y gt -30 and y lt 30,npos)
         negind=where(resid_map lt 0 and x gt -30 and x lt 30 and y gt -30 and y lt 30,nneg)
         poscen=[total(resid_map[posind]*x[posind])/total(resid_map[posind]),total(resid_map[posind]*y[posind])/total(resid_map[posind])]
         negcen=[total(resid_map[negind]*x[negind])/total(resid_map[negind]),total(resid_map[negind]*y[negind])/total(resid_map[negind])]
         difcen=poscen-negcen
         difdist=sqrt(total(difcen^2))
         residrms=stddev(resid_map[120:180,120:180])

         ;; back to default imrange
         ;; NP. Dec. 7th, 2016
         nobar = 0
         charbar=0.7
         inside_bar=1
;         imrange = minmax(resid_map) ; avg(resid_map) + [-1,1]*5*stddev(resid_map)

         case iarray of
            1: begin
               xcenter = info.result_off_x_1
               ycenter = info.result_off_y_1
            end
            2: begin
               xcenter = info.result_off_x_2
               ycenter = info.result_off_y_2
            end
            3: begin
               xcenter = info.result_off_x_3
               ycenter = info.result_off_y_3
            end
         endcase
         xrange = xcenter + [-1,1]*rad_off_center
         yrange = ycenter + [-1,1]*rad_off_center

         if iarray eq 1 then imrange = [-1,1]*max_res1 * scale
         if iarray eq 2 then imrange = [-1,1]*max_res2 * scale
         if iarray eq 3 then imrange = [-1,1]*max_res3 * scale

         imview, resid_map, xmap=grid.xmap, ymap=grid.ymap, position=pp[wpos,iarray-1,*], /noerase, imrange=imrange, $
                 title=strmid(param.scan,8)+" A"+strtrim(iarray,2), xtitle=xtitle, ytitle=ytitle, $
                 /noclose, postscript=ps_file, chars=0.7, inside_bar=inside_bar, orientation=orientation, nobar=0, $
                 charbar=charbar,xrange=xrange, yrange=yrange, coltable=39
;         oplot,[poscen[0]]+resid_centre[0],[poscen[1]]+resid_centre[1],psym=1,symsize=3,thick=3
;         oplot,[negcen[0]]+resid_centre[0],[negcen[1]]+resid_centre[1],psym=2,symsize=3,thick=3
         legendastro, ['Res. RMS: '+string(residrms,format=fmt),'Bary. offsets: '+string(difdist,format=fmt)], box=0, textcol=0, chars=0.7
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;        
         fmt = '(F5.2)'
         legendastro, ['Foc. X: '+string(info.focusx,format=fmt), $
                       'Foc. Y: '+string(info.focusy,format=fmt), $
                       'Foc. Z: '+string(info.focusz,format=fmt)], box=0, textcol=0, /bottom, chars=0.7
      endfor
   endif
endfor
outplot, /close
my_multiplot, /reset

;; Check if it's a focus x,y,z
foc_corr = 0.d0
if max(focusz)-min(focusz) ne 0 then begin
   focus = focusz
   focus_type =  "Z"
   ;; Add an extra correction of -0.2 to give the "average" focus rather than
   ;; the focus derived at the center of each arrays (Apr. 18th, 2017)
   ;; foc_corr = -0.2d0
   ;; NP, June 19th, after discussion with SL at IRAM meeting on June 15th
   foc_corr = -0.3d0

   ;; NP, Jan. 10th, after discussion with SL, LP, JFL, JFM, HA: no
   ;; strong difference between -0.3 and -0.2 while -0.2 should leave
   ;; us more margin with beam distorsions observed in reality and not
   ;; directly predictable with Zemax.
   foc_corr = -0.2d0
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
            ut:'', $
            day:param.day, $
            source:param.source, $
            scan_type:'Lissajous', $
            mean_elevation: string(info.elev, format=fmts), $
            tau_1mm: string(kidpar[0].tau_skydip, format=fmts), $
            tau_2mm: string(kidpar[0].tau_skydip, format=fmts), $
            result_name:strarr(nres), $
            result_value:dblarr(nres)+!values.d_nan, $
            comments:'', $
            az:0., $
            el:0.}
log_info.scan_type = info.obs_type
log_info.source    = param.source
log_info.ut = info.ut
log_info.az = info.azimuth_deg
log_info.el = info.result_elevation_deg

;; Fit optimal focus
dxfocus = (max(focus)-min(focus))
xx = dindgen(100)/99*dxfocus*1.4 + min(focus)-dxfocus*0.2

if param.plot_ps eq 0 then wind, 1, 1, /free, /large
scan_plot_file = plot_output_dir+"/plot_"+strtrim(scan_list[nscans-1],2)

;; Do not overwrite the map produced for the last scan of the sequence
if file_test(scan_plot_file+".png") then spawn, "\cp "+scan_plot_file+".png "+plot_output_dir+"/map_"+strtrim(scan_list[nscans-1],2)+".png"
wind, 1, 1, /free, /large
outplot, file = scan_plot_file, png = png, ps = ps
my_multiplot, 3, 3, pp, pp1, /rev, gap_x=0.05, ymargin=0.05, gap_y=0.05
focus_res = dblarr(3,3)
err_focus_res = 0
if keyword_set(get_focus_error) then err_focus_res = dblarr(3,3)

cp1_all = dblarr(3,n_elements(peak_res[0,*]))
cp2_all = dblarr(3,n_elements(peak_res[0,*]))
cp3_all = dblarr(3,n_elements(peak_res[0,*]))

for myi=0, narrays-1 do begin
   iarray = array_list[myi]
   
   if not(keyword_set(get_focus_error)) then begin
      cp1 = poly_fit( focus, peak_res[*,iarray-1], 2, measure_errors = sigma_peak_res[*,iarray-1])

      ;; Renormalize error bars
      fit_value = focus*0.d0
      n = n_elements(focus)
      for i = 0, n_elements(cp1)-1 do fit_value += cp1[i]*focus^i
      chi2 = total( (peak_res[*,iarray-1]-fit_value)^2/sigma_peak_res[*,iarray-1]^2)/(n-1)
      sigma_peak_res[*,iarray-1] *= sqrt( (n-1)*chi2)
      cp1 = poly_fit( focus, peak_res[*,iarray-1], 2, measure_errors = sigma_peak_res[*,iarray-1])

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
      nparams =  3
      if nscans eq 3 then nparams=2
      nddl = float(nscans - nparams)
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
   
   ;; Adding foc_corr to compute the best "average" focus over the arrays rather
   ;; than the best "central" focus (Apr. 18th, 2017)
   focus_res[iarray-1, 0] = opt_z_p1 + foc_corr
   focus_res[iarray-1, 1] = opt_z_p2 + foc_corr
   focus_res[iarray-1, 2] = opt_z_p3 + foc_corr
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
      dyra = max([fit_p1, reform(peak_res[*,iarray-1])]) - min([fit_p1, reform(peak_res[*,iarray-1])])
      yra = minmax([fit_p1, reform(peak_res[*,iarray-1])]) + [-0.3,0.5]*dyra
      ploterror, focus, peak_res[*,iarray-1], sigma_peak_res[*,iarray-1], $
                 psym = 8, xtitle='Focus [mm]', position=pp[iarray-1,0,*], /noerase, chars=0.7, /xs, $
                 xra=xra, yra=yra, /ys
      xyouts, focus-0.05, peak_res[*,iarray-1]+0.05, strmid(scan_list,9), orient=90, chars=0.7
      ;; lfit = linfit( focus, peak_res[*,iarray-1], measure_errors=sigma_peak_res[*,iarray-1])
      ;; oplot, [-10,10], lfit[0] + lfit[1]*[-10,10]
      lfit = poly_fit( focus, peak_res[*,iarray-1], 1, measure_errors=sigma_peak_res[*,iarray-1], $
                       status=status)
      if status eq 0 then oplot, [-10,10], lfit[0] + lfit[1]*[-10,10]

      oplot, xx, fit_p1, col = 250
      oplot, [1,1]*opt_z_p1, [-1,1]*1e10, col=70
      leg_txt = ['Flux A'+strtrim(iarray,2), $
                 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p1), $
                 "Incl. foc. corr ("+string(foc_corr,form='(F4.1)')+"): "+$
                 num2string(opt_z_p1+foc_corr)]
      textcol = [!p.color, 70, 250]
      if keyword_set(get_focus_error) then begin
         leg_txt[1] += '!9'+pm+'!x'+num2string(err_opt_z_p1)
      endif
      legendastro, leg_txt, box = 0, chars = 0.7, textcol=textcol
;      if foc_corr ne 0.d0 then legendastro, 'Incl. foc corr '+string(foc_corr,form='(F4.1)'), chars=0.7, /bottom

      yra = minmax([fit_p2, reform(fwhm_res,nn)])
      ploterror, focus, fwhm_res[*,iarray-1], sigma_fwhm_res[*,iarray-1], $
                 psym = 8, xtitle='Focus [mm]',position=pp[iarray-1,1,*], /noerase, chars=0.7, /xs, xra=xra
      oplot, xx, fit_p2, col = 250
      oplot, [1,1]*opt_z_p2, [-1,1]*1e10, col=70
      ;; lfit = linfit( focus, fwhm_res[*,iarray-1],
      ;; measure_errors=sigma_fwhm_res[*,iarray-1])
      lfit = poly_fit( focus, fwhm_res[*,iarray-1], 1, measure_errors=sigma_fwhm_res[*,iarray-1], status=status)
      if status eq 0 then oplot, [-10,10], lfit[0] + lfit[1]*[-10,10]
      leg_txt = ['FWHM A'+strtrim(iarray,2), $
                 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p2), $
                 "Incl. foc. corr ("+string(foc_corr,form='(F4.1)')+"): "+$
                 num2string(opt_z_p2+foc_corr)]
      textcol = [!p.color, 70, 250]
      if keyword_set(get_focus_error) then begin
         leg_txt[1] += '!9'+pm+'!x'+num2string(err_opt_z_p2)
      endif
      legendastro, leg_txt, box = 0, chars = 0.7, textcol=textcol
;      if foc_corr ne 0.d0 then legendastro, 'Incl. foc corr '+string(foc_corr,form='(F4.1)'), chars=0.7, /bottom
      
      yra = minmax([fit_p3, reform(ellipt_res,nn)])
      ploterror, focus, ellipt_res[*,iarray-1], sigma_ellipt_res[*,iarray-1], $
                 psym=8, xtitle='Focus [mm]', position=pp[iarray-1,2,*], /noerase, /xs, chars=0.7, xra=xra
      oplot, xx, fit_p3, col=250
      oplot, [1,1]*opt_z_p3, [-1,1]*1e10, col=70
      ;; lfit = linfit( focus, ellipt_res[*,iarray-1], measure_errors=sigma_ellipt_res[*,iarray-1])
      lfit = poly_fit( focus, ellipt_res[*,iarray-1], 1, measure_errors=sigma_ellipt_res[*,iarray-1], status=status)
      if status eq 0 then oplot, [-10,10], lfit[0] + lfit[1]*[-10,10]
      leg_txt = ['Ellipt A'+strtrim(iarray,2), $
                 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p3), $
                 "Incl. foc. corr ("+string(foc_corr,form='(F4.1)')+"): "+$
                 num2string(opt_z_p3+foc_corr)]
      textcol = [!p.color, 70, 250]
      if keyword_set(get_focus_error) then begin
         leg_txt[1] += '!9'+pm+'!x'+num2string(err_opt_z_p3)
      endif
      legendastro, leg_txt, box = 0, chars = 0.7, textcol=textcol
;;      if foc_corr ne 0.d0 then legendastro, 'Incl. foc corr '+string(foc_corr,form='(F4.1)'), chars=0.7, /bottom
      
   endif
   
   if not(keyword_set(get_focus_error)) then begin
      log_info.result_name[  2*(iarray-1)    ] = "focus_peak_A"+strtrim(iarray,2)
      log_info.result_name[  2*(iarray-1) + 1] = "focus_fwhm_A"+strtrim(iarray,2)   
      log_info.result_value[ 2*(iarray-1)    ] = focus_res[iarray-1,0] ; opt_z_p1
      log_info.result_value[ 2*(iarray-1) + 1] = focus_res[iarray-1,1] ; opt_z_p2
   endif else begin
      log_info.result_name[  4*(iarray-1)    ] = "focus_peak_A"+strtrim(iarray,2)
      log_info.result_name[  4*(iarray-1) + 1] = "focus_fwhm_A"+strtrim(iarray,2)
      log_info.result_name[  4*(iarray-1) + 2] = "err_focus_peak_A"+strtrim(iarray,2)
      log_info.result_name[  4*(iarray-1) + 3] = "err_focus_fwhm_A"+strtrim(iarray,2)
      log_info.result_value[ 4*(iarray-1)    ] = focus_res[iarray-1,0] ; opt_z_p1
      log_info.result_value[ 4*(iarray-1) + 1] = focus_res[iarray-1,1] ; opt_z_p2
      log_info.result_value[ 4*(iarray-1) + 2] = err_opt_z_p1
      log_info.result_value[ 4*(iarray-1) + 3] = err_opt_z_p2
   endelse
   
endfor
outplot, /close

;; Create a html page with plots from this scan
;; save, file=plot_output_dir+"/log_info.save", log_info
save, file=plot_output_dir+"/focus_nklog_info.save", log_info
nk_logbook_sub, param.scan_num, param.day

;; Update logbook
nk_logbook, param.day


print, "scans                          : ", scan_list
for iarray=1, 3 do begin
   print, "------------------------"
   print, "A"+strtrim(iarray,2)
   print, "chi2                           : ", string( transpose( chi2_res[            *,iarray-1]), format='(F12.3)')
;   print, "main beam flux                 : ", string( transpose( peak_res[            *,iarray-1]), format='(F12.3)')
;   print, "main beam fwhm                 : ", string( transpose( fwhm_res[            *,iarray-1]), format='(F12.3)')
;   print, "main beam ellipt               : ", string( transpose( ellipt_res[          *,iarray-1]), format='(F12.3)')
   print, "side lobes/main beam flux ratio: ", string( transpose( flux_ratio[          *,iarray-1]), format='(F12.3)')
   print, "residual_ampl/main beam ampl   : ", string( transpose( residual_ampl_ratio[ *,iarray-1]), format='(F12.3)')
endfor

print, ""
print, "***************************"
print, "      FOCUS results"
print, "***************************"
print, ""
print, "To be used directly in PAKO"
print, "Check the best fit value and give priority to the value derived from flux optimization:"
print, ""
if foc_corr ne 0.d0 then $
   pretxt = 'Opt. AVG focus ('+string(foc_corr,form='(F4.1)')+' applied)/ ' else pretxt = 'Opt. focus / '

for iarray=1,3 do begin
   print, pretxt+"Flux A"+strtrim(iarray,2)+": "+string( focus_res[iarray-1,0], format='(F5.2)')
endfor
print, "avg. of A1 and A3: "
print, "==> Priority 1: set focus "+string( (focus_res[0,0]+focus_res[2,0])/2.,form='(F5.2)')

print, ""
for iarray=1,3 do begin
   print, pretxt+"FWHM A"+strtrim(iarray,2)+": "+string( focus_res[iarray-1,1], format='(F5.2)')
endfor
print, "avg. of A1 and A3: "
print, "==> Priority 2: set focus "+string( (focus_res[0,1]+focus_res[2,1])/2.,form='(F5.2)')
print, ""
for iarray=1, 3 do begin
   print, pretxt+"Ellipticity A"+strtrim(iarray,2)+": "+string( focus_res[iarray-1,2], format='(F5.2)')
endfor
print, "avg. of A1 and A3: "
print, "==> Priority 3: set focus "+string( (focus_res[0,2]+focus_res[2,2])/2.,form='(F5.2)')

;; Rsync the logbook
if keyword_set(doScp) or (!host eq 'nika2a') then $
   spawn, "rsync -avuzq $NIKA_PLOT_DIR/Logbook t22@mrt-lx1.iram.es:./samuel/. 2> /dev/null"

end
