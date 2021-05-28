
;+
;
; SOFTWARE:
; NIKA pipeline
;
; NAME: 
; nk_scan_reduce_test
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_scan_reduce, param, info, data, kidpar, grid, subtract_maps=subtract_maps
; 
; PURPOSE: 
;        Performs decorrelation, filtering and produces maps from pre-processed TOIs
; 
; INPUT: 
;        - param, info, data, kidpar
;        - grid: the projection grid
; 
; OUTPUT: 
;        - grid is modified with the current scan maps
; 
; KEYWORDS:
;        - subtract_maps: strucuture that contains the maps that will be
;          subtracted from the TOI's if the user chooses to perform an
;          iterative map making.
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 08th, 2014: creation (Nicolas Ponthieu & Remi Adam)
;-

pro nk_scan_reduce_test, param, info, data, kidpar, grid, $
                    subtract_maps=subtract_maps,  $
                    out_temp_data=out_temp_data, $
                    input_polar_maps=input_polar_maps, lkg_kernel=lkg_kernel, simpar=simpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, " nk_scan_reduce, param, info, data, kidpar, grid, $"
   print, "                 subtract_maps=subtract_maps,  $"
   print, "                 out_temp_data=out_temp_data, $"
   print, "                 input_polar_maps=input_polar_maps, lkg_kernel=lkg_kernel"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; ;; In principle, the input maps should be subtracted from the timelines before
;; ;; the HWP template removal, to improve on this too...
;; ;; This will be improved in the future. For now, I put it here, otherwise
;; ;; data_copy is not cleaned from the template or we have to do it twice.
;; data_copy = data
;; if keyword_set(subtract_maps) then begin
;;    ;; toi's have already been calibrated in nk_scan_preproc, so we can
;;    ;; read directly the map and subtract it.
;;    nk_maps2data_toi, param, info, data, kidpar, subtract_maps, toi_input_maps
;;    data.toi -= toi_input_maps
;;    delvarx, toi_input_maps
;; endif

;; to test
if keyword_set(subtract_maps) and param.subtract_i_map eq 1 then begin

   if param.keep_mask eq 0 then begin
      message, /info, "forcing off_source to 1 everywhere to bypass the mask in the decorrelation"
      message, /info, "and use it only to subtract the input maps"
      data.off_source = 1.d0
   endif
   
   dd = sqrt( subtract_maps.xmap^2 + subtract_maps.ymap^2)
   
   data_copy = data
   
;;    nk_clean_data_3, param, info, data, kidpar, out_temp_data=out_temp_data_raw
;;    data = data_copy   
;;    stop
   w1 = where(kidpar.type eq 1 and (kidpar.array eq 1 or kidpar.array eq 3), nw1)

   ;; By default, take the mask provided by subtract_maps, so that it
   ;; can come from NIKA's data and be applied to external
   ;; simulations that would have different S/N threhold and so
   ;; different regions of subtraction
   w = where( subtract_maps.iter_mask_1mm gt 0., nw)
   if nw eq 0 then begin        ; no input mask provided, hence derive it from the data
      if param.sub_thres_sn gt 0.d0 then begin
         map_sn = dblarr(subtract_maps.nx, subtract_maps.ny)
         w = where( subtract_maps.nhits_1mm ne 0)
         map_sn[w] = subtract_maps.map_i_1mm[w]/sqrt( subtract_maps.map_var_i_1mm[w])
         if param.no_signal_threshold eq 1 then begin
            w = where( map_sn gt param.sub_thres_sn and $
                       dd le param.iter_mask_radius, nw)
         endif else begin
            w = where( map_sn gt param.sub_thres_sn and $
                       dd le param.iter_mask_radius and $
                       subtract_maps.map_i_1mm gt 0.d0, nw)
         endelse
      endif
   endif
   if nw ne 0 then begin
      my_mask     = subtract_maps.map_i_1mm*0.d0
      my_mask[w] = 1.d0
      nk_map2toi_3, param, info, subtract_maps.map_i_1mm*my_mask, data.ipix[w1], toi_i_1mm
      data.toi[w1] -= toi_i_1mm
   endif

   w1 = where(kidpar.type eq 1 and kidpar.array eq 2, nw1)
   w = where( subtract_maps.iter_mask_2mm gt 0., nw)
   if nw eq 0 then begin        ; no input mask provided, hence derive it from the data
      if param.sub_thres_sn gt 0.d0 then begin
         map_sn = dblarr(subtract_maps.nx, subtract_maps.ny)
         w = where( subtract_maps.nhits_2 ne 0)
         map_sn[w] = subtract_maps.map_i2[w]/sqrt( subtract_maps.map_var_i2[w])
         if param.no_signal_threshold eq 1 then begin
            w = where( map_sn gt param.sub_thres_sn and $
                       dd le param.iter_mask_radius, nw)
         endif else begin
            w = where( map_sn gt param.sub_thres_sn and $
                       dd le param.iter_mask_radius and $
                       subtract_maps.map_i2 gt 0.d0, nw)
         endelse
      endif
   endif
   if nw ne 0 then begin
      my_mask     = subtract_maps.map_i2*0.d0
      my_mask[w] = 1.d0
      grid.mask_source = my_mask
      nk_map2toi_3, param, info, subtract_maps.map_i2*my_mask, data.ipix[w1], toi_i_2mm
      data.toi[w1] -= toi_i_2mm
   endif
