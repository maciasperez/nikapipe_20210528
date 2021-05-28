
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
;        - June 2nd, 2014: Nicolas Ponthieu
;-
;================================================================================================

pro nk_pointing, scan, pako_str, $
                 param=param, info=info, imbfits=imbfits, $
                 online=online, p2cor=p2cor, p7cor=p7cor, nas_offset_x=nas_offset_x, nas_offset_y=nas_offset_y, $
                 RF=RF, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
                 ref_det_1mm=ref_det_1mm, ref_det_2mm=ref_det_2mm, force=force,  obs_type = obs_type, $
                 nasmyth = nasmyth, xml = xml, sn_min = sn_min, sn_max = sn_max, educated = educated


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_pointing, scan, pako_str, $"
   print, "             param=param, info=info, imbfits=imbfits, $"
   print, "             online=online, p2cor=p2cor, p7cor=p7cor, nas_offset_x=nas_offset_x, nas_offset_y=nas_offset_y, $"
   print, "             RF=RF, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $"
   print, "             ref_det_1mm=ref_det_1mm, ref_det_2mm=ref_det_2mm, force=force"
   return
endif

;; Init param and info
if not keyword_set(param) then nk_default_param, param
if not keyword_set(info)  then nk_default_info, info
;nk_update_scan_param, scan, param, info
nk_update_param_info,  scan,  param, info
nk_init_grid, param, grid

param.rta = 1

;; Create mask_source in case it's needed by param.decor_method
;param.decor_method  = "COMMON_MODE_KIDS_OUT"
dist = sqrt( grid.xmap^2 + grid.ymap^2)
w = where( dist lt param.decor_cm_dmin, nw)
if nw ne 0 then grid.mask_source[w] = 0.d0

;; Work in (az,el) to derive offsets
param.map_proj = "azel"
if keyword_set(nasmyth) then begin
   param.map_proj = "nasmyth"
   coltable = 3
endif

;;!;; if not keyword_set(common_mode_radius) then common_mode_radius = 40.
if keyword_set(RF)              then param.math        = "RF"
if keyword_set(one_mm_only)     then param.one_mm_only = 1
if keyword_set(two_mm_only)     then param.two_mm_only = 1
if keyword_set(educated)        then param.educated    = 1
if not keyword_set(ref_det_1mm) then ref_det_1mm       = !nika.numdet_ref_1mm
if not keyword_set(ref_det_2mm) then ref_det_2mm       = !nika.numdet_ref_2mm

;; Prepare output directory for plots and logbook
plot_output_dir = !nika.plot_dir+"/Scans/"+scan
spawn, "mkdir -p "+plot_output_dir
param.plot_dir = plot_output_dir

;;--------------------------------------------------------------
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
;;nk, scan, param=param, info=info, data=data, kidpar=kidpar
;param.do_plot=0
nk_scan_preproc, param, info, data, kidpar, xml = xml
if not keyword_Set(sn_min) then sn_min = 0
if not keyword_set(sn_max) then sn_max = n_elements(data)-1
if sn_min ne 0 or sn_max ne (n_elements(data)-1) then data =  data[sn_min:sn_max]

;; Quick fix when /tune
if max(data.subscan) eq 5 then begin
   data = data[ where( data.subscan ge 2)]
   data.subscan -=  1
endif
nk_scan_reduce,  param, info, data, kidpar, grid
nk_projection_3, param, info, data, kidpar, grid
param.output_dir = param.project_dir+"/v_"+strtrim(param.version,  2)+"/"+param.scan
param.do_plot = 0 ; to avoid the additional map plot in save_scan_results
;nk_save_scan_results, param, info, grid, kidpar
nk_save_scan_results_2, param, info, grid, kidpar

;pcor_az = pako_str.p2cor
;pcor_el = pako_str.p7cor

param.source = strtrim( pako_str.source, 2)

info.focusx = pako_str.focusx
info.focusy = pako_str.focusy
info.focusz = pako_str.focusz

