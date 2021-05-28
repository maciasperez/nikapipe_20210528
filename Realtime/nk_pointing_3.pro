
;+
;
; SOFTWARE: Real time analysis: derives telescope pointing offsets
;
; NAME: 
; nk_pointing
;
; CATEGORY: general, RTA
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Derives telescope pointing offsets
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Oct. 13th, 2015: Cleaned up nk_pointing and adjusted to NIKA2
;        - Mar. 15th, 2016: NP. Upgraded version of nk_pointing_2 to match the
;          cleaned up version of nk_rta.pro
;-
;================================================================================================

pro nk_pointing_3, scan, pako_str, param, info, $
                   online=online, p2cor=p2cor, p7cor=p7cor, nas_offset_x=nas_offset_x, nas_offset_y=nas_offset_y, $
                   ref_det=ref_det, obs_type = obs_type, $
                   nasmyth = nasmyth, sn_min = sn_min, sn_max = sn_max, $
                   fwhm_prof=fwhm_prof, outfoc=outfoc, ellipticity=ellipticity, $
                   data=data, kidpar=kidpar, xyguess=xyguess, radius=radius, azelguess=azelguess, grid=grid, $
                   raw_acq_dir=raw_acq_dir, plotting_verbose=plotting_verbose, rest=rest, $
                   all_ptg_instructions=all_ptg_instructions, show_surrounding_kids=show_surrounding_kids


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print," nk_pointing_3, scan, pako_str, $"
   print, "                   param=param, info=info, $"
   print, "                   online=online, p2cor=p2cor, p7cor=p7cor, nas_offset_x=nas_offset_x, nas_offset_y=nas_offset_y, $"
   print, "                   ref_det=ref_det, obs_type = obs_type, $"
   print, "                   nasmyth = nasmyth, sn_min = sn_min, sn_max = sn_max, $"
   print, "                   fwhm_prof=fwhm_prof, outfoc=outfoc, ellipticity=ellipticity, $"
   print, "                   data=data, kidpar=kidpar, xyguess=xyguess, radius=radius, azelguess=azelguess, grid=grid, $"
   print, "                   raw_acq_dir=raw_acq_dir, plotting_verbose=plotting_verbose, show_surrounding_kids=show_surrounding_kids"
   return
endif

if info.status eq 1 then begin
   message, /info, "info.status is 1 from the beginning: exiting"
   return
endif

message, /info, !nika.raw_acq_dir

;; Prepare output directory for plots and logbook
if keyword_set(nasmyth) then param.map_proj = "nasmyth" else param.map_proj = "azel"
;nk_init_grid, param, info, grid, radius=radius
nk_init_grid_2, param, info, grid

if keyword_set(online) then begin
   if not keyword_set(obs_type)     then begin
      message, /info, "You must set obs_type='cross' or obs_type='lissajous'"
      return
   endif
   if not keyword_set(p2cor)        then p2cor        = 0.d0
   if not keyword_set(p7cor)        then p7cor        = 0.d0
   if not keyword_set(nas_offset_x) then nas_offset_x = 0.d0
   if not keyword_set(nas_offset_y) then nas_offset_y = 0.d0

   init_pako_str, pako_str
   pako_str.p2cor = p2cor
   pako_str.p7cor = p7cor
   pako_str.NAS_OFFSET_X = nas_offset_x
   pako_str.NAS_OFFSET_Y = nas_offset_y
   pako_str.obs_type = obs_type
endif

outfoc = [info.focusx, info.focusy, info.focusz]

if keyword_set(nasmyth) and (abs(pako_str.p2cor) gt 0.01 or abs(pako_str.p7cor) gt 0.01) then begin
   print, ""
   print, "------------------------------------------"
   print, "Az, el pointing offsets are NOT 0 and 0, so"
   print, "I cannot compute the exact nasmyth offset correction in this context"
   print, "please SET POINTING 0 0 and run another cross"
   print, ""
   return