endif

;; @ nk_clean_data_3 decorrelates, filters the timelines.
nk_clean_data_3_test, param, info, data, kidpar, out_temp_data=out_temp_data, subtract_maps=subtract_maps

;; nk_clean_data_3, param, info, data_copy, kidpar, out_temp_data=out_temp_data_copy
;; 
;; ikid = where( kidpar.numdet eq 823)
;; wind, 1, 1, /free
;; !p.multi=[0,1,2]
;; plot, data_copy.toi[ikid] - out_temp_data.toi[ikid], /xs, title='copy_toi - out_temp_data', col=70
;; oplot, data_copy.toi[ikid] - out_temp_data_copy.toi[ikid], col=0
;; !p.multi=0
;; stop

if keyword_set(subtract_maps) and param.subtract_i_map eq 1 then begin
   
;;  ;; kidpar.type has been updated in nk_clean_data_3
;;     ikid = where( kidpar.numdet eq 823)
;;     help, toi_i_2mm, w1
;;     stop
;;     w = where(kidpar[w1].numdet eq 823)
;;     wind, 1, 1, /free
;;     !p.multi=[0,1,2]
;;     plot, data_copy.toi[ikid], /xs
;;     oplot, out_temp_data.toi[ikid], col=250
;;     plot, data_copy.toi[ikid]-out_temp_data.toi[ikid], /xs
;;     oplot, toi_i_2mm[w,*], col=150
;;     !p.multi=0
;;     stop
   data.toi = data_copy.toi - out_temp_data.toi
;; if keyword_set(subtract_maps) and param.subtract_i_map eq 1 then begin
;;    w1 = where(kidpar.type eq 1 and (kidpar.array eq 1 or kidpar.array eq 3), nw1)
;;    data.toi[w1] += toi_i_1mm
;;    w1 = where(kidpar.type eq 1 and kidpar.array eq 2, nw1)
;;    data.toi[w1] += toi_i_2mm
;; endif
;stop
endif

;; Now that the "common_mode" has been subtracted, If requested, we
;; can perform additional filtering
if param.lf_sin_fit_n_harmonics ne 0 then begin
   ;; Need to produce a mask for nk_lf_sin_fit
   ;; A common mask for both bands for a start
   if keyword_set(subtract_maps) then begin
      map_sn1 = dblarr(subtract_maps.nx, subtract_maps.ny)
      map_sn2 = dblarr(subtract_maps.nx, subtract_maps.ny)
      w = where( subtract_maps.nhits_1mm ne 0, nw)
      map_sn1[w] = subtract_maps.map_i_1mm[w]/sqrt( subtract_maps.map_var_i_1mm[w])
      w = where( subtract_maps.nhits_2 ne 0, nw)
      map_sn2[w] = subtract_maps.map_i2[w]/sqrt( subtract_maps.map_var_i2[w])
      
      w = where( map_sn1 gt param.sub_thres_sn or map_sn2 gt param.sub_thres_sn, nw)
      if nw ne 0 then begin
         grid.mask_source *= 0. + 1
         grid.mask_source[w] = 1
      endif
      w1 = where( kidpar.type eq 1, nw1)
      nk_map2toi_3, param, info, grid.mask_source, data.ipix, toi_mask
      data.off_source[w1] = toi_mask
      stop
   endif
   
   for isubscan=min(data.subscan), max(data.subscan) do begin
      wsubscan = where( data.subscan eq isubscan, nwsubscan)
      if nwsubscan ne 0 then begin
         data1 = data[wsubscan]
         nk_lf_sin_fit, param, info, data1, kidpar
         data[wsubscan].toi = data1.toi
      endif
   endfor
endif

if param.sim_fit_toi    eq 1 then nk_fit_sim_toi, param, info, data, kidpar
if param.twin_noise_toi eq 1 then nk_twin_noise_toi, param, info, data, kidpar
if param.force_white_noise ne 0 then nk_force_white_noise, param, info, data, kidpar