;; Display results
box     = ['A', 'B']
offsets = dblarr(2,2)
nterms = 5
outplot, file=plot_output_dir+"/plot_"+strtrim(param.scan), png = param.plot_png, ps = param.plot_ps

display_info = 0
if strupcase( strtrim( pako_str.obs_type, 2)) eq "POINTING" then begin
   wind, 1, 1, /free, xs=1500, ys=900, title = 'nk_pointing'

   my_multiplot, 1, 3, xmin = 0.01, xmax = 0.15, junk, ppn, /rev
   my_multiplot, 3, 2, /rev, pp, pp1, xmin = 0.15, xmax = 0.9, gap_x = 0.05

   wspeed = nika_pipe_wflag( data.flag[0], 11, nflag=nwspeed)
   plot, data.ofs_az, data.ofs_el, position=ppn[0,*], /nodata
   oplot, data.ofs_az, data.ofs_el, col=70
   if nwspeed ne 0 then oplot, [data[wspeed].ofs_az], [data[wspeed].ofs_el], psym=4, col=0
   legendastro, 'Anomalous speed flag', psym=4, col=0, box=0

   plot, data.ofs_az, position=ppn[1,*], /noerase, ytitle='ofs_az'
   ct = [70, 150, 200, 250]
   for ii=1, 4 do begin
      w = where( data.subscan eq ii, nw)
      if nw eq 0 then message, /info, "No subscan "+strtrim(ii,2)+" in the data ?!" else $
         oplot, w, data[w].ofs_az, col=ct[ii-1], psym=3
   endfor
   if nwspeed ne 0 then oplot, [wspeed], [data[wspeed].ofs_az], psym=1
   legendastro, 'OFS_AZ', /right, box=0
   legendastro, "Subscan "+strtrim(indgen(4)+1,2), textcol=ct, box=0

   plot, data.ofs_el, position=ppn[2,*], /noerase, ytitle='ofs_el'
   for ii=1, 4 do begin
      w = where( data.subscan eq ii, nw)
      if nw eq 0 then message, /info, "No subscan "+strtrim(ii,2)+" in the data ?!" else $
         oplot, w, data[w].ofs_el, col=ct[ii-1], psym=3
   endfor
   if nwspeed ne 0 then oplot, [wspeed], [data[wspeed].ofs_el], psym=1
   legendastro, 'OFS_EL', /right, box=0
   legendastro, "Subscan "+strtrim(indgen(4)+1,2), textcol=ct, box=0

   ;;--------------------------------------------------------------------
   ;; profiles and maps
   for lambda=1, 2 do begin

      nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
      if nw1 ne 0 then begin
         if lambda eq 1 then ref_det = ref_det_1mm else ref_det = ref_det_2mm
         
         ;; Check the choice of the reference kids
         ikid_ref = (where( kidpar.numdet eq ref_det, nw))[0]
         if nw eq 0 then message, "could not find "+strtrim( ref_det, 2)+" in kidpar"
         if kidpar[ikid_ref].type ne 1 and not keyword_set(force) then begin
            message, /info, ""
            message, /info, "Ref. kid has type /= 1 ?!"
            return
         endif

         ;; Azimuth / elevation subscans
         for i=0, 1 do begin
            ;; find global plot range
            w = where( data.subscan eq (2*i+1) or data.subscan eq (2*i+2), nw)
            yra = minmax( data[w].toi[ikid_ref])
            yra = [yra[0], yra[1]+0.8*(yra[1]-yra[0])]

            ;; Timelines must be plotted as a function of the pointing of the reference
            ;; kid to avoid confusion on the sign of the correction derived on timelines
            ;; or on the map

            ;; 1st scan
            w = where( data.subscan eq (2*i+1) and data.flag[ikid_ref] eq 0, nw)
            ;nika_nasmyth2azel, kidpar[ikid_ref].nas_x, kidpar[ikid_ref].nas_y, $
            ;                   0.0, 0.0, data[w].el*!radeg, daz, del, $
            ;                   nas_x_ref=kidpar[ikid_ref].nas_center_X, nas_y_ref=kidpar[ikid_ref].nas_center_Y

            nk_nasmyth2dazdel,  param,  info,  data,  kidpar,  daz,  del,  daz1,  del1
            wref = where(kidpar.numdet eq ref_det)
            daz = reform(daz[wref, *])
            del = reform(del[wref, *])

            if i eq 0 then begin
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
            fit = gaussfit( x, data[w].toi[ikid_ref], a1, nterms=nterms)
            plot,  x, data[w].toi[ikid_ref], position=pp[i,lambda-1,*], $
                   /xs, xra=xra, yra=yra, /ys, xtitle=xtitle, /noerase
            oplot, x, a1[3] + a1[4]*x + a1[0]*exp(-(x-a1[1])^2/(2.0d0*a1[2]^2)), col=70, thick=2
            if display_info eq 0 then begin
               legendastro, ['Focusz: '+string(info.focusz, format = "(F6.2)"), $
                             ;;'Nas. off. x: '+string(info.nasmyth_offset_x,  format =  "(F6.2)"), $
                             ;;'Nas. off. y: '+string(info.nasmyth_offset_y,  format =  "(F6.2)"), $
                             ;;"az offset p2cor: "+string(info.p2cor, format = "(F6.2)"), $
                             ;;"el offset p7cor: "+string(info.p7cor, format = "(F6.2)"), $
                             'Nas. off. x: '+string(pako_str.nas_offset_x,  format =  "(F6.2)"), $
                             'Nas. off. y: '+string(pako_str.nas_offset_y,  format =  "(F6.2)"), $
                             "az offset p2cor: "+string(pako_str.p2cor, format = "(F6.2)"), $
                             "el offset p7cor: "+string(pako_str.p7cor, format = "(F6.2)"), $
                             "", $
                             'Az: '+string(avg(data.az)*!radeg, format = "(F6.2)"), $
                             "El: "+string(avg(data.el)*!radeg, format = "(F6.2)")], box = 0, /right
               display_info = 1
            endif

            ;; 2nd scan
            w = where( data.subscan eq (2*i+2) and data.flag[ikid_ref] eq 0, nw)
            ;nika_nasmyth2azel, kidpar[ikid_ref].nas_x, kidpar[ikid_ref].nas_y, $
            ;                   0.0, 0.0, data[w].el*!radeg, daz, del, $
            ;                   nas_x_ref=kidpar[ikid_ref].nas_center_X, nas_y_ref=kidpar[ikid_ref].nas_center_Y

            nk_nasmyth2dazdel,  param,  info,  data,  kidpar,  daz,  del,  daz1,  del1
            wref = where(kidpar.numdet eq ref_det)
            daz = reform(daz[wref, *])
            del = reform(del[wref, *])


            if i eq 0 then x = data[w].ofs_az - daz else x = data[w].ofs_el - del
            fit = gaussfit( x, data[w].toi[ikid_ref], a2, nterms=nterms)
            oplot, x, data[w].toi[ikid_ref]
            oplot, x, a2[3] + a2[4]*x + a2[0]*exp(-(x-a2[1])^2/(2.0d0*a2[2]^2)), col=250, thick=2
            legendastro, [strtrim(lambda,2)+"mm, Numdet "+strtrim(kidpar[ikid_ref].numdet,2), $
                          "", $
                          p+'= '+num2string(a1[1]), $
                          'FWHM= '+num2string(a1[2]/!fwhm2sigma), $
                          'Peak= '+num2string(a1[0]), $
                          "", $
                          p+'= '+num2string(a2[1]), $
                          'FWHM= '+num2string(a2[2]/!fwhm2sigma), $
                          'Peak= '+num2string(a2[0])], box=0, textcol=[0, 0, 70, 70, 70, 0, 250, 250, 250]
            
            ;; get result
            offsets[lambda-1,i] = (a1[1]+a2[1])/2.
         endfor
      endif

   endfor