endif

if keyword_set(rest) then begin
   restore, "data_"+scan+".save"
endif else begin

   ;; Clean data and project maps
   nk_scan_preproc, param, info, data, kidpar, grid=grid, sn_min=sn_min, sn_max=sn_max, polar=param.polar
   
;; if not keyword_set(ref_det) then ref_det = !nika.ref_det[0]
;; Now take the pointing ref pixel on the 2mm, NP et al, Oct. 8th, 2016
   if keyword_set(ref_det) then begin
      w = where( kidpar.numdet eq ref_det and kidpar.type eq 1, nw)
      if nw eq 0 then begin
         message, /info, "The reference detector you're trying to use either does not exist or has type /= 1"
         message, /info, "Please choose another one and relaunch"
         return
      endif
      !nika.ref_det[kidpar[w].array-1] = ref_det
   endif else begin
      ref_det = !nika.ref_det[1]
   endelse
   
   w = where( kidpar.type eq 1 and kidpar.numdet eq ref_det, nw)
   if nw eq 0 then begin
      message, /info, "The chosen reference detector "+strtrim(ref_det,2)+" is non valid"
;      return
   endif
   ref_array = kidpar[w].array

   if info.status eq 1 then begin
      message, /info, "Problem during nk_scan_preproc:"
      print, info.error_message
      return
   endif

   if param.kid_monitor eq 1 then $
      kid_monitor, scan, data=data, kidpar=kidpar, output_kidpar_dir=!nika.plot_dir+"/KidMonitor"

   ;; Quick fix when /tune
   if max(data.subscan) eq 5 then begin
      data = data[ where( data.subscan ge 2)]
      data.subscan -=  1
   endif

   if keyword_set(xyguess) then begin
      nk_default_mask, param, info, grid, radius=radius, $
                       xcenter=info.NASMYTH_OFFSET_X, $
                       ycenter=info.NASMYTH_OFFSET_Y
      param.decor_method = 'common_mode_kids_out'
      xguess = info.NASMYTH_OFFSET_X
      yguess = info.NASMYTH_OFFSET_Y
      educated = 1
   endif

   if keyword_set(azelguess) then begin
      nk_default_mask, param, info, grid, radius=radius
      param.decor_method = 'common_mode_kids_out'
      xguess = 0.d0
      yguess = 0.d0
      educated = 1
   endif

   nk_mask_source, param, info, data, kidpar, grid
;;   message, /info, "fix me scan_reduce to scan_reduce_1"
;;   nk_scan_reduce, param, info, data, kidpar, grid
   nk_scan_reduce_1,  param, info, data, kidpar, grid
   
   ;; Save plots for the logbook
   w = where( !nika.plot_window gt 0, nw)
   if nw ne 0 and param.plot_png ne 0 then begin
      for iw=0, nw-1 do begin
         wset, !nika.plot_window[iw]
         png, param.plot_dir+"/monitor_"+strtrim(iw,2)+".png"
      endfor
   endif
   
   message, /info, "fix me: taking only the second cross"
   if max(data.subscan) ge 5 then begin
      data.subscan -= 5
      data = data[ where( data.subscan ge 1)]
   endif

;   message, /info, "fix me remove the stop and erase the save to save time"
;   save, param, info, data, kidpar, grid, file='data_'+scan+'.save'
;   stop
endelse


param.do_plot=1

nk_projection_4, param, info, data, kidpar, grid
param.output_dir = param.project_dir+"/v_"+strtrim(param.version,  2)+"/"+param.scan
param.do_plot = 0 ; to avoid the additional map plot in save_scan_results
nk_save_scan_results_3, param, info, data, kidpar, grid

;;=======================================================================================================
;;================================== Cross or Lissajous scan ============================================
;;=======================================================================================================
;; Display results
;; offsets = dblarr(3,2) ; 3 arrays for nika2, 2 offsets
offsets = dblarr(2) ; one offset in az, one offset in el: store only the results of the ref_det for safety.
nterms = 5
display_antenna_info = 0

