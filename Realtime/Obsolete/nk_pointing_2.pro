
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
;-
;================================================================================================

pro nk_pointing_2, scan, pako_str, ptg_az_instruction, ptg_el_instruction, $
                   param=param, info=info, imbfits=imbfits, $
                   online=online, p2cor=p2cor, p7cor=p7cor, nas_offset_x=nas_offset_x, nas_offset_y=nas_offset_y, $
                   RF=RF, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
                   ref_det_1=ref_det_1, ref_det_2=ref_det_2, ref_det_3=ref_det_3, force=force,  obs_type = obs_type, $
                   nasmyth = nasmyth, xml = xml, sn_min = sn_min, sn_max = sn_max, educated = educated, $
                   fwhm_prof=fwhm_prof, outfoc=outfoc, ellipticity=ellipticity, jump_remove=jump_remove, $
                   data=data, kidpar=kidpar, xyguess=xyguess, radius=radius, azelguess=azelguess, grid=grid, $
                   raw_acq_dir=raw_acq_dir, plotting_verbose=plotting_verbose, log_info=log_info


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

;; Init param and info
if not keyword_set(param) then nk_default_param, param
if not keyword_set(info)  then nk_default_info, info
nk_update_param_info,  scan,  param, info, raw_acq_dir=raw_acq_dir
if info.status eq 1 then begin
   message, /info, "info.status is 1 right after update_param_info: exiting"
   return
endif

message, /info, !nika.raw_acq_dir

param.rta = 1
;param.math = "RF"               ; to save time
if keyword_set(one_mm_only)     then param.one_mm_only = 1
if keyword_set(two_mm_only)     then param.two_mm_only = 1
if keyword_set(educated)        then param.educated    = 1
if not keyword_set(ref_det_1) then ref_det_1 = !nika.ref_det[0]
if not keyword_set(ref_det_2) then ref_det_2 = !nika.ref_det[1]
if not keyword_set(ref_det_3) then ref_det_3 = !nika.ref_det[2]
ref_det = [ref_det_1, ref_det_2, ref_det_3]

;; Prepare output directory for plots and logbook
plot_output_dir = !nika.plot_dir+"/Logbook/Scans/"+scan
spawn, "mkdir -p "+plot_output_dir
param.plot_dir = plot_output_dir

param.do_aperture_photometry = 0
param.map_proj = "azel"
if keyword_set(nasmyth) then param.map_proj = "nasmyth"
param.map_xsize = 600
param.map_ysize = 600
nk_init_grid, param, info, grid

;; Retrieve p2cor and p7cor info
if keyword_set(xml) then begin
   info.nasmyth_offset_x = pako_str.nas_offset_x
   info.nasmyth_offset_y = pako_str.nas_offset_y
   info.p2cor = pako_str.p2cor
   info.p7cor = pako_str.p7cor
endif

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

param.source = strtrim( pako_str.source, 2)
info.focusx = pako_str.focusx
info.focusy = pako_str.focusy
info.focusz = pako_str.focusz

outfoc = [info.focusx, info.focusy, info.focusz]

if keyword_set(nasmyth) and (abs(pako_str.p2cor) gt 0.1 or abs(pako_str.p7cor) gt 0.1) then begin
   print, ""
   print, "------------------------------------------"
   print, "Az, el pointing offsets are NOT 0 and 0, so"
   print, "I cannot compute the exact nasmyth offset correction in this context"
   print, "please SET POINTING 0 0 and run another cross"
   print, ""
   return
endif

;;-------------------------------------------------------------------
;; Clean data and project maps
;message, /info, "param.zigzag_correction: "+strtrim(param.zigzag_correction,2)
;stop
nk_scan_preproc, param, info, data, kidpar, grid, xml=xml, sn_min=sn_min, sn_max=sn_max
print, !nika.raw_acq_dir

if param.kid_monitor eq 1 then $
   kid_monitor, scan, data=data, kidpar=kidpar, output_kidpar_dir=!nika.plot_dir+"/KidMonitor"

