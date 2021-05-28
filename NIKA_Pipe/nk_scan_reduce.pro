
;+
;
; SOFTWARE:
; NIKA pipeline
;
; NAME: 
; nk_scan_reduce
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

pro nk_scan_reduce, param, info, data, kidpar, grid, $
                    subtract_maps=subtract_maps,  $
                    out_temp_data=out_temp_data, $
                    input_polar_maps=input_polar_maps, $
                    lkg_kernel=lkg_kernel, simpar=simpar, astr=astr
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

if keyword_set(subtract_maps) and param.subtract_i_map eq 1 then begin

   if param.keep_mask eq 0 then begin
      message, /info, "forcing off_source to 1 everywhere to bypass the mask in the decorrelation"
      message, /info, "and use it only to subtract the input maps"
      data.off_source = 1.d0
   endif
   
   dd = sqrt( subtract_maps.xmap^2 + subtract_maps.ymap^2)
   
   data_copy = data
   
   ;; By default, take the mask provided by subtract_maps, so that it
   ;; can come from NIKA's data and be applied to external
   ;; simulations that would have different S/N threhold and so
   ;; different regions of subtraction
   ;;
   ;; 1mm
   w1 = where(kidpar.type eq 1 and (kidpar.array eq 1 or kidpar.array eq 3), nw1)
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
      grid.mask_source_1mm = my_mask
      nk_map2toi_3, param, info, subtract_maps.map_i_1mm*my_mask, data.ipix[w1], toi_i_1mm
      data.toi[w1] -= toi_i_1mm
   endif

   ;; 2mm
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
      grid.mask_source_2mm = my_mask
      nk_map2toi_3, param, info, subtract_maps.map_i2*my_mask, data.ipix[w1], toi_i_2mm
      data.toi[w1] -= toi_i_2mm
   endif
endif

if param.pre_wiener ne 0 then nk_wiener_filter, param, info, data, kidpar

;; @ {\tt nk_clean_data_3} decorrelates, filters the timelines etc...
case param.clean_data_version of
   3: nk_clean_data_3, param, info, data, kidpar, out_temp_data=out_temp_data
   4: nk_clean_data_4, param, info, data, kidpar, grid, out_temp_data=out_temp_data
   else: message, /info, "Wrong value of param.clean_data_version: "+strtrim(param.clean_data_version,2)
endcase

if param.post_wiener ne 0 then nk_wiener_filter, param, info, data, kidpar

;; wind, 1, 1, /free, /large
;; my_multiplot, 1, 3, pp,pp1, /rev
;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;;    make_ct, nw1, ct
;;    if nw1 ne 0 then begin
;;       plot, data.toi[w1[0]]-data[0].toi[w1[0]], /xs, $
;;             position=pp[0,iarray-1,*], /noerase
;;       for i=0, nw1-1 do oplot, data.toi[w1[i]]-data[0].toi[w1[i]], col=ct[i]
;;    endif
;; endfor
;; stop

;;--------------------------
;; Look at the common mode correlation between 1 and 2mm
nsn = n_elements(data)
all_common_modes = dblarr(nsn,3)
for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray and kidpar.c1_skydip gt 0., nw1)

   if nw1 ne 0 then begin
      ;; 1. take out_temp_data because the CM has been removed in data
      ;; 2. Intercalib with C1 coeffs, not kidpar.calib
      calib = (dblarr(nsn)+1.d0)##(1./kidpar[w1].calib_fix_fwhm/kidpar[w1].c1_skydip) ; back to Hz and then to K
      if strupcase(param.decor_method) ne "NONE" then begin
         cm_toi = out_temp_data.toi[w1]*calib
      endif else begin
         cm_toi = data.toi[w1]*calib
      endelse
      nk_get_cm_sub_2, param, info, $
                       cm_toi, $
                       data.flag[w1], $
                       data.off_source[w1], kidpar[w1], common_mode
      all_common_modes[*,iarray-1] = common_mode
   endif
endfor
;; Correlation
fit = linfit( all_common_modes[*,0], all_common_modes[*,1])
info.A2_TO_A1_CM_CORR = fit[1]
fit = linfit( all_common_modes[*,2], all_common_modes[*,1])
info.A2_TO_A3_CM_CORR = fit[1]

;;--------------------------

if keyword_set(subtract_maps) and param.subtract_i_map eq 1 then begin
   data.toi = data_copy.toi - out_temp_data.toi
endif