outplot, file=param.plot_dir+"/plot_"+strtrim(param.scan), png = param.plot_png, ps = param.plot_ps

if strupcase( strtrim( pako_str.obs_type, 2)) eq "POINTING" then cross_scan = 1 else cross_scan = 0

fwhm_prof = dblarr(3,2,2)
ellipticity = dblarr(3)

;; ;;------------------------------------------
;; message, /info, "fix me:"
;; 
;; 
;; w1 = where( kidpar.type eq 1 and kidpar.array eq 1, nw1)
;; make_ct, nw1, ct
;; wind, 1, 1, /free, /large
;; my_multiplot, 1, 2, pp, pp1, /rev
;; ww1 = where( data.subscan eq 1)
;; ww2 = where( data.subscan eq 3)
;; yra = minmax(data.toi[w1])
;; ;plot, data[ww1].toi[w1[0]], /xs, position=pp1[0,*], yra=yra, /ys
;; ;plot, data[ww2].toi[w1[0]], /xs, position=pp1[1,*], yra=yra, /ys, /noerase
;; sigma = dblarr(nw1)
;; for i=0, nw1-1 do begin
;;    ikid = w1[i]
;;    plot, data[ww1].toi[ikid], /xs, position=pp1[0,*], $
;;          yra=yra, /ys, col=ct[i], title=strtrim(ikid,2)+", numdet: "+strtrim(kidpar[ikid].numdet,2)
;;    plot, data[ww2].toi[ikid], /xs, position=pp1[1,*], yra=yra, /ys, /noerase, col=ct[i]
;;    sigma[i] = stddev( [data[ww1].toi[ikid],data[ww2].toi[ikid]])
;; ;   wait, 0.2
;; endfor
;; wind, 1, 1, /free
;; plot,sigma
;; stop


;; message, /info, "fix me: convolution added"
;; ;mybeam = 
;; 
;; stop


;;ref_det_list = [3137, 3384, 3631, 3290, 3629, 3387, 3141, 3225, 3852, 3685, 3855]
;;ref_det_list = [ref_det]
;;;;for iref_det=0, n_elements(ref_det_list)-1 do begin
;;for iref_det=0, 0 do begin
;;   ref_det = ref_det_list[iref_det]
;;;;------------------------------------------


if cross_scan eq 1 then begin
   if param.plot_ps ne 1 then wind, 1, 1, /free, xs=1500, ys=700, title = 'nk_pointing_3', iconic = param.iconic
   
   ;; Init display parameters
   azel_field = ['az', 'el']
   ;; az,el section
   x1_azel = 0.05
   x2_azel = 0.2
   y1_azel = 0.02
   y2_azel = 0.98

   ;; Profiles section
   x1_prof = x2_azel+0.05
   x2_prof = 0.95
   y1_prof = y1_azel
   y2_prof = 0.5
   
   ;; Maps section
   x1_maps = x2_azel+0.05
   x2_maps = 0.99
   y1_maps = 0.55
   y2_maps = 0.95

   ;; pointing plots location
   my_multiplot, 1, 3, pp_p, pp1_p, /rev, $
                 xmin=x1_azel, ymin=y1_azel, xmax=x2_azel,  $
                 xmargin=1d-10, ymargin=0.01, ymax=y2_azel

   ;; profiles plots location
   my_multiplot, 2, 1, pp_prof, pp1_prof, /rev, $
                 xmin=x1_prof, ymin=y1_prof, xmax=x2_prof,  $
                 xmargin=1d-10, ymargin=0.01, ymax=y2_prof, gap_x=0.05, gap_y=0.05, /dry

   ;; Maps location
   my_multiplot, 3, 1, pp_maps, pp1_maps, /rev, $
                 xmin=x1_maps, ymin=y1_maps, xmax=x2_maps,  $
                 xmargin=1d-10, ymargin=0.01, ymax=y2_maps, /full, /dry

   ;; profiles plots location
   ;; test
   my_multiplot, 3, 2, pp_prof, pp1_prof, /rev, $
                 xmin=x1_prof, ymin=y1_prof, xmax=x2_prof,  $
                 xmargin=1d-10, ymargin=0.01, ymax=y2_prof, gap_x=0.05, gap_y=0.05, /dry

   ;;------------------------- pointing plots ---------------------------------

   ;; Speed flags: 11
   w    = nk_where_flag( data.flag[0], 11, nflag=nflag)
   time = data.a_t_utc-data[0].a_t_utc 
