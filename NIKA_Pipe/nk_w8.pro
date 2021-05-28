;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_w8
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_w8, param, info, data, kidpar
; 
; PURPOSE: 
;        Derives optimal noise weighting for timelines
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data: data.w8 is modified
; 
; KEYWORDS: param.w8_per_subscan
;         0: toi weight per scan
;         1: toi weight per subscan
;         2: toi weight per scan, evaluated as median of noise per subscan
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 08th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;        - 25/11/2016: removed loops on detectors (HR)
;          June 2020: add a third option (FXD) which may be more
;robust, take the median average of the noise per subscan to apply
;that to a Kid for the whole scan (#2)
; #3, made by NP Clipping bad and too good subscans
; #4, FXD, max( the subscan noise, the median average over all
;subscans) in order to weigh down bad subscans (bad wrt the median average)
; #5 FXD, allow for excess noise to be taken into account, correct the
;signal from filtering (only the low signal to noise signal is
;corrected here in the IMCM scheme)

pro nk_w8, param, info, data, kidpar
;-

  if n_params() lt 1 then begin
     dl_unix, 'nk_w8'
     return
  endif

  if info.status eq 1 then begin
     if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
     return
  endif

  if param.do_w8 eq 0 then return

  if param.cpu_time then param.cpu_t0 = systime(0, /sec)

  w1 = where( kidpar.type eq 1, nw1)
  if nw1 eq 0 then begin
     nk_error, info, "No valid kids"
     return
  endif
  pex = param.atmb_exclude > 2. ; exclude kids according to noise above that times the median noise, should be at least 2., default is 3. (only used with method 5)

;; Re-init w8 to zero to avoid samples with weight 1 as set by default and not
;; updated if their flag is not zero...
;; If the user does not want to apply any w8, we have already exited the routine
;; with param.do_w8 = 0 anyway.
  data.w8 = 0.d0

  off_source = data.off_source
  nsn = n_elements(data)
  toi = data.toi
  flag = data.flag
  if info.polar ne 0 then begin
     toi_q = data.toi_q
     toi_u = data.toi_u
  endif

