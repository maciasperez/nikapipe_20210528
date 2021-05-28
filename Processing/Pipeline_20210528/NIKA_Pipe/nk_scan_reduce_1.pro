
;+
;
; SOFTWARE:
; NIKA pipeline
;
; NAME: 
; nk_scan_reduce_1
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_scan_reduce_1, param, info, data, kidpar, grid, subtract_maps=subtract_maps
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
;        - April 24th, 2018: NP, cleaner and improved version of nk_scan_reduce

pro nk_scan_reduce_1, param, info, data, kidpar, grid, $
                      subtract_maps=subtract_maps,  $
                      out_temp_data=out_temp_data, $
                      input_polar_maps=input_polar_maps, $
                      simpar=simpar, astr=astr, lf_decor_map=lf_decor_map
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_scan_reduce_1'
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then  message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.log then nk_log, info, "----------- Entering nk_scan_reduce_1"
if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; wind, 1, 1, /f
;; imview, grid.mask_source_1mm, xmap=grid.xmap, ymap=grid.ymap
;; phi = dindgen(360)*!dtor
;; oplot, 6.5/2*60.*cos(phi), 6.5/2.*60*sin(phi), col=255
;; stop

;; @ Define which parts of the maps must be masked for common mode estimation
;; grid.mask_source_XXmm must be 1 outside the source, 0 on source
if keyword_set(subtract_maps) then $
   nk_update_mask_source, param, info, data, kidpar, grid, subtract_maps

;wind, 1, 1, /fr, /l
;my_multiplot, 2, 2, pp, pp1, /rev
;imview, subtract_maps.iter_mask_1mm, position=pp1[0,*]
;imview, grid.mask_source_1mm, position=pp1[1,*], /noerase
;stop

;; @ Update data.off_source according to grid.mask_source_Xmm
nk_mask_source, param, info, data, kidpar, grid

;; Get rid of outlyers w.r.t the common mode
param_temp  = param
;;;;;;;;;;param_temp.niter_cm = 100
for iarray=1, 3 do begin
   noutlyers = 1 ; init
   iter = 0
   while noutlyers ne 0 do begin
      noutlyers = 0

      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
      myflag = data.flag[w1]
      nk_get_cm_sub_2, param_temp, info, data.toi[w1], myflag, data.off_source[w1], kidpar[w1], $
                       common_mode, output_kidpar=output_kidpar
      
      ;; w  = where(        kidpar.type eq 3 and        kidpar.array eq iarray, nw)
      ;; ww = where( output_kidpar.type eq 3 and output_kidpar.array eq iarray, nww)
      ;; print, nw, nww

      kidpar[w1].type = output_kidpar.type
      
      coeffs = dblarr(nw1,2)
      for i=0, nw1-1 do begin
         wfit = where( data.off_source[w1[i]] eq 1, nwfit)
         fit = linfit( common_mode[wfit], data[wfit].toi[w1[i]])
         coeffs[i,*] = fit
      endfor
      w = where( abs(coeffs[*,0]-median(coeffs[*,0])) gt 7*stddev(coeffs[*,0]), nw)
      if nw ne 0 then begin
         noutlyers += nw
         kidpar[w1[w]].type = 3
      endif
      w = where( abs(coeffs[*,1]-median(coeffs[*,1])) gt 7*stddev(coeffs[*,1]), nw)
      if nw ne 0 then begin
         noutlyers += nw
         kidpar[w1[w]].type = 3
      endif
      
;;      wind, 1, 1, /free, /large
;;      make_ct, nw1, ct
;;      yra = array2range( data.toi[w1])
;;      plot, data.toi[w1[0]], /xs, /ys, yra=yra, position=[0.1,0.1,0.4,0.5]
;;      for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]
;;      my_multiplot, 1, 2, pp, pp1, /rev, xmin=0.5, xmax=0.95
;;      plot, coeffs[*,0], /xs, position=pp1[0,*], /noerase, title='A'+strtrim(iarray,2)+', iter '+strtrim(iter,2)
;;      w = where( abs(coeffs[*,0]-median(coeffs[*,0])) gt 7*stddev(coeffs[*,0]), nw)
;;      if nw ne 0 then oplot, [w], [coeffs[w,0]], psym=8, col=250
;;
;;      plot, coeffs[*,1], /xs, position=pp1[1,*], /noerase
;;      w = where( abs(coeffs[*,1]-median(coeffs[*,1])) gt 7*stddev(coeffs[*,1]), nw)
;;      if nw ne 0 then oplot, [w], [coeffs[w,1]], psym=8, col=250
;;      stop

   ;; New try at sky noise figure of merit
      power_spec, common_mode-my_baseline(common_mode,base=0.01), !nika.f_sampling, pw_cm, freq
      wlf = where( freq ge param.skynoise_low_freq and freq lt param.skynoise_high_freq, nwlf)
      whf = where( freq ge param.skynoise_high_freq, nwhf)
      if nwlf ne 0 and nwhf ne 0 then begin
         nk_get_info_tag, info, 'sky_noise_power', iarray, wtag
         ;; delta_f = freq[1]-freq[0] ;; It cancels out, I did not foret
         ;; it :)
         ;; power_spec is in units of signal.hz^(-1/2), we must integrate
         ;; the square to be homogeneous to sky variance
         info.(wtag) = total( pw_cm[wlf]^2)/total( pw_cm[whf]^2)
      endif
      iter++
   endwhile

endfor

;; Do not check outlying kids vs cm in the following: box, subbands,
;; subscans could lead to an artificial downselection => ensure param.niter_cm
param.niter_cm = 1

if param.on_the_fly_kid_noise eq 1 then begin
   @on_the_fly_kid_noise.pro
endif

myp = -1

;; @ look for small glitches that have escaped nk_deglitch on
;; individual timelines but that show up when coadded in the array
;; common mode.
if param.improve_deglitch then nk_improve_deglitch, param, info, data, kidpar

;;@ Alter data according to simulations if requested via the "simpar"
;;keyword
;; data1 = data
if keyword_set(simpar) then $
   nk_deal_with_simulations, param, info, data, kidpar, grid, simpar, astr=astr