;   if keyword_set(plotting_verbose) then begin

   !p.charsize = 0.6
   make_ct, 4, ct
   ;; cross
   plot, data.ofs_az, data.ofs_el, position=pp1_p[0,*], xtitle='Ofs Az.', ytitle='Ofs. El.', /iso
   oplot, data.ofs_az, data.ofs_el, col=70
   if nflag ne 0 then oplot, data[w].ofs_az, data[w].ofs_el, psym=4
   legendastro, 'Speed flag', box=0, psym=1, col=70, textcol=70

   ;; Azimuth plot
   plot, time, data.ofs_az, position=pp1_p[1,*], xtitle='time', ytitle='Ofs az.', /noerase
   for i=1, 4 do begin
      wsub = where( data.subscan eq i, nwsub)
      if nwsub ne 0 then oplot, time[wsub], data[wsub].ofs_az, col=ct[i-1]
   endfor
   if nflag ne 0 then oplot, time[w], data[w].ofs_az, psym=4, col=0
   legendastro, "Subscan "+strtrim(indgen(4)+1,2), textcol=ct, box=0
   
   ;; Elevation plot
   plot, time, data.ofs_el, position=pp1_p[2,*], xtitle='time', ytitle='Ofs az.', /noerase
   for i=1, 4 do begin
      wsub = where( data.subscan eq i, nwsub)
      if nwsub ne 0 then oplot, time[wsub], data[wsub].ofs_el, col=ct[i-1]
   endfor
   if nflag ne 0 then oplot, time[w], data[w].ofs_el, psym=4, col=0
   legendastro, "Subscan "+strtrim(indgen(4)+1,2), textcol=ct, box=0