if keyword_set(jump_remove) then nk_remove_jumps, param, info, data, kidpar

if info.status ne 0 then begin
   message, /info, "Problem during nk_scan_preproc:"
   print, info.error_message
   return
endif

;; Quick fix when /tune
if max(data.subscan) eq 5 then begin
   data = data[ where( data.subscan ge 2)]
   data.subscan -=  1
endif

;; ;;-----------------------
;; message, /info, "fix me:"
;; flag8 = avg( double( data.k_flag eq 8), 0)
;; wcm = where( flag8 eq 0, nwcm)
;; thres = 0.2
;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
;;    if nw1 ne 0 then begin
;;       cm = median( data[wcm].toi[w1], dim=1)
;;       cc = dblarr(nw1)
;;       for i=0, nw1-1 do begin
;;          cc[i] = correlate( cm, data[wcm].toi[w1[i]])
;;       endfor
;;       acc = abs(cc)
;;       w = where( acc lt (median(acc)-stddev(acc)), nw)
;;       if nw ne 0 then kidpar[w1[w]].type = 3
;;    endif
;; endfor
;; stop
;; ;;-----------------------

if not keyword_set(radius) then radius = 50
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

nk_scan_reduce,  param, info, data, kidpar, grid
nk_projection_4, param, info, data, kidpar, grid
param.output_dir = param.project_dir+"/v_"+strtrim(param.version,  2)+"/"+param.scan
param.do_plot = 0 ; to avoid the additional map plot in save_scan_results
nk_save_scan_results_3, param, info, data, kidpar, grid

;;-------------------------------------------------------------------
;; Display results
;box     = ['A', 'B']
;offsets = dblarr(2,2)
offsets = dblarr(3,2) ; 3 arrays for nika2, 2 offsets
nterms = 5
display_info = 0

outplot, file=plot_output_dir+"/plot_"+strtrim(param.scan), png = param.plot_png, ps = param.plot_ps

;;=======================================================================================================
;;=============================== Cross or Lissajous scan =================================================
;;=======================================================================================================
if strupcase( strtrim( pako_str.obs_type, 2)) eq "POINTING" then cross_scan = 1 else cross_scan = 0

fwhm_prof = dblarr(3,2,2)
ellipticity = dblarr(3)

if cross_scan eq 1 then begin
   wind, 1, 1, /free, xs=1500, ys=700, title = 'nk_pointing_2', iconic = param.iconic
   
   ;; Init display parameters
   azel_field = ['az', 'el']
   ;; az,el section
   x1_azel = 0.05
   x2_azel = 0.2
   y1_azel = 0.02
   y2_azel = 0.98

   ;; Profiles section
   x1_prof = x2_azel+0.05
   x2_prof = 0.7
   y1_prof = y1_azel
   y2_prof = y2_azel
   
   ;; Maps section
   x1_maps = x2_prof + 0.03
   x2_maps = 0.99
   y1_maps = y1_azel
   y2_maps = y2_azel

   ;; pointing plots location
   my_multiplot, 1, 3, pp_p, pp1_p, /rev, $
                 xmin=x1_azel, ymin=y1_azel, xmax=x2_azel,  $
                 xmargin=1d-10, ymargin=0.01, ymax=y2_azel

;;    ;; profiles plots location
;;    my_multiplot, 2, 3, pp_prof, pp1_prof, /rev, $
;;                  xmin=x1_prof, ymin=y1_prof, xmax=x2_prof,  $
;;                  xmargin=1d-10, ymargin=0.01, ymax=y2_prof, /full, /dry
   ;; profiles plots location
   my_multiplot, 2, 3, pp_prof, pp1_prof, /rev, $
                 xmin=x1_prof, ymin=y1_prof, xmax=x2_prof,  $
                 xmargin=1d-10, ymargin=0.01, ymax=y2_prof, gap_x=1d-10, gap_y=0.05, /dry

   ;; Maps location
   my_multiplot, 1, 3, pp_maps, pp1_maps, /rev, $
                 xmin=x1_maps, ymin=y1_maps, xmax=x2_maps,  $
                 xmargin=1d-10, ymargin=0.01, ymax=y2_maps, /full, /dry

   ;;------------------------- pointing plots ---------------------------------

   ;; Speed flags: 11
   w    = nk_where_flag( data.flag[0], 11, nflag=nflag)
   time = data.a_t_utc-data[0].a_t_utc 

   if keyword_set(plotting_verbose) then begin

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