;; wind, 1, 1, /f
;; ikid = where( kidpar.numdet eq !nika.ref_det[0])
;; !p.multi=[0,1,2]
;; plot, data1.toi[ikid]
;; oplot, data.toi[ikid], col=250
;; plot, data.toi[ikid]-data1.toi[ikid]
;; !p.multi=0
;; stop

if param.save_sim_data eq 1 then begin
   toi  = data.toi
   ipix = data.ipix
   dra  = data.dra
   ddec = data.ddec
   flag = data.flag
   save_sim_data_file = param.project_dir+'/sim_data_'+param.scan+'.save'
   save, toi, ipix, dra, ddec, flag, param, info, kidpar, simpar, grid, astr, $
         file=save_sim_data_file
   message, /info, "Saved "+save_sim_data_file
;   save, param, info, data, kidpar, simpar, grid, astr, $
;         file=param.project_dir+'/sim_data_'+param.scan+'.save'
endif 

if param.beam_freq_cut_db gt 0.d0 then begin
   ;; See Labtools/NP/Polar/Mess/bhss.pro for the derivation of the
   ;; beam transfer function in time as a function of the scanning speed
   cut_freq = sqrt( param.beam_freq_cut_db*2*alog(10))/(2.d0*!dpi*!nika.fwhm_nom[0]*!fwhm2sigma)*info.median_scan_speed
   if cut_freq lt !nika.f_sampling/2. then begin
      param.freqlow          = 0.d0
      param.freqhigh         = cut_freq
      param.bandpass_delta_f = 0.2
      nk_bandpass_filter, param, info, data, kidpar
   endif
endif 

;; wind, 1, 1, /free, /large
;; ikid = where( kidpar.numdet eq !nika.ref_det[0])
;; power_spec, data.toi[ikid] - my_baseline(data.toi[ikid], b=0.05), !nika.f_sampling, pw, freq
;; plot_oo, freq, pw, /xs
;; stop