;   endif ;; plotting verbose flag

   ;;------------------------- Profiles plots
   ;;                          ---------------------------------

   ;; coordinates of kids in (az,el) around the center of the scan
   nk_nasmyth2dazdel, param, info, data, kidpar, daz, del
   diff = sqrt( data.ofs_az^2 + data.ofs_el^2)
   junk = min(diff, imin)
   daz = -reform( daz[*, imin], n_elements(kidpar))
   del = -reform( del[*, imin], n_elements(kidpar))
   
   ikid_ref_det = where( kidpar.numdet eq ref_det, nw)
   if nw ne 0 then begin
      ref_det_daz = (daz[ikid_ref_det])[0]
      ref_det_del = (del[ikid_ref_det])[0]
      print, "ref_det_daz, ref_det_del: ", ref_det_daz, ref_det_del
   endif else begin
      ref_det_daz = !values.d_nan
      ref_det_del = !values.d_nan
   endelse

   for iarray=1, 3 do begin
      my_ref_det = !nika.ref_det[iarray-1]

      ikid_ref = where( kidpar.numdet eq my_ref_det, nw)

      if nw eq 0 then begin
         error_message = "ref. kid "+strtrim(ref_det,2)+", not found in the current kidpar."
         message, /info, error_message
         plot, [0,1], [0,1], /nodata, position=pp1_prof[0,*], /noerase
         xyouts, 0.1, 0.4, error_message, /data
      endif else begin

         ;; Loop on coordinates (ic), az or el
         for ic=0, 1 do begin
            ;; Global plot y-range
            w = where( data.subscan eq (2*ic+1) or data.subscan eq (2*ic+2), nw)
            yra = minmax( data[w].toi[ikid_ref])
            yra = [yra[0], yra[1]+0.8*(yra[1]-yra[0])]

            ;; Timelines must be plotted as a function of the pointing of the reference
            ;; kid to avoid confusion on the sign of the correction derived on timelines
            ;; or on the map

            ;; Loop on the subscans (is) of the cross
            gfit_res = dblarr(2,5)
            if iarray eq ref_array then ctscan = [70, 250] else ctscan = [!p.color, !p.color]
            for is=1,2 do begin
               w = where( data.subscan eq (2*ic+is) and data.flag[ikid_ref] eq 0, nw)
               if nw lt 10 then begin
                  error_message = strtrim(nw,2)+" unflagged samples in subscan "+$
                                  strtrim(2*ic+is,2)+" for Numdet "+strtrim(kidpar[ikid_ref].numdet,2)
                  message, /info, error_message
                  if is eq 1  and ic eq 0 then begin
                     plot, [0,1], [0,1], /nodata, position=pp1_prof[ic,*], /noerase
                     xyouts, 0.1, 0.4, error_message, /data, chars=1.5
                     xyouts, 0.1, 0.35, '10 at least are requested.', chars=1.5
                  endif
               endif else begin
                  if ic eq 0 then begin
                     x      = data[w].ofs_az
                     xtitle = 'Azimuth'
                     p      = '!7D!3az'
                     xra = minmax(data.ofs_az)
                  endif else begin
                     x      = data[w].ofs_el
                     xtitle = 'Elevation'
                     p      = '!7D!3el'
                     xra = minmax(data.ofs_el)
                  endelse
                  ;; xra = minmax( x)

                  loadct, 39, /silent

                  if nw lt 10 then begin
                     a1=0
                  endif else begin
                     fit = gaussfit( x, data[w].toi[ikid_ref], a1, nterms=nterms)
                  endelse
                  gfit_res[is-1,*] = a1
                  if is eq 1 then begin
                     plot,  x, data[w].toi[ikid_ref], position=pp_prof[iarray-1,ic,*], $
                            /xs, xra=xra, yra=yra, /ys, xtitle=xtitle, /noerase, col=(iarray eq ref_array)*250
                     oplot, x, data[w].toi[ikid_ref]
                  endif else begin
                     oplot, x, data[w].toi[ikid_ref]
                  endelse
                  oplot, x, a1[3] + a1[4]*x + a1[0]*exp(-(x-a1[1])^2/(2.0d0*a1[2]^2)), col=ctscan[is-1], thick=2
                  fwhm_prof[0,ic,is-1] = a1[2]/!fwhm2sigma
                  if display_antenna_info eq 0 then begin
                     legendastro, [strtrim(param.scan,2), $
                                   '', $
                                   'Focusz: '+string(info.focusz, format = "(F6.2)"), $
                                   'Nas. off. x: '+string(pako_str.nas_offset_x,  format =  "(F6.2)"), $
                                   'Nas. off. y: '+string(pako_str.nas_offset_y,  format =  "(F6.2)"), $
                                   "az offset p2cor: "+string(pako_str.p2cor, format = "(F6.2)"), $
                                   "el offset p7cor: "+string(pako_str.p7cor, format = "(F6.2)"), $
                                   "", $
                                   'Az: '+string(avg(data.az)*!radeg, format = "(F6.2)"), $
                                   "El: "+string(avg(data.el)*!radeg, format = "(F6.2)")], box = 0, /right ;, /trad
                     display_antenna_info = 1
                  endif
                  if is eq 2 then begin
                     legendastro, ["Numdet "+strtrim(kidpar[ikid_ref].numdet,2), $
                                   "", $
                                   p+'= '+num2string(   gfit_res[0,1]), $
                                   'FWHM= '+num2string( gfit_res[0,2]/!fwhm2sigma), $
                                   'Peak= '+num2string( gfit_res[0,0]), $
                                   "", $
                                   p+'= '+num2string(   gfit_res[1,1]), $
                                   'FWHM= '+num2string( gfit_res[1,2]/!fwhm2sigma), $
                                   'Peak= '+num2string( gfit_res[1,0])], box=0, textcol=[0, 0, 70, 70, 70, 0, 250, 250, 250]
                  endif
               endelse
               
            endfor              ; loop on the two az or el subscans

            ;; get results
            if my_ref_det eq ref_det then offsets[ic] = (gfit_res[0,1]+gfit_res[1,1])/2.

         endfor                 ; loop on azel
      endelse                   ; plot profile
   endfor
   