case param.w8_per_subscan of
   ;;-----------------------------------------------------------------------------------
   ;; One weight per full scan
   0: begin
      if param.log then nk_log, info, "Derive projection toi weights on the entire scan"
      
      w = where( off_source eq 0, nw)
      if nw ne 0 then toi[w] = !values.d_nan
      std_toi = nk_stddev( toi, dim=2, /nan)
      
      if info.polar ne 0 then begin
         if nw ne 0 then begin
            toi_q[w] = !values.d_nan
            toi_u[w] = !values.d_nan
         endif
         std_toi_q = nk_stddev( toi_q, dim=2, /nan)
         std_toi_u = nk_stddev( toi_u, dim=2, /nan)
      endif

      wkid = where(kidpar.type eq 1 and finite(std_toi) gt 0 and std_toi gt 0., ckid)
      if ckid gt 0 then begin
         data.w8[wkid] = 1.D0 / rebin((std_toi(wkid))^2.D0, ckid, nsn)
         if info.polar ne 0 then begin
            w = where(std_toi_q(wkid) gt 0., cw)
            if cw gt 0 then data.w8_q[wkid(w)] = $
               1.D0 / rebin((std_toi_q(wkid(w)))^2.D0, cw, nsn)
            w = where(std_toi_u(wkid) gt 0., cw)
            if cw gt 0 then data.w8_u[wkid(w)] = $
               1.D0 / rebin((std_toi_u(wkid(w)))^2.D0, cw, nsn)
         endif
      endif
   end
   
   ;;-----------------------------------------------------------------------------------
   ;; one weight per subscan
   1:  begin
      if param.log then nk_log, info, "Derive projection toi weights per subscan"
      for isubscan=min(data.subscan), max(data.subscan) do begin
         wsubscan = where( data.subscan eq isubscan, nwsubscan)
         if nwsubscan eq 0 then begin
            nk_error, info, "subscan "+strtrim(isubscan,2)+" is empty"
            return
         endif

           toi1        = toi[       *,wsubscan]
           off_source1 = off_source[*,wsubscan]
           w           = where( off_source1 eq 0, nw)
           if nw ne 0 then toi1[w] = !values.d_nan
           std_toi = nk_stddev( toi1, dim=2, /nan)

           if info.polar ne 0 then begin
              toi_q1 = toi_q[*,wsubscan]
              toi_u1 = toi_u[*,wsubscan]
              if nw ne 0 then begin
                 toi_q1[w] = !values.d_nan
                 toi_u1[w] = !values.d_nan
              endif
              std_toi_q = nk_stddev( toi_q1, dim=2, /nan)
              std_toi_u = nk_stddev( toi_u1, dim=2, /nan)
           endif

           wkid = where(kidpar.type eq 1 and finite(std_toi) gt 0 and std_toi gt 0., ckid)
           if ckid gt 0 then begin
              data[wsubscan].w8[wkid] = 1.D0 / rebin((std_toi(wkid))^2.D0, ckid, nwsubscan)
              if info.polar ne 0 then begin
                 w = where(std_toi_q(wkid) gt 0., cw)
                 if cw gt 0 then data[wsubscan].w8_q[wkid(w)] = $
                    1.D0 / rebin((std_toi_q(wkid(w)))^2.D0, cw, nwsubscan)
                 w = where(std_toi_u(wkid) gt 0., cw)
                 if cw gt 0 then data[wsubscan].w8_u[wkid(w)] = $
                    1.D0 / rebin((std_toi_u(wkid(w)))^2.D0, cw, nwsubscan)
              endif
           endif
        endfor                  ; subscan
     end

     ;;-----------------------------------------------------------------------------------
     ;; FXD determine the noise per subscan
     ;; but make it constant over the scan by taking the median average
     2: begin                     
        if param.log then nk_log, info, "Derive projection toi weights per subscan and median that over the scan"
        misub = min(data.subscan)
        masub = max(data.subscan)
        ndet = n_elements( toi[*, 0])
        noisub   = dblarr( ndet, masub+1)+!values.d_nan ; nan is default
        noisub_q = dblarr( ndet, masub+1)+!values.d_nan
        noisub_u = dblarr( ndet, masub+1)+!values.d_nan
        for isubscan=misub,masub  do begin
           wsubscan = where( data.subscan eq isubscan, nwsubscan)
           if nwsubscan eq 0 then begin
              nk_error, info, "subscan "+strtrim(isubscan,2)+" is empty"
              return
           endif
           
           toi1        = toi[       *,wsubscan]
           off_source1 = off_source[*,wsubscan]
           w           = where( off_source1 eq 0, nw)
           if nw ne 0 then toi1[w] = !values.d_nan
           noisub[ *, isubscan]= nk_stddev( toi1, dim=2, /nan)
           
           if info.polar ne 0 then begin
              toi_q1 = toi_q[*,wsubscan]
              toi_u1 = toi_u[*,wsubscan]
              if nw ne 0 then begin
                 toi_q1[w] = !values.d_nan
                 toi_u1[w] = !values.d_nan
              endif
              noisub_q[ *, isubscan] = nk_stddev( toi_q1, dim=2, /nan)
              noisub_u[ *, isubscan] = nk_stddev( toi_u1, dim=2, /nan)
           endif
        endfor
                                ; now take the median of subscan noise values across all subscans
        std_toi = nk_median( noisub, dim = 2)
        wkid = where(kidpar.type eq 1 and finite(std_toi) gt 0 and std_toi gt 0., ckid)
        if ckid gt 0 then begin
           data.w8[wkid] = 1.D0 / rebin((std_toi(wkid))^2.D0, ckid, nsn)
           if info.polar ne 0 then begin
              std_toi_q = nk_median( noisub_q, dim = 2)
              std_toi_u = nk_median( noisub_u, dim = 2)
              w = where(std_toi_q(wkid) gt 0., cw)
              if cw gt 0 then data.w8_q[wkid(w)] = $
                 1.D0 / rebin((std_toi_q(wkid(w)))^2.D0, cw, nsn)
              w = where(std_toi_u(wkid) gt 0., cw)
              if cw gt 0 then data.w8_u[wkid(w)] = $
                 1.D0 / rebin((std_toi_u(wkid(w)))^2.D0, cw, nsn)
           endif
        endif      
     end

     ;;-----------------------------------------------------------------------------------
     ;; one weight per subscan (exact copy and paste of case=1)
     ;; 
     ;; Then discard outliers from the median noise, either "skinny"
     ;; subscans or noisy ones
     3:  begin
        if param.log then nk_log, info, "Derive projection toi weights per subscan"
        for isubscan=min(data.subscan), max(data.subscan) do begin

           
           wsubscan = where( data.subscan eq isubscan, nwsubscan)
           if nwsubscan eq 0 then begin
              nk_error, info, "subscan "+strtrim(isubscan,2)+" is empty"
              return
           endif

           toi1        = toi[       *,wsubscan]
           off_source1 = off_source[*,wsubscan]
           w           = where( off_source1 eq 0, nw)
           if nw ne 0 then toi1[w] = !values.d_nan
           std_toi = nk_stddev( toi1, dim=2, /nan)

           
           if info.polar ne 0 then begin
              toi_q1 = toi_q[*,wsubscan]
              toi_u1 = toi_u[*,wsubscan]
              if nw ne 0 then begin
                 toi_q1[w] = !values.d_nan
                 toi_u1[w] = !values.d_nan
              endif
              std_toi_q = nk_stddev( toi_q1, dim=2, /nan)
              std_toi_u = nk_stddev( toi_u1, dim=2, /nan)
           endif

           wkid = where(kidpar.type eq 1 and finite(std_toi) gt 0 and std_toi gt 0., ckid)
           if ckid gt 0 then begin
              data[wsubscan].w8[wkid] = 1.D0 / rebin((std_toi(wkid))^2.D0, ckid, nwsubscan)
              if info.polar ne 0 then begin
                 w = where(std_toi_q(wkid) gt 0., cw)
                 if cw gt 0 then data[wsubscan].w8_q[wkid(w)] = $
                    1.D0 / rebin((std_toi_q(wkid(w)))^2.D0, cw, nwsubscan)
                 w = where(std_toi_u(wkid) gt 0., cw)
                 if cw gt 0 then data[wsubscan].w8_u[wkid(w)] = $
                    1.D0 / rebin((std_toi_u(wkid(w)))^2.D0, cw, nwsubscan)
              endif
           endif
        endfor                  ; subscan

        ;; Discard outlying subscans
        w1 = where(kidpar.type eq 1, nw1)
        if nw1 eq 0 then begin
           nk_error, info, "No valid kid ? param.w8_per_subscan=3"
           return
        endif
        for i=0, nw1-1 do begin
           ikid = w1[i]
           wok = where( data.flag[ikid] eq 0, nwok)
           if nwok ne 0 then begin
              m = median( data[wok].w8[ikid])
              w = where( abs( data.w8[ikid]-m) gt 3*stddev( data.w8[ikid]), nw)
              if nw ne 0 then data[w].flag[ikid] = 1
           endif
        endfor
     end

     ;;-----------------------------------------------------------------------------------
     ;; FXD determine the noise per subscan
     ;; but make it constant over the scan by taking the median average
     ;; then take the max( the subscan noise, this median average)
     4: begin                     
        if param.log then nk_log, info, "Derive projection toi weights per subscan "+$
                                  "and median that over the scan, take the worst of the two per subscan"
        misub = min(data.subscan)
        masub = max(data.subscan)
        ndet = n_elements( toi[*, 0])
        noisub   = dblarr( ndet, masub+1)+!values.d_nan ; nan is default
        noisub_q = dblarr( ndet, masub+1)+!values.d_nan
        noisub_u = dblarr( ndet, masub+1)+!values.d_nan
        noisubsamp = dblarr( ndet, nsn) ; subscans noise resampled to the full sampling
        noisubsamp_q = dblarr( ndet, nsn) 
        noisubsamp_u = dblarr( ndet, nsn) 
        for isubscan=misub,masub  do begin
           wsubscan = where( data.subscan eq isubscan, nwsubscan)
           if nwsubscan eq 0 then begin
              nk_error, info, "subscan "+strtrim(isubscan,2)+" is empty"
              return
           endif
           
           toi1        = toi[       *,wsubscan]
           off_source1 = off_source[*,wsubscan]
           w           = where( off_source1 eq 0, nw)
           if nw ne 0 then toi1[w] = !values.d_nan
           noisub[ *, isubscan]= nk_stddev( toi1, dim=2, /nan)
           noisubsamp[ *, wsubscan] = noisub[ *,  isubscan] # replicate(1., nwsubscan)
           if info.polar ne 0 then begin
              toi_q1 = toi_q[*,wsubscan]
              toi_u1 = toi_u[*,wsubscan]
              if nw ne 0 then begin
                 toi_q1[w] = !values.d_nan
                 toi_u1[w] = !values.d_nan
              endif
              noisub_q[ *, isubscan] = nk_stddev( toi_q1, dim=2, /nan)
              noisub_u[ *, isubscan] = nk_stddev( toi_u1, dim=2, /nan)
              noisubsamp_q[ *, wsubscan] = noisub_q[ *,  isubscan] # replicate(1., nwsubscan)
              noisubsamp_u[ *, wsubscan] = noisub_u[ *,  isubscan] # replicate(1., nwsubscan)
           endif
        endfor
                                ; now take the median of subscan noise values across all subscans
        std_toi = nk_median( noisub, dim = 2)
        wkid = where(kidpar.type eq 1 and finite(std_toi) gt 0 and std_toi gt 0., ckid)
        if ckid gt 0 then begin
           data.w8[wkid] = 1.D0 / (rebin(std_toi[ wkid], ckid, nsn) > noisubsamp[wkid, *])^2
           if info.polar ne 0 then begin
              std_toi_q = nk_median( noisub_q, dim = 2)
              std_toi_u = nk_median( noisub_u, dim = 2)
              w = where(std_toi_q(wkid) gt 0., cw)
              if cw gt 0 then data.w8_q[wkid[w]] = $
                 1.D0 / (rebin(std_toi_q[ wkid[w]], cw, nsn) > noisubsamp_q[ wkid[w], *])^2
              w = where(std_toi_u(wkid) gt 0., cw)
              if cw gt 0 then data.w8_u[wkid(w)] = $
                 1.D0 / (rebin(std_toi_u[ wkid[w]], cw, nsn) > noisubsamp_u[ wkid[w], *])^2
           endif
        endif      
     end