;; Correct for opacity with current elevation.
;; do it here and not at the same time as the absolute calibraiton not
;; to introduce non linearity on the timelines and the noise before
;; the decorrelation.
if param.do_opacity_correction eq 3 then begin
   ;; Compute (az,el) of each kid at each time
   param1          = param
   param1.map_proj = "azel"
   dra_copy        = data.dra
   ddec_copy       = data.ddec
   nk_get_kid_pointing, param1, info, data, kidpar
   nsn = n_elements(data)
   w1 = where( kidpar.type eq 1, nw1)
   true_elevation = transpose( rebin( data.el, nsn, nw1)) + data.ddec[w1]/3600.d0*!dtor
   ;; restore the requested coordinate system in input
   data.dra  = dra_copy
   data.ddec = ddec_copy
   delvarx, dra_copy, ddec_copy, param1
   ;; Correct for opacity and air mass
   kid_tau_skydip = rebin( kidpar[w1].tau_skydip, nw1, nsn)
   corr = exp( kid_tau_skydip/sin(true_elevation))
   data.toi[w1] *= corr
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
      mask = grid.mask_source_1mm*0.d0 + 1
      if nw ne 0 then begin
         ;;grid.mask_source *= 0. + 1
         ;;grid.mask_source[w] = 1
         mask[w] = 1
      endif
      w1 = where( kidpar.type eq 1, nw1)
      nk_map2toi_3, param, info, mask, data.ipix, toi_mask
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

if param.sim_fit_toi       eq 1 then nk_fit_sim_toi, param, info, data, kidpar
if param.twin_noise_toi    eq 1 then nk_twin_noise_toi, param, info, data, kidpar
if param.force_white_noise ne 0 then nk_force_white_noise, param, info, data, kidpar

if info.status eq 1 then begin
   if param.silent eq 0 then $
      message, /info, 'Not enough data to achieve '+ info.scan
   return
endif

;; Assess scan quality based on atmosphere and decorrelation
nk_scan_quality_monitor, param, info, data, kidpar, out_temp_data

;;  Re-deglitch the data to improve after atmosphere subtraction
;; nk_deglitch, param, info, data, kidpar
if param.iterative_offsets eq 1 then begin
   nk_iterative_offsets, param, info, data, kidpar, subtract_maps
endif else begin
   if param.set_zero_level_full_scan ne 0 or $
      param.set_zero_level_per_subscan ne 0 then nk_set0level_2, param, info, data, kidpar
endelse

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

w1 = where( kidpar.type eq 1, nw1)

;; Discard sections of timelines that are "too" noisy or show jumps or glitch
;; residuals... Do only on weak sources.
;; This is done on the entire scan, not 'per subscan'.
if param.kill_noisy_sections eq 1 then begin
   for i=0, nw1-1 do begin
      ikid = w1[i]
      w = where( abs( data.toi[ikid]-mean(data.toi[ikid])) gt $
                 param.kill_noise_nsigma*stddev( data.toi[ikid]), nw)
      if nw ne 0 then nk_add_flag, data, 0, wsample=w
   endfor
endif

;; @ If this is a polarized scan, {\tt nk_lkg_correct_temp} Corrects
;; @^ the I to Q and I to U leakage using a template derived from
;; @^ observations of Uranus.
;; if keyword_set(input_polar_maps) and keyword_set(lkg_kernel) then $
;;    nk_lkg_correct, param, info, data, kidpar, grid,
;;    input_polar_maps, lkg_kernel, align=param.align ;,
;;    gauss_regul=param.lkg_gauss_regul

if keyword_set(input_polar_maps) and keyword_set(lkg_kernel) then begin
;;    nk_lkg_correct_temp, param, info, data, kidpar, grid, $
;;                         input_polar_maps, lkg_kernel, align=param.align, gauss_regul=param.lkg_gauss_regul
   ;; nk_lkg_correct, param, info, data, kidpar, grid, $
   ;;                 input_polar_maps, lkg_kernel,
   ;;                 gauss_regul=param.lkg_gauss_regul, astr=astr

   if !nika.run le 12 then begin
   nk_lkg_correct_temp_nika, param, info, data, kidpar, grid, $
                             input_polar_maps, lkg_kernel, $
                             gauss_regul=param.lkg_gauss_regul, astr=astr
endif else begin
   nk_lkg_correct2, param, info, data, kidpar, grid, $
                    input_polar_maps, lkg_kernel, $
                    gauss_regul=param.lkg_gauss_regul, astr=astr
   endelse
   
endif
   
   
;; Determine observation time and store info
info.result_total_obs_time = n_elements(data)/!nika.f_sampling

if param.cpu_time then nk_show_cpu_time, param
end