;; Build snr_toi if possible and requested
if keyword_set(subtract_maps) then begin
   if param.k_snr_w8_decor gt 0.d0 and $
      max( abs( subtract_maps.map_i_1mm)) gt 0.d0 then begin

      ;; restrict to some user defined region to compute snr_toi
      k_snr_mask = subtract_maps.map_i_1mm*0.d0
      w = where( sqrt( subtract_maps.xmap^2 + subtract_maps.ymap^2) le param.k_snr_radius, nw)
      k_snr_mask[w] = 1.d0

      if param.log then nk_log, info, "creating snr_toi"
      snr_toi = data.toi*0.d0   ; init to 0 to have uniform weight=1 by default
      w13 = where( kidpar.type eq 1 and (kidpar.array eq 1 or kidpar.array eq 3), nw13)
      if nw13 ne 0 and max(abs(subtract_maps.map_i_1mm)) gt 0.d0 then begin
         nk_snr_flux_map, subtract_maps.map_i_1mm, subtract_maps.map_var_i_1mm, $
                          subtract_maps.nhits_1mm, !nika.fwhm_nom[0], $
                          subtract_maps.map_reso, info, snr_flux_map_1mm, $
                          method = param.k_snr_method, /noboost
                                ; noboost is to avoid renormalising
                                ; data (here it contains only the high
                                ; snr end
         nk_map2toi_3, param, info, subtract_maps.snr_mask_1mm*k_snr_mask*snr_flux_map_1mm, $
                       data.ipix[w13], snr_toi_1mm
         if param.positive_snr_toi eq 1 then begin
            snr_toi[w13,*] = (snr_toi_1mm < param.snr_max) > 0
         endif else begin
            snr_toi[w13,*] = abs(snr_toi_1mm) < param.snr_max
         endelse
         delvarx, snr_toi_1mm
      endif
      w2 = where( kidpar.type eq 1 and kidpar.array eq 2, nw2)
      if nw2 ne 0 and max( abs( subtract_maps.map_i_2mm)) gt 0.d0 then begin
         nk_snr_flux_map, subtract_maps.map_i_2mm, subtract_maps.map_var_i_2mm, $
                          subtract_maps.nhits_2mm, !nika.fwhm_nom[1], $
                          subtract_maps.map_reso, info, snr_flux_map_2mm, $
                          method = param.k_snr_method, /noboost  ; boost has been applied in nk_average_Scans so don't do it here.
         nk_map2toi_3, param, info, subtract_maps.snr_mask_2mm*k_snr_mask*snr_flux_map_2mm, $
                       data.ipix[w2], snr_toi_2mm
         if param.positive_snr_toi eq 1 then begin
            snr_toi[w2,*] = ( snr_toi_2mm < param.snr_max) > 0
         endif else begin
            snr_toi[w2,*] = abs(snr_toi_2mm) < param.snr_max
         endelse
         delvarx, snr_toi_2mm
      endif

      ;; Derive snr_w8 maps
      nkids = n_elements(kidpar)
      nsn = n_elements(data)
      d = {toi:dblarr(nkids), ipix:dblarr(nkids), w8:dblarr(nkids), flag:dblarr(nkids)}
      d = replicate( d, nsn)
      d.toi  = 1.d0/(1.d0 + param.k_snr_w8_decor*snr_toi^2)
      d.ipix = data.ipix
      d.w8   = 1
      d.flag = data.flag
      info1 = info
      grid1 = grid
      nk_projection_4, param, info1, d, kidpar, grid1
      grid.snr_w8_1mm = grid1.map_i_1mm
      grid.snr_w8_2mm = grid1.map_i2
      delvarx, d, info1, grid1
   endif
endif

;help, snr_toi
;stop

if info.polar ne 0 then begin
   ;; @ {\tt nk_nk_get_hwpss} and subtract HWPSS if polar scan

   ;; copy of reference TOI's before template subtraction
   nsn = n_elements(data)
   y   = dblarr(3,nsn)
   y1  = dblarr(3,nsn)
   for iarray=1, 3 do begin
      ikid = where( kidpar.numdet eq !nika.ref_det[iarray-1])
      y[iarray-1,*] = data.toi[ikid]
   endfor
;   save, file='data.save'
;   stop

   ;; Add the Nasmyth to sky rotation of the polariztion
   ;; Moved out from nk_get_hwp_angle to here, NP. Dec. 5th, 2017
   if info.polar ge 1 then begin
      if param.new_pol_synchro eq 0 then begin
         nk_nasmyth2sky_polar, param, info, data, kidpar
      endif else begin
         nk_nasmyth2sky_polar_2, param, info, data, kidpar
      endelse
   endif

   if param.do_not_remove_hwp_template eq 0 then begin
      
      if keyword_set(subtract_maps) then begin
         toi_save = data.toi

         ;; I subtracted the signal from data.toi, so now the mask
         ;; must not be accounted for in the hwpss derivation
         off_source_copy = data.off_source

         for iarray=1, 3 do begin
            if iarray ne 2 then begin
               w1 = where(kidpar.type eq 1 and kidpar.array eq iarray, nw1)
               nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.iter_mask_1mm*subtract_maps.map_i_1mm, data.ipix[w1], toi_i_1mm
               nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.polar_mask*subtract_maps.map_q_1mm, data.ipix[w1], toi_q_1mm
               nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.polar_mask*subtract_maps.map_u_1mm, data.ipix[w1], toi_u_1mm
               if iarray eq 3 then begin
                  toi_q_1mm *= -1
                  toi_u_1mm *= -1
               endif
               data.toi[w1] -= toi_i_1mm + $
                               (data.cospolar##(dblarr(nw1)+1))*toi_q_1mm + $
                               (data.sinpolar##(dblarr(nw1)+1))*toi_u_1mm

               ;; Not enough to just do "data.off_source = 1" here in case I use nk_decor_8: no signal at the
               ;; center in subtract_maps.map_X, hence no subtraction, hence
               ;; still (high) signal in the toi that induces ringing when
               ;; fitting for hwpss.
               ;; data.off_source = 1
               
               ;; => Need also to work only where signal has been
               ;; subtracted, hence use Nhits.
               nhits = subtract_maps.nhits_1mm
               nk_map2toi_3, param, info, subtract_maps.nhits_1mm, data.ipix[w1], toi_nhits_1mm
               data.off_source[w1] = long( toi_nhits_1mm gt (param.nhits_fraction_min*median( nhits[where(nhits ne 0)])))
            endif
         endfor

      endif

      ;; Estimate the HWPSS
      nk_get_hwpss, param, info, data, kidpar, hwpss, snr_toi=snr_toi

      ;; Restore toi for further lock-in and signal timelines production
      if keyword_set(subtract_maps) then begin
         data.toi = toi_save
         data.off_source = off_source_copy
         delvarx, toi_save, off_source_copy
      endif
      
      w1 = where( kidpar.type eq 1, nw1)
      ;; Put back input signal in data.toi because it's needed
      ;; in nk_lockin to produce the I_TOI
      if strupcase( strtrim(info.obs_type,2)) eq "DIY" then begin
         data.df_tone[w1] -= hwpss
      endif else begin
         ;; subtract only hwpss from raw data that contain all the
         ;; I,Q and U signal
         ;; data.toi[w1] = toi_copy[w1,*] - hwpss
         if param.keep_one_hwp_position eq 0 then data.toi[w1] -= hwpss
                                ; else param.keep_one_hwp_position=1 (experimental case FXD) don't do anything
      endelse
   endif 

   ;; Copy of toi after subtraction for monitoring plots
   for iarray=1, 3 do begin
      ikid = where( kidpar.numdet eq !nika.ref_det[iarray-1])
      y1[iarray-1,*] = data.toi[ikid]
   endfor
   
   ;; Builds data.toi_q, data.toi_u and lowpasses toi
   nk_lockin_2, param, info, data, kidpar
   
   nk_hwp_lockin_plot, param, info, data, kidpar, y, y1
endif                           ; end of polar case

;;===============================================================================================
;;
;; HWPSS has been subtracted from the raw data, so there is I, Q
;; and U in data.toi here.
;; So if we want to subtract I, Q, U maps, we need to redo it but
;; NOT WITH nk_subtract_maps_from_toi that subtracts the
;; combination of I + Q x cos4omega + U x sin4omega to data.toi so far

if param.undersamp_postproc ne 0 then begin
   w1 = where( kidpar.type eq 1, nw1)
   for i=0, nw1-1 do begin
      data.toi[ikid] = smooth( data.toi[ikid], param.undersamp_postproc)
      if info.polar eq 1 then begin
         data.toi_q[ikid] = smooth( data.toi_q[ikid], param.undersamp_postproc)
         data.toi_u[ikid] = smooth( data.toi_u[ikid], param.undersamp_postproc)
      endif
   endfor
   nsn = n_elements(data)
   index = lindgen(nsn/param.undersamp_postproc) * param.undersamp_postproc
   data = data[index]
   nsn = n_elements(data)
endif


;; Needed to preserve data while determining common modes
;; LP renamed to be sure it is not modiky by any subsequent routines
;; (e.g. nk_decor_sub_6, nk_decor_common_mode_one_block, ...)
;;toi_copy = data.toi
original_toi = data.toi
datasub = data
datasub.toi = data.toi*0.D0     ; This Toi is here to provide a way of defiltering in method 120. Not used otherwise

;; wind, 1, 1, /free, /large
;; my_multiplot, 2, 2, pp, pp1, /rev
;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
;;    if nw1 ne 0 then begin
;;       make_ct, nw1, ct
;;       plot, data.toi[w1[0]], /xs, yra=array2range(data.toi[w1]), /ys, $
;;             position=pp1[iarray-1,*], /noerase
;;       for i=0, nw1-1 do begin
;;          oplot, data.toi[w1[i]], col=ct[i]
;;       endfor
;;    endif
;; endfor

;; here_plot = 0
;; istokes=0
;; @check_tois_and_common_mode.pro
;; istokes=1
;; @check_tois_and_common_mode.pro
;; istokes=2
;; @check_tois_and_common_mode.pro

;; If iterative mode, subtract the previous iteration maps from the data.
if keyword_set(subtract_maps) then begin
   smo = subtract_maps          ; smo contains the original complete map
                                ; and does not change
   if param.keep_only_high_snr gt 0 then begin
      if keyword_set( param.split_horver) then $
         add_mapin = lf_decor_map else add_mapin = 0
      nk_keep_only_high_snr, param, info, smo, subtract_maps, $
                             smooth_residue = smd, $
                             add_mapin = add_mapin, $
                             out_res_mapin = out_res_mapin
                                ; subtract_maps contains only the high SNR part of the map
      if keyword_set( param.split_horver) then smd = out_res_mapin
                                ; smd contains the low SNR part of the
                                ; map (only used to compute the LF
                                ; part of the toi).
   endif

;   if param.mydebug eq 1 then begin
;      wind, 1, 1, /free, /large
;      debug_window = !d.window
;      myikid = 437                ; 538 ; 640
;      nsn = n_elements(data)
;      index = lindgen(nsn)
;      my_y_raw = data.toi[myikid]
;      plot, index, my_y_raw, /xs, /ys
;      legendastro, 'Raw toi myikid '+strtrim(myikid,2)
;   endif

;;    wind, 1, 1, /free, /large
;;    my_multiplot, 2, 1, pp, pp1
;;    imview, grid.mask_source_1mm, position=pp1[0,*]
;;    imview, grid.mask_source_2mm, position=pp1[1,*], /noerase
;;    stop
   
   if param.subtract_i_map eq 1 then $
      nk_subtract_maps_from_toi, param, info, data, kidpar, grid, subtract_maps

    ;; Redefine the decorrelation mask for this specific method
    if param.method_num eq 676 or param.force_mask_nhits eq 1 then begin
       ;; wind, 1, 1, /free, /large
       ;; my_multiplot, 3, 3, pp, pp1, /rev
       ;; imview, subtract_maps.iter_mask_1mm, position=pp[0,0,*], title='subtract_maps.iter_mask_1mm'
       ;; imview, grid.mask_source_1mm, position=pp[1,0,*], title='grid.mask_source_1mm', /noerase
       ;; imview, subtract_maps.nhits_1mm, position=pp[2,0,*], title='Nhits 1mm', /noerase
       ;; imview, subtract_maps.nhits_2mm, position=pp[0,1,*], title='Nhits 2mm', /noerase
 
       mask = subtract_maps.iter_mask_1mm
       nhits = subtract_maps.nhits_1mm
       if max(abs(nhits)) gt 0 then begin
          w = where( nhits le param.nhits_fraction_min*median( nhits[where(nhits ne 0)]), nw)
          mask = nhits*0 + 1
          if nw ne 0 then mask[w] = 0
          ;; imview, mask, position=pp[1,1,*], title='mask 1mm',
          ;; /noerase
       endif
;       stop
       grid.mask_source_1mm = mask
 
       mask = subtract_maps.iter_mask_2mm
       nhits = subtract_maps.nhits_2mm
       if max(abs(nhits)) gt 0 then begin
          w = where( nhits le param.nhits_fraction_min*median( nhits[where(nhits ne 0)]), nw)
          mask = nhits*0 + 1
          if nw ne 0 then mask[w] = 0
          ;; imview, mask, position=pp[2,1,*], title='mask 2mm',
          ;; /noerase
       endif
       grid.mask_source_2mm = mask
       
       ;; recompute data.off_source for the decorrelation
       nk_mask_source, param, info, data, kidpar, grid
    endif

;   if param.mydebug eq 1 then begin
;      wshet, debug_window
;      my_y1 = data.toi[myikid]
;      ws = where( data.subscan-shift(data.subscan,1) eq 1, nws)
;      plot, index, my_y_raw, /xs, /ys
;      oplot, index, my_y1, col=70
;      for is=0, nws-1 do oplot, [1,1]*ws[is], [-1,1]*1d10, col=100
;      legendastro, [strtrim(myikid,2), $
;                    'Raw toi', 'Raw toi -Imap'], col=[0,0,70]
;   endif
   
   if param.iter_interpol_high_snr eq 1 then begin
      nk_interpol_high_snr, param, info, data, kidpar, grid, subtract_maps
   endif 

; Compute the TOI from the original subtract_maps in order to compute
; the defiltering
   if param.atmb_defilter ne 0 and $
      param.imcm_iter ge param.atmb_defilter then begin
      w1 = where(kidpar.type eq 1 and $
                 (kidpar.array eq 1 or kidpar.array eq 3), nw1)
      w = where( smd.nhits_1mm gt 0, nw)
      if nw ne 0 and nw1 ne 0 then begin ; no input mask provided,
                                ; hence derive it from the data
         my_mask    = smd.map_i_1mm*0.d0
         my_mask[w] = 1.d0
         nk_map2toi_3, param, info, smd.map_i_1mm*my_mask, $
                       data.ipix[w1], toi_i_1mm
         datasub.toi[w1] = toi_i_1mm ; this reads the smooth map without the high SNR part
      endif

      ;; 2mm
      w2 = where(kidpar.type eq 1 and kidpar.array eq 2, nw2)
      w = where( smd.nhits_2mm gt 0, nw)
      if nw ne 0 and nw2 ne 0 then begin 
         my_mask    = smd.map_i_2mm*0.d0
         my_mask[w] = 1.d0
         nk_map2toi_3, param, info, smd.map_i_2mm*my_mask, $
                       data.ipix[w2], toi_i_2mm
         datasub.toi[w2] = toi_i_2mm
      endif 
   endif                         ; end case of defiltering
   
   
   ;; if snr_toi has not already been estimated and is required,
   ;; compute it now
   if param.k_snr_w8_decor gt 0.d0 and $
      max( abs( smo.map_i_1mm)) gt 0.d0 then begin
; smo contains the whole map, hence snr will be better defined and
; complete FXD 8dec2020 (was subtract_maps before, only high snr)
      ;; restrict to some user defined region to compute snr_toi
      k_snr_mask = smo.map_i_1mm*0.d0
      w = where( sqrt( smo.xmap^2 + smo.ymap^2) le $
                 param.k_snr_radius, nw)
      k_snr_mask[w] = 1.d0

      if param.log then nk_log, info, "creating snr_toi"
      snr_toi = data.toi*0.d0   ; init to 0 to have uniform weight=1 by default
      w13 = where( kidpar.type eq 1 and $
                   (kidpar.array eq 1 or kidpar.array eq 3), nw13)
      if nw13 ne 0 and max(abs(smo.map_i_1mm)) gt 0.d0 then begin
         nk_snr_flux_map, smo.map_i_1mm, $
                          smo.map_var_i_1mm, $
                          smo.nhits_1mm, !nika.fwhm_nom[0], $
                          smo.map_reso, info, snr_flux_map_1mm, $
                          method = param.k_snr_method, /noboost
                                ; noboost is to avoid renormalising
                                ; data (here it contains only the high
                                ; snr end
         nk_map2toi_3, param, info, $
                       smo.snr_mask_1mm*k_snr_mask*snr_flux_map_1mm, $
                       data.ipix[w13], snr_toi_1mm
         ;; snr_toi[w13,*] = abs(snr_toi_1mm) < param.snr_max
         if param.positive_snr_toi eq 1 then begin
            snr_toi[w13,*] = (snr_toi_1mm < param.snr_max) > 0
         endif else begin
            snr_toi[w13,*] = abs(snr_toi_1mm) < param.snr_max
         endelse
         delvarx, snr_toi_1mm
      endif
      
      w2 = where( kidpar.type eq 1 and kidpar.array eq 2, nw2)
      if nw2 ne 0 and max( abs( smo.map_i_2mm)) gt 0.d0 then begin
;;         print, minmax(smo.map_i_2mm), $
;;                minmax(smo.map_var_i_2mm), $
;;                minmax(smo.nhits_2mm)
;;stop
         nk_snr_flux_map, smo.map_i_2mm, $
                          smo.map_var_i_2mm, $
                          smo.nhits_2mm, !nika.fwhm_nom[1], $
                          smo.map_reso, info, snr_flux_map_2mm, $
                          method = param.k_snr_method, /noboost
         nk_map2toi_3, param, info, $
                       smo.snr_mask_2mm*k_snr_mask*snr_flux_map_2mm, $
                       data.ipix[w2], snr_toi_2mm
;;         snr_toi[w2,*] = abs(snr_toi_2mm) < param.snr_max
         if param.positive_snr_toi eq 1 then begin
            snr_toi[w2,*] = ( snr_toi_2mm < param.snr_max) > 0
         endif else begin
            snr_toi[w2,*] = abs(snr_toi_2mm) < param.snr_max
         endelse
         snr_toi[w2,*] = abs(snr_toi_2mm) < param.snr_max
         delvarx, snr_toi_2mm
      endif 

      ;; Derive snr_w8 maps
      nkids = n_elements(kidpar)
      nsn = n_elements(data)
      d = {toi:dblarr(nkids), ipix:dblarr(nkids), w8:dblarr(nkids), flag:dblarr(nkids)}
      d = replicate( d, nsn)
      d.toi  = 1.d0/(1.d0 + param.k_snr_w8_decor*snr_toi^2)
      d.ipix = data.ipix
      d.w8   = 1
      d.flag = data.flag
      info1 = info
      grid1 = grid
      info1.polar = 0
      nk_projection_4, param, info1, d, kidpar, grid1
      grid.snr_w8_1mm = grid1.map_i_1mm
      grid.snr_w8_2mm = grid1.map_i2
      delvarx, d, info1, grid1
    endif 
endif

if param.do_dmm eq 1 then begin
;   toi  = data.toi
;   dra  = data.dra
;   ddec = data.ddec
;   flag = data.flag
   dmm_param = param
   dmm_param.map_reso = param.dmm_map_reso

   ;;-----------------------
;   save, file='data.save'
;   stop

;   restore, 'data.save'
;   dmm_param.nharm_multi_sinfit = 2
   
   ;;-----------------------
   
   dmm_lambda, dmm_param, info, data.toi, data.dra, data.ddec, data.flag, $
               kidpar, dmm_grid, param.dmm_rmax, kidpar_copy, $
               kid_reso=param.dmm_kid_reso, subscan=data.subscan
   save, dmm_param, dmm_grid, kidpar_copy, file=param.output_dir+"/dmm.save"

;   save, toi, dra, ddec, flag, param, info, kidpar, grid, astr, $
;         file=param.output_dir+"/dmm.save"
   delvarx, toi, dra, ddec, flag
endif

;; message, /info, "FIX ME:"
;; print, "project map of snr_toi and 1/(1+k_snr*snr^2)"
;; data.toi = snr_toi
;; data.w8 = 1.
;; nk_projection_4, param, info, data, kidpar, grid
;; wind, 1, 1, /free, /large
;; my_multiplot, 2, 2, pp, pp1, /rev
;; dp = {noerase:1, imrange:[0,5], coltable:39}
;; imview, grid.map_i_1mm, dp=dp, title='SNR 1mm', position=pp1[0,*]
;; imview, grid.map_i2,    dp=dp, title='SNR 2mm', position=pp1[1,*]
;; data.toi = 1.d0/(1.d0+param.k_snr_w8_decor*snr_toi^2)
;; nk_projection_4, param, info, data, kidpar, grid
;; dp.imrange=[0,1]
;; imview, grid.map_i_1mm, dp=dp, title='Decor w8 1mm', position=pp1[2,*]
;; imview, grid.map_i2,    dp=dp, title='Decor w8 2mm', position=pp1[3,*]
;; stop

if param.ignore_mask_for_decorr eq 1 then begin
   if param.log then nk_log, info, "forcing data.off_source to 1 because param.ignore_mask_for_decorr=1"
   data.off_source = 1
endif 

;; Interpol sources and flags on the whole timeline to avoid problems
;; on subscan edges when the KID is on-source or the anomalous speed
;; flag screws up the inteprolation.
if param.edge_source_interpol gt 0 then begin
   @edge_source_interpol.pro
endif 


;;-----------------------------------------------------------------------------------------------------------
;@check_kid_vs_cm.pro
;stop

;; @check_kid_plots.pro
;; xyouts, 0.03, 0.2, 'Before clean_data_4', orient=90, /norm, chars=1.5
;; stop

;; wind, 1, 1, /free, /large
;; my_multiplot, 1, 3, pp, pp1, /rev
;; delvarx, xra
;; xra = [0,1500]
;; for iarray=1, 3 do begin
;;    ikid = where( kidpar.numdet eq !nika.ref_det[iarray-1])
;;    w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;;    toi = data.toi[w1]
;;    for i=0, nw1-1 do toi[i,*] -= median(toi[i,*])
;;    make_ct, nw1, ct
;;    yra = array2range( toi)
;;    plot, toi[0,*], /xs, xra=xra, position=pp1[iarray-1,*], /noerase, yra=yra
;;    for i=0, nw1-1 do oplot, toi[i,*], col=ct[i]
;;    plot, data.subscan, /xs, col=70, xra=xra, position=pp1[iarray-1,*], /noerase, charsize=1d-10
;; endfor
;; stop

;; Estimation of out_temp_data
case param.clean_data_version of
   0: begin
      message, /info, "Skipping nk_clean_data_X"
      if defined(out_temp_data) eq 0 then begin
         out_temp_data = create_struct( "toi", data[0].toi*0.d0)
         nsn = n_elements(data)
         out_temp_data = replicate( out_temp_data, nsn)
      endif
   end
   3: nk_clean_data_3, param, info, data, kidpar, out_temp_data=out_temp_data
   ;; @ {\tt nk_clean_data_3} decorrelates only, no more filter to
   ;; allow iterative map making
   4: nk_clean_data_4, param, info, data, kidpar, grid, $
                       out_temp_data=out_temp_data, out_coeffs=out_coeffs, $
                       snr_toi=snr_toi, hfnoise_w8=hfnoise_w8, datasub = datasub
   5:begin
      param.decor_method = 'ring_median'
      nk_clean_data_4, param, info, data, kidpar, grid, $
                       out_temp_data=out_temp_data, out_coeffs=out_coeffs, $
                       snr_toi=snr_toi, hfnoise_w8=hfnoise_w8
   end

   else: message, /info, "Wrong value of param.clean_data_version: "+strtrim(param.clean_data_version,2)
endcase 


;; wind, 1, 1, /free, /large
;; my_multiplot, 1, 3, pp, pp1, /rev
;; delvarx, xra
;; xra = [0,1500]
;; for iarray=1, 3 do begin
;;    ikid = where( kidpar.numdet eq !nika.ref_det[iarray-1])
;;    plot, data.toi[ikid], /xs, xra=xra, position=pp1[iarray-1,*], /noerase
;;    plot, data.subscan, /xs, col=70, xra=xra, position=pp1[iarray-1,*], /noerase
;; endfor
;; stop
;; 
;; if param.mydebug then begin
;;    
;;    x0 = -120
;;    y0 =  40
;;    iarray=1
;;    w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;;    on_zone = dblarr( n_elements(data))
;;    nppw = 5
;;    my_multiplot, 1, nppw, /rev, pp, pp1, gap_y=0.02
;;    myp = 0
;;    yra = [-1,1]                 ; 2,2] ; array2range( data.toi[w1])
;;    for i=0, nw1-1 do begin
;;       ikid = w1[i]
;;       ww = where( sqrt( (data.dra[ikid]-x0)^2 + (data.ddec[ikid]-y0)^2) le 20, nww)
;;       if nww ne 0 then begin
;;          
;;          if (myp mod nppw) eq 0 then wind, 1, 1, /free, /large
;;          on_zone[ww] = 1
;;          plot, data.toi[ikid], /xs, /ys, position=pp1[myp mod nppw,*], $
;;                /noerase, yra=yra ;, xra=array2range(ww)
;;          oplot, ww, data[ww].toi[ikid], psym=1, col=250
;;          legendastro, strtrim(ikid,2)
;;          myp++
;;       endif
;;    endfor
;; ;   stop
;;    
;;    plot, atm_cm1, /xs
;;    w = where( on_zone eq 1, nw)
;;    if nw eq 0 then begin
;;       message, /info, "pb with on_zone"
;;    endif else begin
;;       oplot, w, atm_cm1[w], psym=1, col=250
;;    endelse
;;    
;;    stop
;; endif

if param.g2_paper then begin
   @post_decor_corr_mat.pro
;; wind, 1, 1, /f, /large
;; my_multiplot, 2, 2, pp, pp1, /rev
;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;;    if nw1 ne 0 then begin
;;       nk_get_median_common_mode, param, info, data.toi[w1], data.flag[w1], $
;;                                  data.off_source[w1], kidpar[w1], median_common_mode
;; 
;;       plot, data.toi[w1[0]], /xs, yra=array2range(data.toi[w1]), title='Array '+strtrim(iarray,2), $
;;             position=pp1[iarray-1,*], /noerase
;;       make_ct, nw1, ct
;;       for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]
;;       oplot, median_common_mode, col=0, thick=2
;;    endif
;; endfor
;; stop
endif 



;@check_kid_plots.pro
;xyouts, 0.03, 0.2, 'after clean_data_4', orient=90, /norm, chars=1.5
;stop

;if param.mydebug eq 1 then begin
;   wshet, debug_window
;   my_y2 = out_temp_data.toi[myikid]
;   ws = where( data.subscan-shift(data.subscan,1) eq 1, nws)
;   my_multiplot, 1, 3, pp, pp1, /rev
;   plot, index, my_y_raw, /xs, /ys, position=pp1[0,*]
;   oplot, index, my_y1, col=70
;   oplot, index, my_y2, col=250
;   for is=0, nws-1 do oplot, [1,1]*ws[is], [-1,1]*1d10, col=100
;   legendastro, [strtrim(myikid,2), $
;                 'Raw toi', 'Raw toi -Imap', 'Out temp'], col=[0,0,70,250]
;
;   plot, index, my_y_raw-my_y2, /xs, /ys, position=pp1[1,*], /noerase
;   for is=0, nws-1 do oplot, [1,1]*ws[is], [-1,1]*1d10, col=100
;   legendastro, [strtrim(myikid,2), $
;                 'Raw toi - Out temp'], col=[0,0]
;
;   plot, index, data.toi[myikid], /xs, /ys, position=pp1[2,*], /noerase
;;;   plot, index, my_y2, /xs, /ys, position=pp1[2,*], /noerase
;   for is=0, nws-1 do oplot, [1,1]*ws[is], [-1,1]*1d10, col=100
;   legendastro, [strtrim(myikid,2), $
;                 'data.toi'], col=[0,0]
;endif

if param.flex_polynomial then begin
   param.polynomial = round( info.subscan_arcsec/(377.6/3))
;   if param.method_num eq 607 then begin
;      message, /info, "param.polynomial = "+strtrim( param.polynomial, 2)
;      stop
;   endif
endif
if param.polynomial ne 0 and param.polynomial_on_residual eq 1 then begin
   @subtract_polynomials_on_residuals.pro
endif

if info.polar and param.simul_atmosphere_leakage then begin
   @polar_simul_atmosphere_leakage.pro
endif 

;; @ Derive projection weights here on the residual timelines
;; Need to make sure that bright sources are accounted for (masked) in
;; data.off_source before calling nk_w8, otherwise weights are biased
;; by strong sources.
;; updating data.off_source with grid.mask_source_Xmm
nk_mask_source, param, info, data, kidpar, grid
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 25/03/2021
; Emmanuel & Laurence
; data.toi = residuals
; original TOI copied in original_toi at l.358 if needed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; For method 120, data.toi contains the cleanest (noise only) part of
;; the toi so do nothing .

;if param.method_num ne 120 then begin
;   residual_toi = data.toi - out_temp_data.toi
;   mytoi = data.toi ; back up data.toi
   ;data.toi = residual_toi ; for nk_w8 
;endif

;; w1 = where( kidpar.type eq 1, nw1)
;; delvarx, xra ; xra = [0,1000]
;; wind, 1, 1, /f
;; my_multiplot, 1, 2, pp, pp1, /rev
;; plot, data.toi[w1[0]], /xs, position=pp1[0,*], xra=xra
;; plot, data.subscan, /xs, position=pp1[1,*], xra=xra, /noerase
;; stop

nk_w8, param, info, data, kidpar

;if param.method_num ne 120 then begin
;   ;; restore data.toi
;   data.toi = mytoi
;   delvarx, mytoi, residual_toi
;endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;END MODIF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if param.subscan_edge_w8 gt 0 then data.w8 *= hfnoise_w8

if param.fourier_lf_freqmax gt 0.d0 then begin
;   @fourier_lf_freqmax.pro
   nsn = n_elements(data)
   w1 = where( kidpar.type eq 1, nw1)
   lf_modes = dblarr(nw1,nsn)
   nsmooth = !nika.f_sampling

   if param.log then nk_log, info, "udpate data.off_source with nk_mask_source (grid.mask_source_Xmm)"
   nk_mask_source, param, info, data, kidpar, grid

   ;; init filter
   np_bandpass, dblarr(nsn), !nika.f_sampling, junk, filter=filter, $
                freqlow=0.d0, freqhigh=param.fourier_lf_freqmax
   
   plot_done = 0
   index = lindgen(nsn)
   for i=0, nw1-1 do begin
      ikid = w1[i]

      toi2 = data.toi[ikid]     ; data.toi = residuals, here, the input map has been subtracted (where mask_source eq 0 only !)
      whole = where( data.off_source[ikid] eq 0 or data.flag[ikid] ne 0, nwhole, compl=wgood, ncompl=nwgood)
      ;; interpol holes if any
      if nwhole ne 0 then begin
         if param.log then nk_log, info, "interpolate mask holes"
         toi_interp = interpol( data[wgood].toi[ikid], index[wgood], index)
         toi_sm = smooth( toi_interp, nsmooth)
         toi_interp = interpol( toi_sm[wgood], index[wgood], index)
         sigma = stddev( data[wgood].toi[ikid]-toi_interp[wgood])
         toi2[whole] = toi_interp[whole] + randomn( seed, nwhole)*sigma
      endif

      ;; apply filter to derive lf_comp
      baseline = my_baseline(toi2, base_frac=0.01)
      if param.log then nk_log, info, "Fourier filter"
      np_bandpass, toi2 - baseline, !nika.f_sampling, lf_comp, filter=filter
      lf_modes[i,*] = baseline + lf_comp
   endfor
endif

;; @ Now subtract the common modes from the raw input timelines
if strupcase(param.decor_method) eq "FOURIER" then begin
   nk_bandpass_filter, param, info, data, kidpar
endif else begin
   ;;;(original_toi is the initial untouched toi)
   data.toi = original_toi - out_temp_data.toi
   ;; data.toi contains the initial toi minus all the nuisance
   ;; templates obtained by decorrelation
   if defined(out_temp_atm) then data.toi -= out_temp_atm
endelse

;; subtract the extra individual LF component if available
if defined( lf_modes) then begin
   w1 = where(kidpar.type eq 1, nw1)
   data.toi[w1] -= lf_modes
endif

if param.extra_nsmooth gt 0 then begin
   @extra_nsmooth.pro
endif

if info.polar eq 1 and param.decor_qu eq 1 then begin
   ;; 1. defined out_temp_data_p to preserve "out_temp_data" for weather
   ;; monitoring below
   ;; 2. use the intensity snr_toi in case atm_iter...SNR_w8
   ;; decorrelation
   toi_q_copy = data.toi_q
   if param.subtract_qu_maps then nk_subtract_maps_from_toi, param, info, data, kidpar, grid, subtract_maps, /Q
   nk_clean_data_4, param, info, data, kidpar, grid, $
                    out_temp_data=out_temp_data_p, out_coeffs=out_coeffs, $
                    snr_toi=snr_toi, /Q, $
                    hfnoise_w8=hfnoise_w8
   data.toi_q = toi_q_copy - out_temp_data_p.toi

   toi_u_copy = data.toi_u
   if param.subtract_qu_maps then nk_subtract_maps_from_toi, param, info, data, kidpar, grid, subtract_maps, /U
   nk_clean_data_4, param, info, data, kidpar, grid, $
                    out_temp_data=out_temp_data_p, out_coeffs=out_coeffs, $
                    snr_toi=snr_toi, /U, $
                    hfnoise_w8=hfnoise_w8
   data.toi_u = toi_u_copy - out_temp_data_p.toi
   delvarx, toi_q_copy, toi_u_copy, out_temp_data_p ; save memory
endif

if param.post_wiener  ne 0 then nk_wiener_filter, param, info, data, kidpar
if param.notch_filter ne 0 then nk_notch_filter, param, info, data, kidpar

;; data_copy = data
if param.bandpass ne 0 then nk_bandpass_filter, param, info, data, kidpar

;; w1 = where( kidpar.type eq 1 and kidpar.array eq 1, nw1)
;; i = 0
;; ikid = w1[i]
;; wind, 1, 1, /free, /large
;; my_multiplot, 1, 2, pp, pp1
;; plot, data_copy.toi[ikid], /xs, /ys, position=pp1[0,*]
;; oplot, data.toi[ikid], col=250
;; power_spec, data_copy.toi[ikid]-my_baseline(data_copy.toi[ikid], base=0.01), !nika.f_sampling, pw, freq
;; power_spec, data.toi[ikid] - my_baseline(data.toi[ikid], base=0.01), !nika.f_sampling, pw1, freq
;; plot_oo, freq, pw, /xs, /ys, position=pp1[1,*], /noerase
;; oplot, freq, pw1, col=250
;; stop


if param.off_source_fourier ne 0 and defined(subtract_maps) then begin
   kernel = dblarr(20,20) + 1.d0
   kernel /= total(kernel)
   grid.mask_source_1mm = 1.d0 - double( convol( subtract_maps.iter_mask_1mm, kernel) gt 0.d0)
   grid.mask_source_2mm = 1.d0 - double( convol( subtract_maps.iter_mask_2mm, kernel) gt 0.d0)
   if param.debug ne 0 then begin
      wind, 1, 1, /free
      imview, subtract_maps.iter_mask_2mm
      wind, 2, 2, /free
      imview, convol( subtract_maps.iter_mask_2mm, kernel)
   endif
   if param.log then nk_log, info, "off_source_fourier ne 0 and defined(subtract_maps)"
   nk_mask_source, param, info, data, kidpar, grid
   nk_off_source_fourier, param, info, data, kidpar
endif

;; Now that the "common_mode" has been subtracted, If requested, we
;; can perform additional filtering
;; if param.fourier_subtract ne 0 then nk_fourier_subtract, param,
;; info, data, kidpar, grid, subtract_maps

if param.polynomial ne 0 and param.polynomial_on_residual eq 0 then begin
   @subtract_polynomials_on_tois.pro
endif

;if param.mydebug eq 1 then begin
;   wshet, debug_window
;   ws = where( data.subscan-shift(data.subscan,1) eq 1, nws)
;   my_multiplot, 1, 3, pp, pp1, /rev
;   plot, index, my_y_raw, /xs, /ys, position=pp1[0,*]
;   oplot, index, my_y1, col=70
;   oplot, index, my_y2, col=250
;   for is=0, nws-1 do oplot, [1,1]*ws[is], [-1,1]*1d10, col=100
;   legendastro, [strtrim(myikid,2), $
;                 'Raw toi', 'Raw toi -Imap', 'Out temp'], col=[0,0,70,250]
;
;   plot, index, toi1[myikid,*], /xs, /ys, position=pp1[1,*], /noerase
;   oplot, index, (toi1-data.toi)[myikid,*], col=250
;   for is=0, nws-1 do oplot, [1,1]*ws[is], [-1,1]*1d10, col=100
;   legendastro, [strtrim(myikid,2), $
;                 'Raw toi - Out temp', 'poly'], col=[0,0,250]
;
;   plot, index, data.toi[myikid], /xs, /ys, position=pp1[2,*], /noerase
;   for is=0, nws-1 do oplot, [1,1]*ws[is], [-1,1]*1d10, col=100
;   legendastro, [strtrim(myikid,2), $
;                 'TOI'], col=[0,0]
;endif

if param.lf_sin_fit_n_harmonics eq 1 then nk_lf_sin_fit_2, param, info, data, kidpar
if param.sim_fit_toi            eq 1 then nk_fit_sim_toi, param, info, data, kidpar
if param.twin_noise_toi         eq 1 then nk_twin_noise_toi, param, info, data, kidpar
if param.force_white_noise      eq 1 then nk_force_white_noise, param, info, data, kidpar

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
;;      if strupcase(param.decor_method) ne "NONE" then begin
      if defined(out_temp_data) then begin
         cm_toi = out_temp_data.toi[w1]*calib
      endif else begin
         cm_toi = data.toi[w1]*calib
      endelse
                                ; This subroutine modifies kidpar. So
                                ; keep it quiet and do not print
      paramaux = param
      paramaux.silent = 1
      kidaux = kidpar[w1]
      nk_get_cm_sub_2, paramaux, info, cm_toi, data.flag[w1], $
                       data.off_source[w1], kidaux, common_mode
      all_common_modes[*,iarray-1] = common_mode
   endif
endfor
;; Correlation
fit = linfit( all_common_modes[*,0], all_common_modes[*,1])
info.A2_TO_A1_CM_CORR = fit[1]
fit = linfit( all_common_modes[*,2], all_common_modes[*,1])
info.A2_TO_A3_CM_CORR = fit[1]
;;--------------------------

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

;; Assess scan quality based on atmosphere and decorrelation
nk_scan_quality_monitor, param, info, data, kidpar, out_temp_data

;; The zero levels and weights must be computed on the background, hence not
;; include bright sources.
if param.log then nk_log, info, "Update data.off_source via nk_mask_source"
nk_mask_source, param, info, data, kidpar, grid

;; @ Compute zero levels per subscan or per full scan

;; myp++
;; print, "myp: "+strtrim(myp,2)
;; w1 = where( kidpar.type eq 1, nw1)
;; print, "nw1: "+strtrim(nw1,2)
;; myw = where( finite(data.toi[w1]) ne 1, nmyw)
;; print, "Infinite values in data.toi[w1]: "+strtrim(nmyw,2)
;; 
;; save, file='data.save'
;; stop


if param.iterative_offsets eq 1 then begin
   nk_iterative_offsets, param, info, data, kidpar, subtract_maps
endif else begin
   if param.set_zero_level_full_scan ne 0 or $
      param.set_zero_level_per_subscan ne 0 then begin
      nk_set0level_2, param, info, data, kidpar
   endif else begin
      if param.log then nk_log, info, "No zero level per KID timeline is derived"
   endelse
endelse

;; @ Compute inverse variance weights for TOIs (for future projection)
;; $^ where data.off_source=1
;; already done above either on the residual timelines, hence no
;; polluted by signal.
;; if not keyword_set(subtract_maps) then nk_w8, param, info, data, kidpar

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

;; Determine observation time and store info
info.result_total_obs_time = n_elements(data)/!nika.f_sampling

if param.cpu_time then nk_show_cpu_time, param

end  