; end of case 4
; Case 5, same as case 4 but allow for beginning of subscan excess noise to
; be taken into account in a multiplicative way
                                ; 9 dec 2020, FXD: do the hfnoise first to
                                ; compute the true noise (away from
                                ; subscan beginning), improve on noise
                                ; by using flagging extensively
     ; Correct the signal if requested (param.noiseup)
     5: begin                     
        if param.log then nk_log, info, "Derive projection toi weights " + $
                                  "per subscan and median that over the scan, " + $
                                  "take the worst of the two per subscan"
        misub = min(data.subscan)
        masub = max(data.subscan)
        ndet = n_elements( toi[*, 0])
        noisub   = dblarr( ndet, masub+1)+!values.d_nan ; nan is default
        noisub_q = dblarr( ndet, masub+1)+!values.d_nan
        noisub_u = dblarr( ndet, masub+1)+!values.d_nan
        noisubsamp = dblarr( ndet, nsn) ; subscans noise resampled to the full sampling
        noisubsamp_q = dblarr( ndet, nsn) 
        noisubsamp_u = dblarr( ndet, nsn)
; 0th step
                                ; correct the TOI signal
        for iarray = 1, 3 do begin
           wkid = where( kidpar.type eq 1 and kidpar.array eq iarray , ckid)
           Np = nk_atmb_count_param( info,  param, iarray) ; 1 or 2mm
           if iarray eq 2 then Nsa = info.subscan_arcsec/!nika.fwhm_nom[1] else $
              Nsa = info.subscan_arcsec/!nika.fwhm_nom[0] 