endif ;; plotting verbose flag
   ;;------------------------- Profiles plots ---------------------------------

   for iarray=1, 3 do begin
      plot_profile = 1          ; init
      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
      if nw1 ne 0 then begin
         
         ;; Check the choice of the reference kids
         ikid_ref = (where( kidpar.numdet eq ref_det[iarray-1], nw))[0]
         if nw eq 0 then begin
            message, "could not find "+strtrim( ref_det[iarray-1], 2)+" in kidpar"
            plot_profile = 0
         endif

         if plot_profile eq 1 then begin

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
               ctscan = [70, 250]
               for is=1,2 do begin
                  w = where( data.subscan eq (2*ic+is) and data.flag[ikid_ref] eq 0, nw)
                  nk_nasmyth2dazdel, param, info, data[w],  kidpar,  daz,  del
                  daz = reform(daz[ikid_ref, *])
                  del = reform(del[ikid_ref, *])

                  if ic eq 0 then begin
                     x      = data[w].ofs_az - daz
                     xtitle = 'Azimuth'
                     p      = '!7D!3az'
                  endif else begin
                     x      = data[w].ofs_el - del
                     xtitle = 'Elevation'
                     p      = '!7D!3el'
                  endelse
                  xra = minmax( x)

                  loadct, 39, /silent
                  if n_elements( x) gt 10 then begin
                     fit = gaussfit( x, data[w].toi[ikid_ref], a1, nterms=nterms)
                     gfit_res[is-1,*] = a1
                     if is eq 1 then begin
                        plot,  x, data[w].toi[ikid_ref], position=pp_prof[ic,iarray-1,*], $
                               /xs, xra=xra, yra=yra, /ys, xtitle=xtitle, /noerase
                     endif else begin
                        oplot, x, data[w].toi[ikid_ref]
                     endelse
                     oplot, x, a1[3] + a1[4]*x + a1[0]*exp(-(x-a1[1])^2/(2.0d0*a1[2]^2)), col=ctscan[is-1], thick=2
                     fwhm_prof[iarray-1,ic,is-1] = a1[2]/!fwhm2sigma
                     if display_info eq 0 then begin
                        legendastro, ['Focusz: '+string(info.focusz, format = "(F6.2)"), $
                                      'Nas. off. x: '+string(pako_str.nas_offset_x,  format =  "(F6.2)"), $
                                      'Nas. off. y: '+string(pako_str.nas_offset_y,  format =  "(F6.2)"), $
                                      "az offset p2cor: "+string(pako_str.p2cor, format = "(F6.2)"), $
                                      "el offset p7cor: "+string(pako_str.p7cor, format = "(F6.2)"), $
                                      "", $
                                      'Az: '+string(avg(data.az)*!radeg, format = "(F6.2)"), $
                                      "El: "+string(avg(data.el)*!radeg, format = "(F6.2)")], box = 0, /right
                        display_info = 1
                     endif
                     if is eq 2 then begin
                        legendastro, ["Array "+strtrim(iarray,2)+", Numdet "+strtrim(kidpar[ikid_ref].numdet,2), $
                                      "", $
                                      p+'= '+num2string(   gfit_res[0,1]), $
                                      'FWHM= '+num2string( gfit_res[0,2]/!fwhm2sigma), $
                                      'Peak= '+num2string( gfit_res[0,0]), $
                                      "", $
                                      p+'= '+num2string(   gfit_res[1,1]), $
                                      'FWHM= '+num2string( gfit_res[1,2]/!fwhm2sigma), $
                                      'Peak= '+num2string( gfit_res[1,0])], box=0, textcol=[0, 0, 70, 70, 70, 0, 250, 250, 250]
                     endif

                  endif
                  
               endfor           ; loop on the two az or el subscans
            
               ;; get results
               offsets[iarray-1,ic] = (gfit_res[0,1]+gfit_res[1,1])/2.
            endfor              ; loop on azel
         endif                  ; plot profile
      endif                     ; array is present
   endfor                       ; loop on arrays

