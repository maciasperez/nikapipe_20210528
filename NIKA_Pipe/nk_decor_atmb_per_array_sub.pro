pro nk_decor_atmb_per_array_sub, param, info, kidpar, toi, flag, $
                             off_source, elevation, $
                             toi_out, out_temp, $
                             snr_toi=snr_toi, subscan = subscan, $
                             subtoi = subtoi
  

; FXD May 2020, one atm per array, box and subbands are studied.
                                ; This routine is called in a loop by nk_decor_atmb_per_array
  ; Apr 2021: add the atmb_dualband option
;  if param.cpu_time then param.cpu_t0 = systime(0, /sec)
  pex = param.atmb_exclude > 2. ; exclude kids according to noise above that times the median noise, should be at least 2., default is 3.
  pex_intern = 2. ; used only here to avoid bad kids in decorrelation templates
  nsm = round( !nika.f_sampling/param.lf_hf_freq_delim*1.9) ; 11 for intensity, smoothing used in the hf noise evaluation
  nsn = n_elements( toi[0,*])
  nkids = n_elements(kidpar)
  toi_out  = dblarr(nkids,nsn)
  out_temp = dblarr(nkids,nsn)
  outc = dblarr(nkids)  ; Main correlation coefficient (used to eliminate bad kids)
  subscan_min = long( min( subscan))
  subscan_max = long( max( subscan))
  nsubscans =subscan_max - subscan_min + 1 
; It seems that sometimes the last subscan is a lot shorter
; Dump it if it is the case
  nsub = subscan_max+1
  subscan_len = lonarr( nsub)
  for isub = subscan_min, subscan_max do $
     subscan_len[ isub] =total( subscan eq isub)

  if param.flag_n_seconds_subscan_start ne 0 then $
     npts_flag = round( param.flag_n_seconds_subscan_start*!nika.f_sampling) $
  else npts_flag = 0.
  flsub = 1.5*!nika.f_sampling+npts_flag ; the flagged beginning of subscan
  badsub = where( (subscan_len-flsub) lt $
                  (median( subscan_len)-flsub)*2./3. and $
                  lindgen(nsub) ge 2 and $
                  lindgen(nsub) ge subscan_min and lindgen(nsub) le subscan_max, nbadsub)
; above or = 2, to have normal subscans

; Do something if it is the final subscan (too complicated otherwise)
  nwsubscan = 0                 ; default
  if nbadsub gt 0 then begin
     message, /info, 'Some subscans are short '+ info.scan
     stop
     if param.silent eq 0 then $
        print, 'Subscans ', strtrim( badsub, 2), $
               ' will be removed (if last one = '+ $
               strtrim( subscan_max, 2)+ '), with length of '+ $
               strtrim( subscan_len[ badsub])+' samples'
     if badsub[ nbadsub-1] eq subscan_max then begin
        wsubscan = where( subscan eq subscan_max, nwsubscan)
        if nwsubscan ne 0 then flag[*, wsubscan] = 1
        nsubscans = nsubscans-1
     endif
  endif
  flagin = flag  ; modify flag only in the final iteration


  kidloc = kidpar               ; dump place to avoid messing up kidpar
  kidout = kidpar  ; output kidpar for the end
  toi_no_atm = toi
;  twinarr = [0, 3, 1, 1]        ; Twin array to add a complementary atm template
  twinarr = [0, 3, 3, 1]        ; 1Apr2021 (3 is better for array2) Twin array to add a complementary atm template

  niter_atmb = (param.niter_atm_el_box_modes>1) ; at least one
  for iarray = 1, 3 do begin
     if iarray eq 2 then deg = param.polynom_subscan2mm $
       else deg = param.polynom_subscan1mm
                                ; initial value of polynomial degree
                                ; (might be decrease if fit is too
                                ; degenerate)
     if iarray eq 2 then nharm = param.nharm_subscan2mm $
       else nharm = param.nharm_subscan1mm
     if nharm gt 0 then deg = 0 ; retain a constant if harmonic option is chosen
     ;; FXD Jan 2021 remove the slope
     
     ;; if nharm gt 0 then deg = 1 ; retain a linear baseline if harmonic option is chosen.
     
     for iter_atmb = 0, niter_atmb-1   do begin
        warr = where( kidout.type eq 1 and kidout.array eq iarray, nwarr)
        if nwarr ne 0 then begin
           flag[ warr, *] = flagin[ warr, *]