; number of beams in a subscan
;           sigup = (1./(1.-(1.505*Np)/Nsa))
; accounts for the filtering effect (no square root),
                                ; 1.505 is theoretically justified but
                                ; an approximation if sigup is larger
                                ; than 2.
;;; Only approximate           sigup = exp((1.505*Np)/Nsa)  ; allows
;;; to go to large values (without going negative)
           Nsub_sa = info.subscan_arcsec/info.median_scan_speed* $
                           !nika.f_sampling          ; a median subscan in samples
                                ; New (more accurate) method, FXD, 28 Apr 2021
           ; (Np-1)/2 is better than param.nharm_subscan2mm
           if iarray eq 2 then $
              sigd = nk_atmb_harm_filter(Nsub_sa, info.subscan_arcsec/Nsub_sa, $
                                      !nika.fwhm_nom[1], (Np-1)/2., /k1d) else $
              sigd = nk_atmb_harm_filter(Nsub_sa, info.subscan_arcsec/Nsub_sa, $
                                        !nika.fwhm_nom[0], (Np-1)/2., /k1d)
           if sigd ne 0. then sigup = 1./sigd else begin
              sigup = 1.
              message, /info, 'Warning: the correction could not be done '+ $
                       string(sigd)+' '+ param.scan + ' '+ strtrim( param.imcm_iter, 2)
           endelse
           if param.method_num eq 120 and keyword_set( param.noiseup) $
              and ckid gt 0 then begin