endif else begin

   wind, 1, 1, /free, /xlarge, title = 'nk_pointing_2', iconic = param.iconic
   my_multiplot, 3, 1, /rev, pp_maps, pp1_maps
   
endelse

;; Display maps and derive pointing parameters
offsetmap   = dblarr(3,2)
ref_det_daz = dblarr(3)
ref_det_del = dblarr(3)
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
      nk_map_photometry, grid.(wmap), grid.(wvar), grid.(wnhits), grid.xmap, grid.ymap, input_fwhm, $
                         flux, sigma_flux, $
                         sigma_bg, output_fit_par, output_fit_par_error, $
                         bg_rms, flux_center, sigma_flux_center, $
                         map_conv=map_conv, info=info, $
                         input_fit_par=input_fit_par, educated=param.educated, xguess=xguess, yguess=yguess, $
                         k_noise=k_noise, noplot=noplot, position=pp1_maps[iarray-1,*], /short_legend, $
                         title=title, xtitle=xtitle, ytitle=ytitle, param=param, coltable = coltable, chars=0.8, charbar=0.6, /nobar

      ellipticity[iarray-1] = output_fit_par[2]/output_fit_par[3]
      loadct, 39, /silent
      legendastro, ["Array "+strtrim(iarray,2), param.source], /right, box = 0, textcol = 255, corners=corners
      dx = grid.xmax - grid.xmin
      dy = grid.ymax - grid.ymin
      oplot,  [(grid.xmin+grid.xmax)/2.],        [grid.ymin]+0.9*dy, psym=1, col=200
      xyouts, [(grid.xmin+grid.xmax)/2.]+0.01*dx, [grid.ymin]+0.9*dy, "Ref. det.", col=200

      ;; Compute (az,el) coordinates of the reference pixel
      nk_nasmyth2dazdel, param, info, data, kidpar, daz, del
      wkid_ref = where(kidpar.numdet eq ref_det[iarray-1])

      ;; Determine the position of the reference kid in azel when the cross
      ;; is centered ( ie diff ~= 0)
      diff = sqrt( data.ofs_az^2 + data.ofs_el^2)
      junk = min(diff, imin)
      daz = daz[*, imin]
      del = del[*, imin]
      ref_det_daz[iarray-1] = daz[wkid_ref]
      ref_det_del[iarray-1] = del[wkid_ref]
      loadct, 39, /silent
      if keyword_set(nasmyth) then begin
         legendastro, "NASMYTH MODE", textcol = 255, /right, box = 0
         oplot,  [kidpar[wkid_ref].nas_x], [kidpar[wkid_ref].nas_y], psym = 1, col=200, syms = 2
      endif else begin
         ;; oplot,  [ref_det_daz[iarray-1]], [ref_det_del[iarray-1]], psym = 1, col=200, syms = 2
         oplot, -[ref_det_daz[iarray-1]], -[ref_det_del[iarray-1]], psym = 1, col=200, syms = 2
      endelse

;;      if lambda eq 1 then begin
;;         daz_ref_1mm = daz[w]
;;         del_ref_1mm = del[w]
;;      endif else begin
;;         daz_ref_2mm = daz[w]
;;         del_ref_2mm = del[w]
;;      endelse
      
      ;; get result
      offsetmap[iarray-1,0] = output_fit_par[4]
      offsetmap[iarray-1,1] = output_fit_par[5]
    
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
outplot, /close
my_multiplot, /reset


;; Get useful information for the logbook
 nika_get_log_info, param.scan_num, param.day, data, log_info, kidpar=kidpar
;;nk_get_log_info, param, info, data, log_info
log_info.scan_type = pako_str.obs_type
log_info.source    = pako_str.source
if info.polar ne 0 then  log_info.scan_type = pako_str.obs_type+'_polar'