endif else begin
   my_multiplot, 3, 2, /rev, pp, pp1, xmin = 0.15, xmax = 0.9, gap_x = 0.05
   wind, 1, 1, /free, /xlarge, title = 'nk_pointing'
   my_multiplot, 2, 1, /rev, pp_new, pp1_new
   pp[2,*,*] = pp_new
endelse

;; Display maps and derive pointing parameters
offsetmap   = dblarr(2,2)
closest_kid = lonarr(2)
wwd = where( data.subscan eq 1)
el_deg_avg = avg( data[wwd].el)*!radeg
daz_ref_1mm = 0.d0
del_ref_1mm = 0.d0
daz_ref_2mm = 0.d0
del_ref_2mm = 0.d0
for lambda=1, 2 do begin
   if param.two_mm_only ne 0 and lambda eq 1 then goto, ciao
   if param.one_mm_only ne 0 and lambda eq 2 then goto, ciao
   nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1

   if lambda eq 1 then ref_det = ref_det_1mm else ref_det = ref_det_2mm
   if nw1 ne 0 then begin

      if lambda eq 1 then begin
         map     = grid.map_i_1mm
         map_var = grid.map_i_1mm*0.d0
         w = where( grid.map_w8_1mm ne 0, nw)
         if nw eq 0 then message, "No valid pixel"
         map_var[w] = 1.d0/grid.map_w8_1mm[w]
         nhits   = grid.nhits_1mm
         input_fwhm = !nika.fwhm_nom[0]
      endif else begin
         map     = grid.map_i_2mm
         map_var = grid.map_i_1mm*0.d0
         w = where( grid.map_w8_2mm ne 0, nw)
         if nw eq 0 then message, "No valid pixel"
         map_var[w] = 1.d0/grid.map_w8_2mm[w]