if info.status eq 1 then begin
   if param.silent eq 0 then $
      message, /info, 'Not enough data to achieve '+ info.scan
   return
endif

;; nk_measure_atmo monitors the atmosphere via the common mode if requested
if param.do_meas_atmo ne 0 then begin
   nsn = n_elements(data)
   common_mode = dblarr(2,nsn)
   nk_list_kids, kidpar, lambda=1, valid=w1mm, nval=nw1mm
   nk_list_kids, kidpar, lambda=2, valid=w2mm, nval=nw2mm
   if nw1mm ne 0 then common_mode[0,*] = out_temp_data.toi[w1mm[0]]
   if nw2mm ne 0 then common_mode[1,*] = out_temp_data.toi[w2mm[0]]
   nk_measure_atmo, param, info, data, kidpar, common_mode
endif

;; ;; Re-deglitch the data to improve after atmosphere subtraction
;; nk_deglitch, param, info, data, kidpar
if param.iterative_offsets eq 1 then begin
   nk_iterative_offsets, param, info, data, kidpar, subtract_maps
endif else begin
   if param.set_zero_level_full_scan ne 0 or $
      param.set_zero_level_per_subscan ne 0 then nk_set0level_2, param, info, data, kidpar
endelse

;;       ;;-----------------------------
;;       message, /info, "fix me:"
;;       nsn = n_elements(data)
;;       w1 = where( kidpar.type eq 1, nw1)
;;       noise = randomn( seed, 3*nw1*nsn)
;;       for i=0, nw1-1 do begin
;;          ikid = w1[i]
;;          data.toi[  ikid] = noise[    3*i*nsn:(3*i+1)*nsn-1]
;;          data.toi_q[ikid] = noise[(3*i+1)*nsn:(3*i+2)*nsn-1]
;;          data.toi_u[ikid] = noise[(3*i+2)*nsn:(3*i+3)*nsn-1]
;;       endfor
;; ;      stop
      ;;-----------------------------
;; @ Compute inverse variance weights for TOIs (for future projection)
nk_w8, param, info, data, kidpar

if keyword_set(simpar) then begin
   if simpar.toi1 eq 1 then begin
      ;; now that all projection and weight parameters have been
      ;; computed, replace sample values by "1" to see how the covariance
      ;; is reduced by the projection.
      
      ;; neglect the lowpass effect at this stage
      w1 = where( kidpar.type eq 1, nw1)
      data.toi[w1]   = 1.d0
      data.toi_q[w1] = 2.d0*data.cospolar##(dblarr(nw1)+1)
      data.toi_u[w1] = 2.d0*data.sinpolar##(dblarr(nw1)+1)
   endif
endif

;; Discard sections of timelines that are "too" noisy or show jumps or glitch
;; residuals... Do only on weak sources.
;; This is done on the entire scan, not 'per subscan'.
w1 = where( kidpar.type eq 1, nw1)

if param.kill_noisy_sections eq 1 then begin
   for i=0, nw1-1 do begin
      ikid = w1[i]
                                ;wk = where( data.flag[ikid] eq 0, nwk)
                                ;if nwk ne 0 then begin
                                ; look at each sample but estimate mean and sigma only on unflagged samples
                                ;w = where( abs( data.toi[ikid]-mean(data[wk].toi[ikid])) gt $
                                ;           param.kill_noise_nsigma*stddev( data[wk].toi[ikid]), nw)
      w = where( abs( data.toi[ikid]-mean(data.toi[ikid])) gt $
                 param.kill_noise_nsigma*stddev( data.toi[ikid]), nw)
      if nw ne 0 then nk_add_flag, data, 0, wsample=w
   endfor
endif

;; @ If this is a polarized scan, nk_lkg_correct_temp corrects
;; @^ the I to Q and I to U leakage using a template derived from
;; @^ observations of Uranus.
;; if keyword_set(input_polar_maps) and keyword_set(lkg_kernel) then $
;;    nk_lkg_correct, param, info, data, kidpar, grid, input_polar_maps, lkg_kernel, align=param.align ;, gauss_regul=param.lkg_gauss_regul
if keyword_set(input_polar_maps) and keyword_set(lkg_kernel) then $
   nk_lkg_correct_temp, param, info, data, kidpar, grid, input_polar_maps, lkg_kernel, align=param.align, gauss_regul=param.lkg_gauss_regul

;; Determine observation time and store info
info.result_total_obs_time = n_elements(data)/!nika.f_sampling

if param.cpu_time then nk_show_cpu_time, param, "nk_scan_reduce"
end