;; 1. Estimate atmosphere
           if iter_atmb eq 0 then $
              noi_out = kidpar[ warr].noise else $
              noi_out = nk_stddev( toi_out[ warr, *], $
                                 flag = flag[ warr, *], dim=2, /nan)
                                ; Do here some natural elimination: if
                                ; noise is too large, kill the kid
           goodkid = replicate( 1D0, nwarr)
           if iter_atmb eq 0 then begin
              bad = where( noi_out gt pex_intern * nk_median( noi_out) or $
                           noi_out lt 0.5*nk_median( noi_out) or $
                           (1-finite(noi_out)) or $
                           total( flag[ warr, *], 2) eq nsn, nbad)
           endif else begin
              medoutc = median( outc[ warr])
           cdisp = stddev( outc[ warr], /nan)
           medoutc1 = medoutc- 10*cdisp
           medoutc2 = medoutc+ 10*cdisp
; this method (below) is too selective when atmb_nsubscan is employed
              ;; medoutc1 = 0.2*medoutc
              ;; medoutc2 = 10.*medoutc                 ; 5 is not enough for A1
              if strlen(param.simu_dir) ne 0 then begin ; simulation mode
                 medoutc1 = -1D20
                 medoutc2 = 1D20
              endif
              bad = where( (noi_out gt pex_intern * nk_median( noi_out)) or $
                           (noi_out lt 0.5*nk_median( noi_out)) or $
                           (1-finite(noi_out)) or $
                           (total( flag[ warr, *], 2) eq nsn) or $
                           (outc[ warr] gt medoutc2) or $
                           (outc[ warr] lt medoutc1), nbad)
           endelse
           
           if nbad ne 0 then goodkid[ bad] = 0.
           w8toi = (            kidpar[warr].noise^2/noi_out^2)# $
                (replicate(1D0, nsn)) ; will convert to natural weighing
                                ; by the noise in nk_get_cm_sub_2, weight for all kids
           w8good = (goodkid*kidpar[warr].noise^2/noi_out^2)# $
                    (replicate(1D0, nsn)) ; weight to obtain the templates
           if defined(snr_toi) then begin
              w8toi = w8toi/(1.d0 + param.k_snr_w8_decor * snr_toi[warr,*]^2)
              w8good = w8good/(1.d0 + param.k_snr_template * snr_toi[warr,*]^2)
           endif 