;;-------------------------------------------------------------------------------------------
;; Print summary
if keyword_set(nasmyth) then begin
   print,  "-----------------------------------------"
   for iarray=1, 3 do begin
      w =  where(kidpar.numdet eq ref_det[iarray-1], nw)
      if nw ne 0 then begin
         print, "Nasmyth offset to put the source on the ref det A1:"
         ;; Absolute values that can be passed to PAKO directly
         off_x = string( pako_str.nas_offset_x + (kidpar[w].nas_x-offsetmap[iarray-1, 0]), format="(F7.1)")
         off_y = string( pako_str.nas_offset_y + (kidpar[w].nas_y-offsetmap[iarray-1, 1]), format="(F7.1)")
         print, "offset "+off_x+" "+off_y+" /system nasmyth"
      endif
   endfor
   
   ;; Create a html page with plots from this scan
   save, file=plot_output_dir+"/log_info.save", log_info
   nk_logbook_sub, param.scan_num, param.day

   ;; Update logbook
   nk_logbook, param.day
   return
endif

fmt = "(F5.1)"

print, "-----------------------------------------------"
print, 'Nas. off. x: '+string(pako_str.nas_offset_x, format="(F6.2)")
print, 'Nas. off. y: '+string(pako_str.nas_offset_y, format="(F6.2)")
print, "az offset p2cor: "+string(pako_str.p2cor, format = "(F6.2)")
print, "el offset p7cor: "+string(pako_str.p7cor, format = "(F6.2)")

print, ""
print, "-------------------------------------------------------------------"
print, "Reference detectors arras 1, 2, 3: "+strtrim(ref_det[0],2)+", "+strtrim(ref_det[1],2)+", "+strtrim(ref_det[2],2)
print, ""
for iarray=1, 3 do print, "Closest kid to the source (Array "+strtrim(iarray,2)+"): ", closest_kid[iarray-1]

print, "-------------------------------------------------------------------"
print, "To put the source on the ref. detector:"
for iarray=1, 3 do begin
;;   if param.new_ptg_conv eq 0 then begin
;;      ptg_az_instruction = ref_det_daz[iarray-1] - offsetmap[iarray-1,0] + pako_str.p2cor
;;      ptg_el_instruction = ref_det_del[iarray-1] - offsetmap[iarray-1,1] + pako_str.p7cor
;;   endif else begin
      ptg_az_instruction = ref_det_daz[iarray-1] + offsetmap[iarray-1,0] + pako_str.p2cor
      ptg_el_instruction = ref_det_del[iarray-1] + offsetmap[iarray-1,1] + pako_str.p7cor
;;   endelse
   print, "Array "+strtrim(iarray,2)+": set pointing "+$
          string(ptg_az_instruction, format = fmt)+" "+string(ptg_el_instruction, format = fmt)

   
   ;; message, /info, "fix me:"
   ;; print, ref_det_daz[iarray-1], offsetmap[iarray-1,0], pako_str.p2cor
   ;; print, ref_det_del[iarray-1], offsetmap[iarray-1,1], pako_str.p7cor
   ;; stop   

   log_info.result_name[  2*(iarray-1)  ] = 'az offset'
   log_info.result_value[ 2*(iarray-1)  ] = ptg_az_instruction
   log_info.result_name[  2*(iarray-1)+1] = 'el offset'
   log_info.result_value[ 2*(iarray-1)+1] = ptg_el_instruction
endfor

for iarray=1, 3 do begin
   print, "Ellipticity (fwhm_x/fwhm_y) A"+strtrim(iarray,2)+": "+strtrim(ellipticity[iarray-1],2)
endfor

;; Create a html page with plots from this scan
save, file=plot_output_dir+"/log_info.save", log_info
nk_logbook_sub, param.scan_num, param.day

;; Update logbook
nk_logbook, param.day

;; .csv
nk_info2csv, info, plot_output_dir+"/photometry.csv"

my_multiplot, /reset

end