;         map_var = info.map_var_2mm
         nhits   = grid.nhits_2mm
         input_fwhm = !nika.fwhm_nom[1]
      endelse
      
      ;title  = param.source+" "+param.scan+" "+strtrim(lambda,2)+'mm'
      title  = param.scan
      xtitle = 'Azimuth'
      ytitle = 'Elevation'

      nk_map_photometry, map, map_var, nhits, grid.xmap, grid.ymap, input_fwhm, $
                         flux, sigma_flux, $
                         sigma_bg, output_fit_par, output_fit_par_error, $
                         bg_rms, flux_center, sigma_flux_center, $
                         map_conv=map_conv, $
                         input_fit_par=input_fit_par, educated=param.educated, $
                         k_noise=k_noise, noplot=noplot, position=pp[2,lambda-1,*], $
                         title=title, xtitle=xtitle, ytitle=ytitle, param=param, coltable = coltable
      legendastro, [strtrim(lambda, 2)+" mm", param.source], /right, box = 0, textcol = 255

      nk_nasmyth2dazdel,  param,  info,  data,  kidpar,  daz,  del,  daz1,  del1
      w = where(kidpar.numdet eq ref_det)
      nsn = n_elements(data)
      ;diff = abs( data.el-avg(data.el))
      diff = sqrt( data.ofs_az^2 + data.ofs_el^2)
      junk = min(diff, imin)
      daz = daz[*, imin]
      del = del[*, imin]
      loadct, 39, /silent
      if keyword_set(nasmyth) then begin
         legendastro, "NASMYTH MODE", textcol = 255, /right, box = 0
         oplot,  [kidpar[w].nas_x], [kidpar[w].nas_y], psym = 1, col = 250, syms = 2
      endif else begin
         oplot,  [daz[w]], [del[w]], psym = 1, col = 250, syms = 2
      endelse
      if lambda eq 1 then begin
         daz_ref_1mm = daz[w]
         del_ref_1mm = del[w]
      endif else begin
         daz_ref_2mm = daz[w]
         del_ref_2mm = del[w]
      endelse
      
      ;; get result
      offsetmap[lambda-1,0] = output_fit_par[4]
      offsetmap[lambda-1,1] = output_fit_par[5]
    
      d = sqrt( (daz-output_fit_par[4])^2 + (del-output_fit_par[5])^2)
      dmin = min( d[w1])
      ikid = where( d eq dmin and kidpar.type eq 1 and kidpar.array eq lambda)
      ikid = ikid[0]            ; just in case...
      closest_kid[lambda-1] = kidpar[ikid].numdet
   endif