;   endfor
;   stop
endif else begin
   if param.plot_ps ne 1 then wind, 1, 1, /free, /xlarge, title = 'nk_pointing_3', iconic = param.iconic
   my_multiplot, 3, 1, /rev, pp_maps, pp1_maps
endelse
;message, /info, "fix me:"
;endfor

;; Display maps and derive pointing parameters
offsetmap   = dblarr(3,2)
closest_kid = lonarr(3)
wwd = where( data.subscan eq 1)
el_deg_avg = avg( data[wwd].el)*!radeg
grid_tags = tag_names(grid)
info_tags = tag_names(info)
for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if nw1 ne 0 then begin
      case iarray of
         1: input_fwhm = !nika.fwhm_nom[0]
         2: input_fwhm = !nika.fwhm_nom[1]
         3: input_fwhm = !nika.fwhm_nom[0]
      endcase
      
      wmap = where( strupcase(grid_tags) eq "MAP_I"+strtrim(iarray,2), nwmap)
      if nwmap eq 0 then message, "no MAP_I"+strtrim(iarray,2)+" in grid"
      wvar = where( strupcase(grid_tags) eq "MAP_VAR_I"+strtrim(iarray,2), nwvar)
      if nwvar eq 0 then message, "no MAP_VAR_I"+strtrim(iarray,2)+" in grid"
      wnhits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(iarray,2), nwnhits)
      if nwnhits eq 0 then message, "no NHITS_"+strtrim(iarray,2)+" in grid"

      title  = param.scan
      xtitle = 'Azimuth'
      ytitle = 'Elevation'
      !bar.ticklen = 0.005
      !bar.pleg    = 0.01
      if keyword_set(nasmyth) then coltable=3

      xra = [-1,1]*40
      yra = [-1,1]*40

      nk_map_photometry, grid.(wmap), grid.(wvar), grid.(wnhits), grid.xmap, grid.ymap, input_fwhm, $
                         flux, sigma_flux, $
                         sigma_bg, output_fit_par, output_fit_par_error, $
                         bg_rms, flux_center, sigma_flux_center, $
                         info=info, xra=xra, yra=yra, $
                         input_fit_par=input_fit_par, educated=param.educated, xguess=xguess, yguess=yguess, $
                         k_noise=k_noise, noplot=noplot, position=pp1_maps[iarray-1,*], /short_legend, $
                         ;title=title, $
                         xtitle=xtitle, ytitle=ytitle, param=param, $
                         coltable = coltable, chars=0.8, charbar=0.6, /nobar, grid_step=!nika.grid_step[iarray-1]
      nika_title, info, /all

      ellipticity[iarray-1] = output_fit_par[2]/output_fit_par[3]
      loadct, 39, /silent
      legendastro, ["Array "+strtrim(iarray,2), param.source], /right, box = 0, textcol = 255, corners=corners
      dx = grid.xmax - grid.xmin
      dy = grid.ymax - grid.ymin
      oplot,  [(grid.xmin+grid.xmax)/2.],        [grid.ymin]+0.9*dy, psym=7, col=200
      xyouts, [(grid.xmin+grid.xmax)/2.]+0.01*dx, [grid.ymin]+0.9*dy, "Ref. det.", col=200

      loadct, 39, /silent
      if keyword_set(nasmyth) then begin
         legendastro, "NASMYTH MODE", textcol = 255, /right, box = 0
         oplot,  [kidpar[ikid_ref].nas_x], [kidpar[ikid_ref].nas_y], psym = 7, col=250, syms = 1
      endif else begin
         myw = where( kidpar.type eq 1 and kidpar.array eq iarray and $
                      kidpar.x_peak_azel ge min(xra) and $
                      kidpar.x_peak_azel le max(xra) and $
                      kidpar.y_peak_azel ge min(yra) and $
                      kidpar.y_peak_azel le max(yra), nmyw)
         if nmyw ne 0 and keyword_set(show_surrounding_kids) then begin
            oplot, daz[myw], del[myw], psym=7, col=200, syms=0.5
            xyouts, daz[myw], del[myw], strtrim(kidpar[myw].numdet,2), chars=0.8, col=200
         endif
         oplot, [ref_det_daz], [ref_det_del], psym = 7, col=250, syms = 1
         xyouts, [ref_det_daz], [ref_det_del], strtrim(ref_det,2), chars=0.8, col=250
      endelse

      ;; get results
      offsetmap[iarray-1,0] = output_fit_par[4]
      offsetmap[iarray-1,1] = output_fit_par[5]
      case iarray of
         1: begin
            info.result_off_x_1 = output_fit_par[4]
            info.result_off_y_1 = output_fit_par[5]
         end
         2: begin
            info.result_off_x_2 = output_fit_par[4]
            info.result_off_y_2 = output_fit_par[5]
         end
         3: begin
            info.result_off_x_3 = output_fit_par[4]
            info.result_off_y_3 = output_fit_par[5]
         end
      endcase
      
      d = sqrt( (daz-output_fit_par[4])^2 + (del-output_fit_par[5])^2)
      dmin = min( d[w1])
      ikid = where( d eq dmin and kidpar.type eq 1 and kidpar.array eq iarray)
      ikid = ikid[0]            ; just in case...
      closest_kid[iarray-1] = kidpar[ikid].numdet
      ww = where( strupcase(info_tags) eq "RESULT_FWHM_X_"+strtrim(iarray, 2), nww)
      if nww ne 0 then info.(ww) = output_fit_par[2]/!fwhm2sigma
      ww = where( strupcase(info_tags) eq "RESULT_FWHM_Y_"+strtrim(iarray, 2), nww)
      if nww ne 0 then info.(ww) = output_fit_par[3]/!fwhm2sigma
      ww = where( strupcase(info_tags) eq "RESULT_FWHM_"+strtrim(iarray, 2), nww)
      if nww ne 0 then info.(ww) = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma
   endif