;              print, 'nk_w8 warning: Sigup = ', sigup,
;              ' for array ', strtrim(iarray, 2), ' ', param.scan
              toi[wkid, *] = toi[wkid, *] * sigup
           endif
        endfor
        
; First step
; Compute the noise in the unflagged area
        std_toi = nk_stddev( toi, flag = flag, dim=2, /nan)
        data.w8 = 1D0           ; to start with
        nsm = round( !nika.f_sampling / param.lf_hf_freq_delim * 1.9) 
; 11 for intensity, smoothing used in the hf noise evaluation
        
        for iarray = 1, 3 do begin
           wkid = where( kidpar.type eq 1 and kidpar.array eq iarray $
                         and finite(std_toi) gt 0, ckid)
           if ckid gt 0 then begin
              noi_out = std_toi[ wkid]
              goodkid = replicate( 1D0, ckid)
              bad = where( noi_out gt pex*nk_median( noi_out) or $
                           noi_out lt 0.5 *nk_median( noi_out) or $
                           (1-finite(noi_out)) or $
                           total( flag[ wkid, *], 2) eq nsn, nbad)
              if nbad ne 0 then begin
                 goodkid[ bad] = 0.
                 data.w8[ wkid[ bad]] = 0.
              endif
              if total( goodkid) gt 0 then begin
                 hfnoise = nk_hf_noise( toi[ wkid[ where( goodkid)],  *], nsm = nsm) >0.7