ciao:
endfor
outplot, /close
my_multiplot, /reset

param1 = param
info1 = info
kidpar1 = kidpar
grid1 = grid
save, file=param.output_dir+'/results.save', param1, info1, kidpar1, grid1

;; Get useful information for the logbook
nika_get_log_info, param.scan_num, param.day, data, log_info, kidpar=kidpar
log_info.scan_type = pako_str.obs_type
log_info.source    = pako_str.source
;; if keyword_set(polar) then log_info.scan_type = pako_str.obs_type+'_polar'

;;-------------------------------------------------------------------------------------------
;; Print summary
if keyword_set(nasmyth) then begin
   print,  "-----------------------------------------"
   print, "Nasmyth offset to put the source on the ref det:"
   print,  '1mm:'
   w =  where(kidpar.numdet eq ref_det_1mm)
   ;; Absolute values that can be passed to PAKO directly
   off_x = string( pako_str.nas_offset_x + (kidpar[w].nas_x-offsetmap[0, 0]), format="(F7.1)")
   off_y = string( pako_str.nas_offset_y + (kidpar[w].nas_y-offsetmap[0, 1]), format="(F7.1)")
   print, "offset "+off_x+" "+off_y+" /system nasmyth"
   
   print,  '2mm:'
   w =  where(kidpar.numdet eq ref_det_2mm)
   ;; Absolute values that can be passed to PAKO directly
   off_x = string( pako_str.nas_offset_x + (kidpar[w].nas_x-offsetmap[1, 0]), format="(F7.1)")
   off_y = string( pako_str.nas_offset_y + (kidpar[w].nas_y-offsetmap[1, 1]), format="(F7.1)")
   print, "offset "+off_x+" "+off_y+" /system nasmyth"
   return
endif

;; print, ""
;; print, "*****************************"
;; print, " POINTING results"
;; for lambda=1, 2 do begin
;;    print, box[lambda-1]+" "+strtrim(lambda,2)+"mm, Delta az = "+$
;;           string( offsets[lambda-1,0],format='(F10.1)')+$
;;           ", Delta el = "+string( offsets[lambda-1,1],format='(F10.1)')
;; endfor


wref1 = where(kidpar.numdet eq ref_det_1mm, nwref1)
wref2 = where(kidpar.numdet eq ref_det_2mm, nwref2)
wc1 = where(kidpar.numdet eq closest_kid[0], nwc1)
wc2 = where(kidpar.numdet eq closest_kid[1], nwc2)
if nwref1 ne 0 then begin
   delta_nas_x1 = kidpar[wref1].nas_x - kidpar[wc2].nas_x ;- info.nasmyth_offset_x
   delta_nas_y1 = kidpar[wref1].nas_y - kidpar[wc2].nas_y ;- info.nasmyth_offset_y
endif else begin
   delta_nas_x1 = !values.d_nan
   delta_nas_y1 = !values.d_nan
endelse
if nwref2 ne 0 then begin
   delta_nas_x2 = kidpar[wref2].nas_x - kidpar[wc2].nas_x ;- info.nasmyth_offset_x
   delta_nas_y2 = kidpar[wref2].nas_y - kidpar[wc2].nas_y ;- info.nasmyth_offset_y
endif else begin
   delta_nas_x2 = !values.d_nan
   delta_nas_y2 = !values.d_nan
endelse