endfor
outplot, /close, /verb
my_multiplot, /reset

;; Get useful information for the logbook
nk_get_log_info, param, info, data, log_info
log_info.scan_type = pako_str.obs_type
log_info.source    = pako_str.source
if info.polar ne 0 then  log_info.scan_type = pako_str.obs_type+'_polar'
log_info.ut = info.ut
log_info.az = info.azimuth_deg
log_info.el = info.result_elevation_deg

;;-------------------------------------------------------------------------------------------
;; Print summary
if keyword_set(nasmyth) then begin
   print,  "-----------------------------------------"
   for iarray=1, 3 do begin
      ;;    w =  where(kidpar.numdet eq ref_det[iarray-1], nw)
      w =  where(kidpar.numdet eq ref_det and kidpar.array eq iarray, nw)
      if nw ne 0 then begin
         print, "Nasmyth offset to put the source on the ref det:"
         print, "WARNING, this was not retested during Nika2 run6, maybe neither for Run5... (NP, Dec. 6th):"
         ;; Absolute values that can be passed to PAKO directly
         off_x = string( pako_str.nas_offset_x + (kidpar[w].nas_x-offsetmap[iarray-1, 0]), format="(F7.1)")
         off_y = string( pako_str.nas_offset_y + (kidpar[w].nas_y-offsetmap[iarray-1, 1]), format="(F7.1)")
         print, "offset "+off_x+" "+off_y+" /system nasmyth"
      endif
   endfor
   
   ;; Create a html page with plots from this scan
   save, file=param.plot_dir+"/log_info.save", log_info, info
   nk_logbook_sub, param.scan_num, param.day

   return