; Jan 2021: correct bug of k_snr not used (it meant k_snr was in
; effect=1 instead of 0.01 !!! From now on, role is assumed by
; k_snr_w8_decor
                                ; Jan 2021: it is important to weigh
                                ; down strong sources in the
                                ; decorrelation templates but this is
                                ; too costly for the TOI (noise
                                ; increasing) and not really necessary
                                ; w8good is for the determination of
                                ; the templates, w8toi
                                ; is for the decorrelation from the
                                ; template with k_snr_w8_decor that can be very small.
           ;; do not discard any flagged sample because intersubscan flagged data are still
      ;; valid to compute a common mode: keep those that are flagged only
           ;; based on anomalous pointing speed: 2L^11
           ;; this nk_get_cm_sub_2 comment does not seem valid (at
           ;; least for the 2mm where an increase of noise and spikes
           ;; is noticeable. So put that in the w8toi
           flaghere = flag[warr, *] ; do not change the real flag
           w8toi = w8toi*(flaghere eq 0 and off_source[warr, *] eq 1)
           w8good = w8good*(flaghere eq 0 and off_source[warr, *] eq 1)
           
                                ; Refine w8 by accounting for spike of
                                ; noise between subscans
           hfnoise = nk_hf_noise( toi[ warr,  *], nsm = nsm) >0.7
           w8toi = w8toi/( replicate(1D0, nwarr)#(hfnoise^2)) ; weigh down noisy
                                ; samples across the array
           w8good = w8good/( replicate(1D0, nwarr)#(hfnoise^2)) ; weigh down noisy
                                ; samples across the array for good kids
           kidloc[warr] = kidout[warr]
           nk_get_cm_sub_2, param, info, toi[warr,*], flaghere, $
                            off_source[warr,*], kidloc[warr], atm_cm, $
                            w8=w8good
           
           if nwsubscan ne 0 then atm_cm[ wsubscan] = 0.D0
           
; Now compute the complementary atmosphere
           wcomp = where( kidpar.type eq 1 and $
                          kidpar.array eq twinarr[iarray], nwcomp)
           if nwcomp ne 0 then begin
              noi_in_comp = nk_stddev( toi[wcomp,*], $
                                        flag=flag[wcomp,*], dim=2, /nan)
                                ; Do here some natural elimination: if
                                ; noise is too large, kill the kid
              goodkid = replicate( 1D0, nwcomp)
              bad = where( noi_in_comp gt pex_intern * $
                           nk_median( noi_in_comp) or $
                           noi_in_comp lt 0.5*nk_median( noi_in_comp) or $
                           (1-finite(noi_in_comp)), nbad)
              if nbad ne 0 then goodkid[ bad] = 0.
              w8_comp = (goodkid*kidpar[wcomp].noise^2/noi_in_comp^2)# $
                        (replicate(1D0, nsn)) ; will convert to natural weighing by the noise in nk_get_cm_sub_2
              if defined(snr_toi) then begin
                 w8_comp = w8_comp/(1.d0 + $
                                    param.k_snr_template * snr_toi[wcomp,*]^2)
              endif
              flaghere = flag[wcomp, *] ; do not change the real flag
              w8_comp = w8_comp*(flaghere eq 0 and off_source[wcomp,*] eq 1)
              
              hfnoise = nk_hf_noise( toi[ wcomp,  *], nsm = nsm) >0.7
              w8_comp = w8_comp/( replicate(1D0, nwcomp)#(hfnoise^2)) ; weigh down noisy samples across the array
              
              kidloc[wcomp] = kidpar[wcomp]
              
              nk_get_cm_sub_2, param, info, toi[wcomp,*], flaghere, $
                               off_source[wcomp,*], kidloc[wcomp], $
                               atm_cm_comp, $
                               w8=w8_comp
              if nwsubscan gt 0 then atm_cm_comp[ wsubscan] = 0.D0
           ;; endif  else stop, 'Not enough data for complementary array'+ $
           ;;                  param.scan
; Put a bit of a smoothing
              atm_cm_compsm = smooth( median(atm_cm_comp, 3), 11, /edge_trun)
           endif  else stop, param.scan+ $
                            ' Case not coded (FXD), investigate ' + $
                             'how to mask a strong source'
           
; Put a bit of a smoothing
           atm_cmsm = smooth( median(atm_cm, 3), 11, /edge_trun)
; Compute the derivative (avoid too much noise)
           atm_cdm = smooth( median(deriv(atm_cmsm), 7), 29, /edge_trun)
; Put to square to include possible non-linearities
           res = moment( atm_cmsm)
           if res[1] ne 0 then $
              atm_cm2 = ((atm_cmsm-res[0])/sqrt(res[1]))^2 else $
                 stop, param.scan+ ' Atm Common mode is constant?!'
           if param.include_elevation_in_decor_templates eq 1 then begin
              atm_temp = dblarr(5,nsn)
              atm_temp[0, *] = atm_cmsm
              atm_temp[1, *] = atm_cdm
              atm_temp[2, *] = atm_cm_compsm
              atm_temp[3, *] = atm_cm2
              atm_temp[4, *] = elevation
           endif else begin
              atm_temp = dblarr(4,nsn)
              atm_temp[0, *] = atm_cmsm
              atm_temp[1, *] = atm_cdm
              atm_temp[2, *] = atm_cm_compsm
              atm_temp[3, *] = atm_cm2
           endelse

; if one wants to decorrelate the 2mm with only the 1mm
                                ; (no electronic decorrelation, no 2mm average either)
           if param.atmb_dualband and iarray eq 2 then begin
              atm_temp = dblarr(4, nsn)
              atm_temp[0, *] = atm_cm_compsm  ; Twin array smoothed (here array3)
; Compute the derivative (avoid too much noise)
              atm_compdm = smooth( median(deriv(atm_cm_compsm), 7), 29, /edge_trun)
              atm_temp[1, *] = atm_compdm
; Put to square to include possible non-linearities
              res = moment( atm_cm_compsm)
              if res[1] ne 0 then $
                 atm_compsm2 = ((atm_cm_compsm-res[0])/sqrt(res[1]))^2 else $ ; rescaling
                    stop, param.scan+ ' Atm Common mode is constant?!'
              atm_temp[2, *] = atm_compsm2
              atm_temp[3, *] = elevation ; throw in elevation for good measure
              atm_temp = atm_temp[0:(param.atmb_dualband-1) < 3, *]  ; reduce the number of templates
           endif
           
           
;; 2. Subtract atmosphere from all KIDs of same array
           toinoa = toi[warr,*]
           kidloc[warr] = kidout[warr]

           if param.atmb_accelsm gt 1 then begin
              nk_subtract_templates_accel, param, info, toinoa, $
                                       flag[warr, *], off_source[warr, *], $
                                       kidloc[warr], atm_temp, out_temp0, $
                                       param.atmb_accelsm, out_coeffs=out_coeffs, $
                                       w8=w8toi
           endif else begin
              nk_subtract_templates_3, param, info, toinoa, $
                                       flag[warr, *], off_source[warr, *], $
                                       kidloc[warr], atm_temp, out_temp0, $
                                       out_coeffs=out_coeffs, $
                                       w8=w8toi
           endelse
           
           toi_no_atm[warr, *] = toinoa


;; 3. build one mode per subband (Code taken from
           ;; nk_decor_sub_6) and decorrelate a kid from all the subbands
           ;; of its box
           subband = kidout[warr].numdet/80 ; int division on purpose
           acqb = kidout[warr].acqbox       ; acquisition box
           b = subband[ uniq( subband, sort(subband))]
           ab =   acqb[ uniq( subband, sort(subband))]
           nb = n_elements(b)
           ab = ab[ sort(b)]    ; sort the acquisition box in the same way as subbands
           b = b[ sort(b)]
           ablist = acqb[ uniq( acqb, sort(acqb))]
           nab = n_elements( ablist) ; number of acq boxes.
           nt     = n_elements(atm_temp[*,0]) > 1
           if param.one_offset_per_subscan eq 1 then begin ; main case
; number of subscan offset and polynomial templates and remove first
; offset from templates
              ncomp = 2*nharm+ deg+ 1L  ; number of components per subscan (except first one)
              nss = nsubscans * ncomp - 1
; number of subscan times offsets, slopes, 2* number of harmonics
; (sin/cos) and remove first offset from templates
           endif else nss = 0 
           nsu = 5                               ; max 5 subbands per el. box.
           if param.one_offset_per_subscan eq 1 then $
              templates = dblarr( nt+nss+nsu, nsn) else $
                 templates = dblarr( nt+nsu, nsn)
           ;; Do not fit all subscans because regress needs one constant that
           ;; will be the one of the first subscan
           templates[0:nt-1,*] = atm_temp
           if param.one_offset_per_subscan eq 1 then begin
              for iss=0, nsubscans-1 do begin
                 wsubsc = where( subscan eq (subscan_min+iss), nwsubsc)
                 if nwsubsc le 23 then begin  $
; need 23 samples (about 1s) to be a fair subscan
                    nk_error, info, $
                    'Subscan '+strtrim(subscan_min+iss,2)+ $
                    ' is nearly empty'
                    return
                 endif
                 xx = (wsubsc-wsubsc[0]) / $
                      double(max(wsubsc)-wsubsc[0]) ; normalise
                 xx = xx - mean(xx)
                 if iss eq 0 then begin 
; Special case of first valid subscan (no offset)
                    if deg gt 0 then begin  ; Jan 2021, deg is 0, so do not go
                       for ipol = 1, deg do begin 
; remove first offset from template
                          templates[nt+ipol-1,wsubsc] = xx^ipol 
; one polynomial per subscan
                       endfor
                    endif  ; End condition on deg
                    
                    for iharm = 0, nharm-1 do begin 
                       templates[nt+iharm*2+deg, wsubsc] = $
                          cos( ((2.d0*!dpi)  * (iharm+1))* xx )
                       templates[nt+iharm*2+deg+1, wsubsc] = $
                          sin( ((2.d0*!dpi)  * (iharm+1))* xx )
                    endfor
                 endif else begin ; general case
                    for ipol = 0, deg do begin
                       templates[nt+iss*ncomp+ipol-1,wsubsc] = $
                          xx^ipol ; one offset or polynomial per subscan
;;; FXD : bug found 17/8/2020
;;; templates[nt+iss*deg+ipol-1,wsubsc] = xx^ipol
                    endfor
                    for iharm = 0, nharm-1 do begin ; (found this modelling in nk_lf_sin_fit)
                       templates[nt+iss*ncomp+iharm*2+deg,wsubsc] = $
                          cos( ((2.d0*!dpi)  * (iharm+1))* xx )
                       templates[nt+iss*ncomp+iharm*2+deg+1,wsubsc] = $
                          sin( ((2.d0*!dpi)  * (iharm+1))* xx )
                    endfor
                 endelse
              endfor            ; end loop on subscans  
           endif
           
;;; Loop on acq. box
           for iab = 0, nab-1 do begin
              current_ab = ablist[ iab]
              blist = b[ where( ab eq current_ab, nblist)]
              if  param.atmb_dualband and iarray eq 2 then begin
                 ibt = 0        ; ie do not include electronic noise decorrelation
              endif else begin 
                 ibt = 0        ; true number of sub bands with more than 5 kids
                 for ib=0, nblist-1 do begin
                    current_b = blist[ ib]
                    wb = where( subband eq current_b, nwb)
                    if nwb gt 10 then begin ; that 5 could be changed (10 FXD as of 29th Sept 2020)
                       warrb = warr[wb]
                       flaghere = flag[warrb, *] ; do not change the real flag
                       kidloc[warrb] = kidout[warrb]
                       nk_get_cm_sub_2, param, info, toinoa[wb,*], flaghere, $
                                        off_source[warrb,*], kidloc[warrb], subband_cm, $
                                        w8=w8good[wb, *]
                       templates[nt+nss+ibt,*] = $
                          smooth( median(subband_cm, 3), 11, /edge_trun)
                       ibt = ibt+1
                    endif
                 endfor         ; loop of subbands
;              if ibt ne nblist then $
;                 if param.silent eq 0 then
;                 print, 'Some subbands are nearly empty if ', ibt, $
;                        'ne', nblist, ' acqbox= ',  current_ab
              endelse 
;; 4.0 Prepare TOI without the first harmonics
              
              wc = where( acqb eq current_ab, nwarrc)
              warrc = warr[wc]


              if iter_atmb eq (niter_atmb-1) and param.atmb_defilter ne 0 and $
                 param.imcm_iter ge param.atmb_defilter then begin
; Here we want to re-add the harmonics back to the TOI so that the
; filtering is attenuated.
                                ; First attempt was with all
                                ; templates. That blows the noise so
                                ; Second attempt: we keep only the
                                ; constant, the slope, and the
                                ; harmonics
                                ; third: forget the slope
                 out_coeffs2 = 1
                 kidloc[warrc] = kidout[warrc]
                 subtoin = subtoi[warrc,*] ; contains the toi from the corrective map
                 par = param
;;;                 par.no_const_in_regress = 0 ; Important so that the final TOI has the same zero level as expected from the map (THAT is changed with HORVER)
                 par.no_const_in_regress = 1 ; Important so that the final TOI has the same zero level as expected from the map (THAT could be changed with HORVER)
                 if param.atmb_accelsm gt 1 then begin
                    nk_subtract_templates_accel, par, info, subtoin, $
                                                 flag[warrc,*], off_source[warrc,*], $
                                                 kidloc[warrc], $
                                                 templates[nt:nt+nss+ibt-1, *], $
                                                 out_temp2, param.atmb_accelsm, $
                                                 out_coeffs=out_coeffs2, $
                                                 w8=w8toi[wc, *]
                 endif else begin
                    nk_subtract_templates_3, par, info, subtoin, $
                                             flag[warrc,*], off_source[warrc,*], $
                                             kidloc[warrc], $
                                ; limit the templates to useful ones
                                ; nt is the number of atm templates
                                ; that we exclude here to keep only
                                ; the harmonics per subscans
                                             templates[nt:nt+nss+ibt-1, *], $
                                             out_temp2, $
                                             out_coeffs=out_coeffs2, $
                                             w8=w8toi[wc, *]
                                ; out_temp2 is the alternative TOI
                                ; with only the low frequency modes
                 endelse
              endif 
              
              ;; 4.1 Decorrelate input TOI from all modes and
              ;; elevation and atm at
              ;; the same time
              toin = toi[warrc,*]

;; don't do that anymore Jan 2021 (causing divergence in the iteration)
              ;; if iter_atmb eq (niter_atmb-1) and param.atmb_defilter ne 0 and $
              ;;    param.imcm_iter ge param.atmb_defilter then begin
              ;;    toin = toin - out_temp2  ;remove the harmonics before the fit
              ;; endif
              
              out_coeffs = 1
              kidloc[warrc] = kidout[warrc]
              if param.atmb_accelsm gt 1 then begin
                 nk_subtract_templates_accel, param, info, toin, $
                                              flag[warrc,*], off_source[warrc,*], $
                                              kidloc[warrc], $
                                ; limit the templates to useful ones
                                              templates[0:nt+nss+ibt-1, *], $
                                              out_temp1, param.atmb_accelsm, $
                                              out_coeffs=out_coeffs, $
                                              w8=w8toi[wc, *]
              endif else begin
                 nk_subtract_templates_3, param, info, toin, $
                                          flag[warrc,*], off_source[warrc,*], $
                                          kidloc[warrc], $
                                ; limit the templates to useful ones
                                          templates[0:nt+nss+ibt-1, *], $
                                          out_temp1, $
                                          out_coeffs=out_coeffs, $
                                          w8=w8toi[wc, *]
              endelse 
              if iter_atmb eq (niter_atmb-1) and param.atmb_defilter ne 0 and $
                 param.imcm_iter ge param.atmb_defilter then begin
                 toin = toin + out_temp2 ; reintegrate the harmonics after the fit
                                ;out_temp1 is modified JAN 2021
                 out_temp1 = out_temp1 - out_temp2
              endif
              toi_out[warrc,*] = toin
              out_temp[warrc, *] = out_temp1
              outc[warrc] = out_coeffs[*, 1]  ; Main correlation coefficient
; very important (in case of sources...) (0 is for the constant
; offset, 1 is the main correlation with the atmosphere


;              if current_ab eq 14 then stop, ' nk_decor_atmb, ab=14, test'
              ;; if iter_atmb eq (niter_atmb-1) and $
              ;;    param.atmb_defilter ne 0 and acqb[300] eq 14 then stop, ' nk_decor_atmb, iab=3, test'
              
           endfor                          ; End loop on acq. box
           
           noi_out = nk_stddev( toi_out[ warr, *], $
                                flag = flag[ warr, *], dim=2, /nan)
           totout = mean(out_temp[warr, *], dim = 2, /nan) ; test if the fit went wrong
                                ; Move from 3 to 5. here (8/12/2020
                                ; FXD) to avoid too much exclusion
                                ; with A1
           medoutc = median( outc[ warr])
           cdisp = stddev( outc[ warr], /nan)
           medoutc1 = medoutc- 10*cdisp
           medoutc2 = medoutc+ 10*cdisp
; this method (below) is too selective when atmb_nsubscan is employed
; (6 Apr 2021)
           ;; medoutc1 = 0.2*medoutc
           ;; medoutc2 = 10.*medoutc ; 5 is not enough for A1
           if strlen(param.simu_dir) ne 0 then begin ; simulation mode
              medoutc1 = -1D20
              medoutc2 = 1D20
           endif
           bad = where( noi_out gt pex * nk_median( noi_out) or $
                        noi_out lt 0.5 * nk_median( noi_out) or $
                        (1-finite(noi_out)) or $
                        total( flag[ warr, *], 2) eq nsn or totout eq 0D0 or $
                        outc[ warr] gt medoutc2 or $    
                        outc[ warr] lt medoutc1, nbad)
           if iarray eq 3 and nbad gt 0.6*nwarr then $
              stop, 'Should not happen. Test new scheme at iter_atmb '+ strtrim(iter_atmb, 2)+ $
                    ', '+info.scan
;          if iarray eq 2 then stop, 'Test new scheme'
;          if iarray eq 3 and iter_atmb eq (niter_atmb-1) then stop, 'Test new scheme'
           if nbad ne 0 then begin
              if param.silent eq 0 then if nbad gt 19 then $
                 print, strtrim( nbad, 2)+ ' noisy (or too good to be true) kids in array '+ $
                        strtrim(iarray, 2), ' at iter_atmb '+ strtrim(iter_atmb, 2), $
                        ' in ATMB, out of '+ strtrim( nwarr, 2), ' , scan '+info.scan
              if nbad gt 0.6*nwarr then begin
                 if iter_atmb lt (niter_atmb-1) then begin
                    if nharm eq 0 then begin
                       deg = (deg-1)>0 
; attempt at salvaging the scan when fit is poor
                       print, 'Lower the polynomial degree to ', deg
                    endif else begin
                       nharm = (nharm-1)>0
                       print, 'Lower the number of harmonics to ', nharm
                    endelse
                 endif
                 
              endif
;           if iarray eq 1 then stop
;stop,  ' TEST '             
              if iter_atmb eq (niter_atmb-1) then begin ; exit cleaning
                 for ik = 0, nbad-1 do begin
                    toi_out[ warr[ bad[ ik]], *] = !values.d_nan
                                ; Trim toi_out if noise is too high
              ;;;out_temp[ warr[ bad[ ik]], *] = !values.d_nan ; this is
              ;;;what is really used to subtract to data. See
              ;;;nk_scan_reduce_1, line 469 data.toi = toi_copy -
              ;;;out_temp_data.toi ; workaround, see below
                 endfor
                                ; not working, take this radical step
                 kidout[ warr[ bad]].type = 3
              endif else begin  ; cleaning during the iteration
                 if nbad le 0.6*nwarr then kidout[ warr[ bad]].type = 3 
; to improve the iteration take out bad kids
              endelse
           endif                ; end test of noisy kids
           ;; if param.silent eq 0 then $
           ;;    print, iarray, ' ', nk_median( noi_out), $
           ;;           ', scan:   ', param.scan

;           if iarray eq 1 then stop
        endif                    ; end condition on enough kids in the array (nwarr)
     endfor                     ; end iteration on common modes (niter_atmb)
  endfor                      ; end loop on arrays (iarray 1 to 3)
  kidpar = kidout  ; keep the new types
;  if param.cpu_time then nk_show_cpu_time, param
  return
end