print, ""
print, "-------------------------------------------------------------------"
print, "Reference detectors (1mm, 2mm): "+strtrim(ref_det_1mm,2)+", "+strtrim(ref_det_2mm,2)
print, "Closest kid to the source (1mm): ", closest_kid[0]
print, "Closest kid to the source (2mm): ", closest_kid[1]
;fmt = "(F6.2)"
;;print, "-------------------------------------------------------------------"
;;if finite(delta_nas_x1) then print, "nasmyth correction to center on ref. kid "+$
;;                                    strtrim(ref_det_1mm, 2)+": offset "+string(delta_nas_x1, format = fmt)+" "+$
;;                                    string( delta_nas_y1, format = fmt)+" /system nasmyth"
;;if finite(delta_nas_x2) then print, "nasmyth correction to center on ref. kid "+$
;;                                    strtrim(ref_det_2mm, 2)+": offset "+string(delta_nas_x2, format = fmt)+" "+$
;;                                    string( delta_nas_y2, format = fmt)+" /system nasmyth"

print, "-------------------------------------------------------------------"
print, "To put the source on the ref. detector (TBC)"
print, '1mm:'
;print, "az_ref - offsetmap: ", daz_ref_1mm - offsetmap[0, 0]
;print, "el_ref - offsetmap: ", del_ref_1mm - offsetmap[0, 1]
fmt = "(F5.1)"
ptg_az_instruction = daz_ref_1mm - offsetmap[0,0] + pako_str.p2cor
ptg_el_instruction = del_ref_1mm - offsetmap[0,1] + pako_str.p7cor
print, "set pointing "+string(ptg_az_instruction, format = fmt)+" "+string(ptg_el_instruction, format = fmt)

print, '2mm:'
;print, "az_ref - offsetmap: ", daz_ref_2mm - offsetmap[1, 0]
;print, "el_ref - offsetmap: ", del_ref_2mm - offsetmap[1, 1]
ptg_az_instruction = daz_ref_2mm - offsetmap[1,0] + pako_str.p2cor
ptg_el_instruction = del_ref_2mm - offsetmap[1,1] + pako_str.p7cor
print, "set pointing "+string(ptg_az_instruction, format = fmt)+" "+string(ptg_el_instruction, format = fmt)
print, ""

;; print, "-------------------------------------------------------"
;; print,  "POINTING CORRECTIONS"
;; ;; Don't forget to switch the sign of offset map to have consistent instructions here
;; p=0
;; for lambda=1, 2 do begin
;;    cmd = "SET POINTING "+strtrim( string(-offsetmap[lambda-1, 0]+pako_str.p2cor,format="(F5.1)"),2)+$
;;          " "+strtrim( string(-offsetmap[lambda-1, 1]+pako_str.p7cor,format="(F5.1)"),2)
;; 
;;    print, box[lambda-1]+" "+strtrim(lambda,2)+ $ 
;;           "mm, : (MAP) (for PAKO): SET POINTING ", string(-offsetmap[lambda-1, 0]+pako_str.p2cor,format='(F10.1)'), ", ",  $
;;           string(-offsetmap[lambda-1, 1]+pako_str.p7cor, format='(F10.1)')
;; 
;;    if lambda eq 2 then begin
;;       log_info.result_name[p]    = cmd
;;       log_info.result_value[p]   = !undef
;;    endif
;; endfor
;; ;stop
;; print, ""
;; print, "-------------------------------------------------------"

;; Create a html page with plots from this scan
save, file=plot_output_dir+"/log_info.save", log_info
nk_logbook_sub, param.scan_num, param.day

;; Update logbook
nk_logbook, param.day

;;!;;offsets1 = reform(offsets[0,*])
;;!;;offsets2 = reform(offsets[1,*])
;;!;;
;;!;;nika_pipe_measure_atmo, param, data, kidpar, /noplot
;;!;;save, file=plot_output_dir+"/param.save", param
;;!;;
;;!;;exit:
end