endif

fmt = "(F7.1)"

print, "-----------------------------------------------"
print, 'Nas. off. x: '+string(pako_str.nas_offset_x, format="(F6.2)")
print, 'Nas. off. y: '+string(pako_str.nas_offset_y, format="(F6.2)")
print, "az offset p2cor: "+string(pako_str.p2cor, format = "(F6.2)")
print, "el offset p7cor: "+string(pako_str.p7cor, format = "(F6.2)")

print, ""
for iarray=1, 3 do print, "Closest kid to the source (Array "+strtrim(iarray,2)+"): ", closest_kid[iarray-1]


all_ptg_instructions = dblarr(4,2) ; (1 profiles+3 arrays, 2 coorinates (az,el))

print, "-------------------------------------------------------------------"
print, "If A2 profiles cannot be used, then you may try values derived on the maps:"


for iarray=1, 3 do begin
   ptg_az_instruction = -ref_det_daz + offsetmap[iarray-1,0] + pako_str.p2cor
   ptg_el_instruction = -ref_det_del + offsetmap[iarray-1,1] + pako_str.p7cor
   print, "Array "+strtrim(iarray,2)+": set pointing "+$
          string(ptg_az_instruction, format = fmt)+" "+string(ptg_el_instruction, format = fmt)
   log_info.result_name[  2 + 2*(iarray-1)  ] = 'A'+strtrim(iarray,2)+' map az offset'
   log_info.result_value[ 2 + 2*(iarray-1)  ] = ptg_az_instruction
   log_info.result_name[  2 + 2*(iarray-1)+1] = 'A'+strtrim(iarray,2)+' map el offset'
   log_info.result_value[ 2 + 2*(iarray-1)+1] = ptg_el_instruction

   ;; yes, iarray and not (iarray-1) since 0 is taken by the results
   ;; on profiles
   all_ptg_instructions[iarray,0] = ptg_az_instruction
   all_ptg_instructions[iarray,1] = ptg_el_instruction
endfor

;; TO PUT THE SOURCE ON THE REFERENCE DETECTOR
info.ref_det_profile_az_offset = offsets[0]
info.ref_det_profile_el_offset = offsets[1]
ptg_az_instruction = offsets[0] + pako_str.p2cor
ptg_el_instruction = offsets[1] + pako_str.p7cor
print, ""
print, "-------------------------------------------------------------------"
print, "COMMAND TO SEND TO PAKO (IF A2 PROFILES ARE NICE): "
print, "set pointing "+string(ptg_az_instruction, format = fmt)+" "+$
       string(ptg_el_instruction, format = fmt)
print, ""

log_info.result_name[ 0]  = 'ref kid profile az offset'
log_info.result_value[0] = ptg_az_instruction
log_info.result_name[ 1]  = 'ref kid profile el offset'
log_info.result_value[1] = ptg_el_instruction

all_ptg_instructions[0,0] = ptg_az_instruction
all_ptg_instructions[0,1] = ptg_el_instruction


;; Create a html page with plots from this scan
save, file=param.plot_dir+"/log_info.save", log_info, info
nk_logbook_sub, param.scan_num, param.day

;; .csv
nk_info2csv, info, param.plot_dir+"/photometry.csv"

my_multiplot, /reset

end