; Apply that hfnoise to all kids (not just the good ones)
                 data.w8[ wkid] = data.w8[ wkid] / $
                                  (replicate(1D0, ckid)#(hfnoise^2)) ; weigh down noisy samples across the array
              endif                                                  ; end case of enough good kids
           endif                                                     ; end case of enough kids of that array
        endfor                                                       ; end loop on arrays
                                ; At this stage,
                                ; w8 contains just the variable part
                                ; of the noise, but we are around 1
; Second compute the noise per subscan
        for isubscan=misub,masub  do begin
           wsubscan = where( data.subscan eq isubscan, nwsubscan)
           if nwsubscan eq 0 then begin
              nk_error, info, "subscan "+strtrim(isubscan,2)+" is empty"
              return
           endif
           
           toi1        = toi[       *,wsubscan]
           off_source1 = off_source[*,wsubscan]
           w           = where( off_source1 eq 0, nw)
           if nw ne 0 then toi1[w] = !values.d_nan
                                ; we model toi1 as
                                ; sigma*hfnoise*randomn, noisub is
                                ; thus stddev of toi1/hfnoise
           noisub[ *, isubscan]= $
              nk_stddev( toi1 * sqrt(data[wsubscan].w8),  $
                         flag = flag[*, wsubscan], dim=2, /nan)
                                ; Measure the noise outside strong sources and on unflagged samples
           ;;OLD noisub[ *, isubscan]= $
           ;;    nk_stddev( toi1 * sqrt(data[wsubscan].w8)* $
           ;;               (flag[*, wsubscan] eq 0.), dim=2, /nan)* $
           ;;    sqrt( (nwsubscan-1) / total( (flag[*, wsubscan] eq 0.), 2)) 
           noisubsamp[ *, wsubscan] = $
              noisub[ *,  isubscan] # replicate(1., nwsubscan)
           if info.polar ne 0 then begin
              toi_q1 = toi_q[*,wsubscan]
              toi_u1 = toi_u[*,wsubscan]
              if nw ne 0 then begin
                 toi_q1[w] = !values.d_nan
                 toi_u1[w] = !values.d_nan
              endif
              noisub_q[ *, isubscan] = $
                 nk_stddev( toi_q1 * sqrt(data[wsubscan].w8),  $
                            flag = flag[*, wsubscan], dim=2, /nan)
              noisub_u[ *, isubscan] = $
                 nk_stddev( toi_u1 * sqrt(data[wsubscan].w8),  $
                            flag = flag[*, wsubscan], dim=2, /nan)
              noisubsamp_q[ *, wsubscan] = $
                 noisub_q[ *,  isubscan] # replicate(1., nwsubscan)
              noisubsamp_u[ *, wsubscan] = $
                 noisub_u[ *,  isubscan] # replicate(1., nwsubscan)
           endif
        endfor                  ; End loop on subscans


; now take the median of subscan noise values across all subscans
        std_toi = nk_median( noisub, dim = 2)
        wkid = where(kidpar.type eq 1 and finite(std_toi) gt 0 $
                     and std_toi gt 0., ckid)
        if ckid gt 0 then begin
                                ; we redefine the noise (hence
                                ; w8=1/sigma^2) as a constant, to
                                ; start with
                                ; sigma is larger if std_toi is larger than the median
           data.w8[wkid] = 1.D0 / $
                           (rebin(std_toi[ wkid], ckid, nsn) > $
                            noisubsamp[wkid, *])^2
           if info.polar ne 0 then begin
              std_toi_q = nk_median( noisub_q, dim = 2)
              std_toi_u = nk_median( noisub_u, dim = 2)
              w = where(std_toi_q(wkid) gt 0., cw)
              if cw gt 0 then data.w8_q[wkid[w]] = $
                 1.D0 / (rebin(std_toi_q[ wkid[w]], cw, nsn) > $
                         noisubsamp_q[ wkid[w], *])^2
              w = where(std_toi_u(wkid) gt 0., cw)
              if cw gt 0 then data.w8_u[wkid(w)] = $
                 1.D0 / (rebin(std_toi_u[ wkid[w]], cw, nsn) > $
                         noisubsamp_u[ wkid[w], *])^2
           endif
        endif
; Refine w8 (again but more accurately) by accounting for spike of
                                ; noise between subscans
; Final step
        for iarray = 1, 3 do begin
           wkid = where( kidpar.type eq 1 and kidpar.array eq iarray $
                         and finite(std_toi) gt 0 and std_toi gt 0., ckid)
           if ckid gt 0 then begin
              noi_out = std_toi[ wkid]
              goodkid = replicate( 1D0, ckid)
              bad = where( noi_out gt pex*nk_median( noi_out) or $
; need to cut anomalous low noise cases
                           noi_out lt 0.5 *nk_median( noi_out) or $
                           (1-finite(noi_out)) or $
                           total( flag[ wkid, *], 2) eq nsn, nbad)
              if nbad ne 0 then begin
                 goodkid[ bad] = 0.
                 data.w8[ wkid[ bad]] = 0.
              endif
              
              if total( goodkid) gt 0 then begin
                                ; Correct the signal by a factor
                                ; induced by the filtering so the
                                ; point-source calibration is correct
                 hfnoise = nk_hf_noise( toi[ wkid[ where( goodkid)],  *], nsm = nsm) >0.7
                 Nsub_sa = info.subscan_arcsec/info.median_scan_speed* $
                           !nika.f_sampling                    ; a median subscan in samples
                 Np = nk_atmb_count_param( info,  param, iarray) ; 1 or 2mm
; this is a correction to account for a reduced number of degrees of freedom,
; this correction is too big, one should take into account the full spectrum,
; not just the one filtered by the Gaussian:
                 ;; if param.method_num eq 120 and keyword_set( param.noiseup) then $
                 ;;    noiseup = (1./(1. - Np/Nsub_sa)) else $ ; applies to 1/sigma^2 , no square root
;                                          FXD Apr 1,2021: decided not
;                                          to apply noiseup as the
;                                          noise evaluation would
;                                          apply to unfiltered data
;                                          whereas here we need the
;                                          noise after filtering.
                 noiseup = 1.
;                 print, 'Noiseup = ', noiseup, ' for array ', iarray
                 data.w8[ wkid] = data.w8[ wkid] / noiseup/ $
                                  ( replicate(1D0, ckid)#(hfnoise^2)) ; weigh down noisy samples across the array
              endif                                                   ; end case of enough good kids
              
           endif                ; end case of enough kids of that array
        endfor                  ; end loop on arrays
     end                        ; end case 5 of adaptative noise w8

     
     else: message, 'This param.w8_per_subscan = '+ $
                    strtrim(param.w8_per_subscan,2)+' is not implemented'
  endcase


  if param.force_I_weight ne 0 then begin
     message, /info, "fix me: force equal weights in I, Q, U"
     data.w8_q = data.w8        ; * 2
     data.w8_u = data.w8        ; * 2
  endif

  if param.cpu_time then nk_show_cpu_time, param, "nk_w8"

end
