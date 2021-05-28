;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_decor_sub_6
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_decor_sub_6, param, info, toi, flag, off_source, kidpar, out_temp
; 
; PURPOSE: 
;        Decorrelates kids according to param.decor_method
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - toi, flag, off_source
;        - kidpar
; 
; OUTPUT: 
;        - toi, out_temp
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 16th, 2018: NP, extracted from nk_decor_sub_5 and
;          adpated to nk_clean_data_4.pro and its subroutines

pro nk_decor_sub_6, param, info, toi, flag, off_source, kidpar, $
                    out_temp_data, elevation, $
                    kid_corr_block=kid_corr_block, $
                    atm_deriv=atm_deriv, out_coeffs=out_coeffs, $
                    snr_toi=snr_toi, subscan=subscan, dra=dra, ddec=ddec, $
                    zm_toi=zm_toi, $
                    w8_hfnoise=w8_hfnoise, subtoi = subtoi
;-

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_decor_sub_6'
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nsn   = n_elements(toi[0,*])
nkids = n_elements( toi[*,0])

if info.polar ne 0 then begin
   out_temp_data = {toi:dblarr(nkids), toi_q:dblarr(nkids), toi_u:dblarr(nkids)}
endif else begin
   out_temp_data = {toi:dblarr(nkids)}
endelse
out_temp_data = replicate( out_temp_data, nsn)   ; FXD NB: out_temp_data can already be defined as a nsn array in input. see nk_decor_6 whole scan decorrelation case. Never mind.

;;====================================================================================================
;; Select which decorrelation method must be applied
method = param.decor_method
if strupcase(method) eq "COMMON_MODE" then begin
   ;; keep all valid samples, even on source => force off_source to
   ;; 1 everywhere
   off_source[*] = 1.d0
   method = "per_array"
endif
if strupcase(method) eq "COMMON_MODE_KIDS_OUT" then method = "per_array"

;; print, "method: ", method
;;                                 ;help, off_source
;stop
case strupcase(method) of
   ;; 1. No decorrelation
   "NONE": message, /info, "Decor method = None, ok, I pass"

   ;; 2. Simple commmon mode, one per array, mask or not depending
   ;; common_mode vs common_mode_kids_out
   "PER_ARRAY": begin
      nk_get_one_mode_per_array, param, info, toi, flag, off_source, kidpar, common_mode_per_array ;, w8_source=w8_source
      ;; decorrelate
      templates = dblarr(2,nsn)
      templates[0,*] = elevation
      for iarray=1, 3 do begin
         w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
         if nw1 ne 0 then begin
            templates[1,*] = common_mode_per_array[iarray-1,*]
            junk = toi[w1,*]
            nk_subtract_templates_3, param, info, junk, flag[w1,*], off_source[w1,*], $
                                     kidpar[w1], templates, out_temp
            ;; EA and LP
            ;; junk is the residual noise TOI after template subtraction
            toi[w1,*] = junk
            ;; END EA and LP
            out_temp_data.toi[w1] = out_temp
         endif
      endfor
   end
   
   "BASELINES":begin
      w1 = where( kidpar.type eq 1, nw1)
      index = lindgen(nsn)
      for i=0, nw1-1 do begin
         ikid = w1[i]
         wfit = where( off_source[ikid,*] eq 1 and flag[ikid,*] eq 0, nwfit)
         ;; wfit = where( flag[ikid,*] eq 0, nwfit)
         if nwfit lt 10 then begin
            flag[ikid,*] = 2L^7
         endif else begin

            if defined(snr_toi) then begin
               r = poly_fit( index[wfit], reform(toi[ikid,wfit]), param.baselines_pol_deg, $
                             measure_errors=reform( 1.d0/sqrt(1.d0+param.k_snr_w8_decor*snr_toi[ikid,*]^2)), $
                             status = status)
            endif else begin
               r = poly_fit( index[wfit], reform(toi[ikid,wfit]), param.baselines_pol_deg, $
                             status = status)
            endelse
            if status eq 0 then begin
               yfit = index*0.d0
               for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii
               out_temp_data.toi[ikid] = yfit
               ;; EA & LP 
               toi[ikid,*] -= yfit
               ;; END EA & LP
            endif else begin
               flag[ikid,*] = 2L^7
            endelse
            
         endelse
      endfor
   end

   ;; per array with cm_kid_min_dist
   "PER_ARRAY_CM_KID_MIN_DIST":begin
      templates = dblarr(2,nsn)
      templates[0,*] = elevation
      for iarray=1, 3 do begin
         w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
         if nw1 ne 0 then begin
            nk_get_cm_sub_4, param, info, toi[w1,*], flag[w1,*], off_source[w1,*], kidpar[w1], cmsub4
            for i=0, nw1-1 do begin
               templates[1,*] = cmsub4[*,i]
               junk = toi[w1[i],*]
               nk_subtract_templates_3, param, info, junk, flag[w1[i],*], off_source[w1[i],*], $
                                        kidpar[w1[i]], templates, out_temp
               toi[w1[i],*] = junk
               out_temp_data.toi[w1[i]] = out_temp[*]
            endfor
         endif
      endfor
   end
   
   ;; 4. Decorrelate each kid from the common mode of the kids that
   ;; are most correlated to it.
   "COMMON_MODE_ONE_BLOCK":begin
      if param.log eq 1 then nk_log, info, "common_mode_one_block"
      ;; LP begin : kid_corr_block are computed only if not input as keyword
      if keyword_set(kid_corr_block) then kid_corr_block_1 = kid_corr_block else $
         nk_get_corr_block_3, param, info, toi, flag, off_source, kidpar, kid_corr_block_1

      ;; EA & LP: add toi_out to output the residual noise TOI after
      ;; template subtraction
      nk_decor_common_mode_one_block, param, info, toi, flag, off_source, kidpar, $
                                      toi_out, common_mode, elevation, kid_corr_block_1 ;, w8_source=w8_source
      ;; LP end
      out_temp_data.toi = common_mode
      ;; EA & LP: toi is the noise residual
      toi = toi_out 
   end

   ;; 5. Decorrelate each kid from the common mode of all other kids
   ;; in the same electronic box
   "COMMON_MODE_BOX":begin
      nk_get_one_mode_per_box, param, info, toi, flag, off_source, kidpar, common_mode_per_box, acq_box_out
      ;; Decorrelate
      if param.decor_from_all_box ge 1 then begin
         nboxes = n_elements(acq_box_out)
         templates = dblarr(nboxes+1,nsn)
         templates[0,*] = elevation
         templates[1:*,*] = common_mode_per_box
         w1 = where( kidpar.type eq 1, nw1)
         junk = toi[w1,*]
         nk_subtract_templates_3, param, info, junk, flag[w1,*], off_source[w1,*], $
                                  kidpar[w1], templates, out_temp
         toi[w1,*] = junk
         out_temp_data.toi[w1] = out_temp
      endif else begin
         ;; only the box of the current kid
         templates = dblarr(2,nsn)
         templates[0,*] = elevation
         w1 = where( kidpar.type eq 1, nw1)
         for i=0, nw1-1 do begin
            ikid = w1[i]
            wbox = (where( strupcase(acq_box_out) eq strupcase( kidpar[ikid].acqbox), nwbox))[0]
            if nwbox eq 0 then begin
               nk_error, info, "No electronic box in acq_box_out matches kidpar[ikid].acqbox"
               return
            endif
            templates[1,*] = common_mode_per_box[wbox,*]
            junk = toi[ikid,*]
            nk_subtract_templates_3, param, info, junk, flag[ikid,*], off_source[ikid,*], $
                                     kidpar[ikid], templates, out_temp
            toi[ikid,*] = junk
            out_temp_data.toi[ikid] = reform(out_temp)
         endfor
      endelse
   end

   "ATM_AND_ALL_BOX":begin
      ;; Estimate the atmosphere from a global common mode
      w1 = where( kidpar.type eq 1, nw1)
      nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                       off_source[w1,*], kidpar[w1], atm_cm

      ;; Subtract atm_cm from TOI's to build one mode per box with the residuals
      templates = dblarr(2,nsn)
      templates[0,*] = elevation
      templates[1,*] = atm_cm
      junk = toi
      nk_subtract_templates_3, param, info, junk, flag, off_source, $
                               kidpar, templates, out_temp
      nk_get_one_mode_per_box, param, info, junk, flag, off_source, kidpar, common_mode_per_box, acq_box_out

      ;; Decorrelate the original TOI's from atm and all boxes
      ;; at the same time
      junk = toi
      nboxes = n_elements(acq_box_out)
      templates = dblarr(nboxes+2,nsn)
      templates[0,*] = elevation
      templates[1,*] = atm_cm
      templates[2:*,*] = common_mode_per_box
      nk_subtract_templates_3, param, info, junk, flag, off_source, $
                               kidpar, templates, out_temp
      toi = junk
      out_temp_data.toi = out_temp
   end

   "ATM_AND_ALL_BOX_ITER":begin
      ;; Estimate the atmosphere from a global common mode
;      save, param, info, toi, flag, off_source, kidpar, file='data.save'
;      stop
;      myi = 0
;      myt0 = dblarr(100) + systime(0,/sec)
      w1 = where( kidpar.type eq 1, nw1)
      nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                       off_source[w1,*], kidpar[w1], atm_cm

;      myi++
;      myt0[myi] = systime(0,/sec)
      ;; Subtract atm_cm from TOI's to build one mode per box with the residuals
      templates = dblarr(2,nsn)
      templates[0,*] = elevation
      ;;templates[0,*] = 1./sin(elevation)
      templates[1,*] = atm_cm
      junk = toi
      nk_subtract_templates_3, param, info, junk, flag, off_source, $
                               kidpar, templates, out_temp
;      myi++
;      myt0[myi] = systime(0,/sec)
      nk_get_one_mode_per_box, param, info, junk, flag, off_source, kidpar, common_mode_per_box, acq_box_out
;      myi++
;      myt0[myi] = systime(0,/sec)

      ;; Decorrelate the original TOI's from atm and all boxes
      ;; at the same time to get a first estimate of the KIDs coeffs
      junk = toi
      nboxes = n_elements(acq_box_out)
      if param.cos_sin_elev_offset eq 1 then begin
         templates = dblarr(nboxes+3,nsn)
         templates[0,*] = cos(elevation)
         templates[1,*] = sin(elevation)
         templates[2,*] = atm_cm
         templates[3:*,*] = common_mode_per_box
      endif else begin
         templates = dblarr(nboxes+2,nsn)
         templates[0,*] = elevation
         templates[1,*] = atm_cm
         templates[2:*,*] = common_mode_per_box
      endelse

      nk_subtract_templates_3, param, info, junk, flag, off_source, $
                               kidpar, templates, out_temp, out_coeffs=out_coeffs
;;       niter = 5                 ; to try
;; ;      all_out_common_modes = dblarr(niter,nboxes+3,nsn)
;;       make_ct, niter, ct_iter
;;       for iter=0, niter-1 do begin
;;          ;; Build new estimates of common modes with out_coeffs and TOI's
;;          ata = alpha##transpose(alpha)
;;          atam1 = invert(ata)
;;          atd = toi##transpose(alpha)
;;          out_common_modes = transpose(atam1##transpose(atd))
;;  ;        all_out_common_modes[iter,*,*] = out_common_modes
;;          junk = toi
;;          templates = out_common_modes[1:*,*] ; get rid of the constant terms for "regress.pro"
;;          ;; Use nk_subtract_templates_3 to determine alpha at each
;;          ;; iteration and take the last decorrelation when we exit
;;          ;; this loop.
;;          nk_subtract_templates_3, param, info, junk, flag, off_source, $
;;                                   kidpar, templates, out_temp, out_coeffs=alpha
;;  ;     myi++
;;  ;     myt0[myi] = systime(0,/sec)
;;       endfor
         
      toi = junk
      out_temp_data.toi = out_temp

;;       ;; Compare to the original common_mode_per_box and atm_cm
;;       wind, 1, 1, /free, /large
;;       my_multiplot, 1, 1, ntot=(nboxes+2), pp, pp1, /full, /dry
;;       plot, atm_cm, position=pp1[0,*], /xs
;;       legendastro, 'Atm'
;;       for iter=0, niter-1 do oplot, all_out_common_modes[iter,2,*], col=ct_iter[iter]
;;       for i=0, nboxes-1 do begin
;;          plot, all_out_common_modes[0,3+i,*], /xs, position=pp1[i+1,*], /noerase &$
;;             legendastro, 'Box '+strtrim(i,2) &$
;;             for iter=0, niter-1 do oplot, all_out_common_modes[iter,3+i,*], col=ct_iter[iter]
;;       endfor
;       stop
   end

   ;; Direct decorrelation per subbands, not intermediate step with
   ;; boxes
   "ATM_AND_SUBBANDS":begin
      
      w1 = where( kidpar.type eq 1, nw1)
      if defined(snr_toi) eq 0 then begin
         nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                          off_source[w1,*], kidpar[w1], atm_cm
      endif else begin
         nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                          off_source[w1,*], kidpar[w1], atm_cm, $
                          w8_source=(1.d0/(1.d0+param.k_snr_w8_decor*snr_toi[w1,*]^2))
      endelse
 
      ;; Subtract atm_cm from TOI's to build one mode per box with the residuals
      templates = dblarr(2,nsn)
      templates[0,*] = elevation
      templates[1,*] = atm_cm
      junk = toi
      nk_subtract_templates_3, param, info, junk, flag, off_source, $
                               kidpar, templates, out_temp, out_coeffs=out_coeffs

      ;; build one mode per subband
      subband = kidpar[w1].numdet/80 ; int division on purpose
      b = subband[ uniq( subband, sort(subband))]
      nb = n_elements(b)

      templates = dblarr(2+nb,nsn)
      templates[0,*] = elevation
      templates[1,*] = atm_cm
      for ib=0, nb-1 do begin
         wb = where( kidpar.type eq 1 and subband eq b[ib], nwb)
         nk_get_cm_sub_2, param, info, junk[wb,*], flag[wb,*], $
                          off_source[wb,*], kidpar[wb], subband_cm
         templates[ib+2,*] = subband_cm
      endfor
      
      ;; Decorrelate input TOI from all modes and elevation and atm at
      ;; the same time
      junk = toi
      if defined(snr_toi) eq 0 then begin
         nk_subtract_templates_3, param, info, junk, flag, off_source, $
                                  kidpar, templates, out_temp, out_coeffs=out_coeffs
      endif else begin
         nk_subtract_templates_3, param, info, junk, flag, off_source, $
                                  kidpar, templates, out_temp, out_coeffs=out_coeffs, $
                                  w8_source=(1.d0/(1.d0+param.k_snr_w8_decor*snr_toi^2))
      endelse
      
      toi = junk
      out_temp_data.toi = out_temp
   end

   
   ;; just for pedagogical purpose: subtract only elevation and atmosphere
   "ATM_ONLY":begin
      w1 = where( kidpar.type eq 1, nw1)
      nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                       off_source[w1,*], kidpar[w1], atm_cm
      
      templates = dblarr(2,nsn)
      templates[0,*] = elevation
      templates[1,*] = atm_cm

      junk = toi
      nk_subtract_templates_3, param, info, junk, flag, off_source, $
                               kidpar, templates, out_temp, out_coeffs=out_coeffs
      toi = junk
      out_temp_data.toi = out_temp
   end

   "ATM_AND_ALL_BOX_SNR_W8":begin
      
      w1 = where( kidpar.type eq 1, nw1)
      if param.log then nk_log, info, "derive atm_cm using ALL kids (1&2mm)"
      if defined(snr_toi) eq 0 then begin
         nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                          off_source[w1,*], kidpar[w1], atm_cm
      endif else begin
         nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                          off_source[w1,*], kidpar[w1], atm_cm, $
                          w8_source=(1.d0/(1.d0+param.k_snr_w8_decor*snr_toi[w1,*]^2))
      endelse

;;       @nk_decor_sub_6_interactive_plot_1.pro

      ;; Subtract atm_cm from TOI's to build one mode per box
      ;; with the residuals
      templates = dblarr(2,nsn)
      templates[0,*] = elevation
      templates[1,*] = atm_cm
      junk = toi
      if param.log then nk_log, info, "Subtract atm and elevation from toi"
      nk_subtract_templates_3, param, info, junk, flag, off_source, $
                               kidpar, templates, out_temp, out_coeffs=out_coeffs

      ;; Build one mode per box now that atm and elevation (main
      ;; contributors) have been subtracted
      if param.log then nk_log, info, "derive one mode per electronic box"
      nk_get_one_mode_per_box, param, info, junk, flag, off_source, kidpar, common_mode_per_box, acq_box_out

;;      @nk_decor_sub_6_interactive_plot_2.pro

      ;; Decorrelate the original TOI's from atm and all boxes
      ;; at the same time to get a first estimate of the KIDs coeffs
      junk = toi
      if param.log then nk_log, info, "restore input toi"
      nboxes = n_elements(acq_box_out)
      if param.cos_sin_elev_offset eq 1 then begin
         templates = dblarr(nboxes+3,nsn)
         templates[0,*] = cos(elevation)
         templates[1,*] = sin(elevation)
         templates[2,*] = atm_cm
         templates[3:*,*] = common_mode_per_box
      endif else begin
         templates = dblarr(nboxes+2,nsn)
         templates[0,*] = elevation
         templates[1,*] = atm_cm
         templates[2:*,*] = common_mode_per_box
      endelse

      if defined(snr_toi) eq 1 then begin
         w8_source = 1.d0/(1.d0+param.k_snr_w8_decor*snr_toi^2)
      endif else begin
         delvarx, w8_source
      endelse

      @nk_decor_sub_6_debug_plot_1.pro
      
      if param.log then nk_log, info, "decorrelate toi from atm, elevation and common_mode_per_box"
      nk_subtract_templates_3, param, info, junk, flag, off_source, $
                               kidpar, templates, out_temp, out_coeffs=out_coeffs, $
                               w8_source=w8_source

      @nk_decor_sub_6_debug_plot_2.pro
      iter_cm = 1
      while iter_cm lt param.niter_cm do begin
         if param.log then nk_log, info, "iterating on common modes "+strtrim(iter_cm,2)+"/"+strtrim(param.niter_cm-1,2)
         junk = toi

         @nk_decor_sub_6_debug_plot_3.pro

         ;; Build new estimates of common modes with out_coeffs and TOI's
         ata = out_coeffs##transpose(out_coeffs)
         atam1 = invert(ata)
         atd = toi##transpose(out_coeffs)
         out_common_modes = transpose(atam1##transpose(atd))
         if param.debug then all_out_common_modes[iter_cm-1,*,*] = out_common_modes

         templates = out_common_modes[1:*,*] ; get rid of the constant terms for "regress.pro"
         ;; Use nk_subtract_templates_3 to determine out_coeffs at each
         ;; iteration and take the last decorrelation when we exit
         ;; this loop.
         nk_subtract_templates_3, param, info, junk, flag, off_source, $
                                  kidpar, templates, out_temp, out_coeffs=out_coeffs
         iter_cm++
      endwhile

      @nk_decor_sub_6_debug_plot_4.pro
      ;; old plots ?
      ;; @nk_decor_sub_6_debug_plot_old.pro

      if param.common_mode_subband_1mm eq 1 then begin
         if param.log then nk_log, info, "decorrelate each kid from the common mode of its subband at 1mm"
         subband = kidpar.numdet/80 ; int division on purpose
         nbox = max(kidpar.acqbox)-min(kidpar.acqbox)+1
         boxlist = indgen(nbox) + min(kidpar.acqbox)
         for iii=0, nbox-1 do begin
            ibox = boxlist[iii]
            w1 = where( kidpar.type eq 1 and kidpar.acqbox eq ibox and $
                        kidpar.lambda lt 1.5, nw1)
            if nw1 ne 0 then begin
               sb = subband[w1]
               if nw1 ne 0 then begin
                  b = sb[ uniq( sb, sort(sb))]
                  nb = n_elements(b)
                  for ib=0, nb-1 do begin
                     wb = where( kidpar.type eq 1 and subband eq b[ib], nwb)
                     nk_get_cm_sub_2, param, info, junk[wb,*], flag[wb,*], $
                                      off_source[wb,*], kidpar[wb], subband_cm
                     junk_b = junk[wb,*]
                     nk_subtract_templates_3, param, info, junk_b, flag[wb,*], off_source[wb,*], $
                                              kidpar[wb], subband_cm, out_cm
                     junk[wb,*] = junk_b
                     out_temp[wb,*] += out_cm
                  endfor
               endif
            endif
         endfor
      endif

      if param.common_mode_subband_2mm eq 1 then begin
         if param.log then nk_log, info, "decorrelate each kid from the common mode of its subband at 2mm"
         subband = kidpar.numdet/80 ; int division on purpose
         nbox = max(kidpar.acqbox)-min(kidpar.acqbox)+1
         boxlist = indgen(nbox) + min(kidpar.acqbox)
         for iii=0, nbox-1 do begin
            ibox = boxlist[iii]
            w1 = where( kidpar.type eq 1 and kidpar.acqbox eq ibox and $
                        kidpar.lambda gt 1.5, nw1)
            if nw1 ne 0 then begin
               sb = subband[w1]
               if nw1 ne 0 then begin
                  b = sb[ uniq( sb, sort(sb))]
                  nb = n_elements(b)
                  for ib=0, nb-1 do begin
                     wb = where( kidpar.type eq 1 and subband eq b[ib], nwb)
                     nk_get_cm_sub_2, param, info, junk[wb,*], flag[wb,*], $
                                      off_source[wb,*], kidpar[wb], subband_cm
                     junk_b = junk[wb,*]
                     nk_subtract_templates_3, param, info, junk_b, flag[wb,*], off_source[wb,*], $
                                              kidpar[wb], subband_cm, out_cm
                     junk[wb,*] = junk_b
                     out_temp[wb,*] += out_cm
                  endfor
               endif
            endif
         endfor
      endif
      
      toi = junk
      out_temp_data.toi = out_temp
   end

   "ATM_DERIV_ONE_BOX":begin
      ;; Estimate the atmosphere from a global common mode
      w1 = where( kidpar.type eq 1, nw1)
      nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                       off_source[w1,*], kidpar[w1], atm_cm
      
      ;; Subtract atm_cm from TOI's to build one mode per box with the residuals
      templates = dblarr(2,nsn)
      templates[0,*] = elevation
      templates[1,*] = atm_cm
      junk = toi
      nk_subtract_templates_3, param, info, junk, flag, off_source, $
                               kidpar, templates, out_temp
      nk_get_one_mode_per_box, param, info, junk, flag, off_source, kidpar, common_mode_per_box, acq_box_out

      ;; Decorrelate box per box from atm, atm_deriv and the box
      ;; common mode
      templates = dblarr(3,nsn)
      templates[0,*] = atm_cm
      templates[1,*] = atm_deriv
      nboxes = n_elements(acq_box_out)
      for iii=0, nboxes-1 do begin
         ibox = acq_box_out[iii]
         w1 = where( kidpar.type eq 1 and kidpar.acqbox eq ibox, nw1)
         if nw1 ne 0 then begin
            templates[2,*] = common_mode_per_box[iii,*]
            junk = toi[w1,*]
            nk_subtract_templates_3, param, info, junk, flag[w1,*], off_source[w1,*], $
                                     kidpar[w1], templates, out_temp
            toi[w1,*] = junk
         endif
      endfor
   end

   'TEST_NP':begin
;;      nk_get_corr_block_3, param, info, toi, flag, off_source, kidpar, kid_corr_block
;;      nk_test_np, param, info, toi, flag, off_source, kidpar, common_mode, elevation, kid_corr_block
;;
;;      nk_decor_common_mode_one_block, param, info, toi, flag, off_source, kidpar, $
;;                                      common_mode_one_block, elevation, kid_corr_block ;, w8_source=w8_source
;;
;;
;;      print, "Now compare common_mode and common_mode_one_block"
;;      stop
      for iarray=1, 3 do begin
         w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
         if nw1 ne 0 then begin
            flag1 = flag[w1,*]
            toi1 = toi[w1,*]
            nk_test_np_2, param, info, toi1, flag1, off_source[w1,*], kidpar[w1], common_mode, elevation
;            flag[w1,*] = flag1
            ;; EA and LP: uncomment the line below
            toi[w1,*] = toi1
            out_temp_data.toi[w1] = common_mode
         endif
      endfor
   end
   
   ;; Estimate the atmosphere with all kids and cecorrelate each kid from the common mode of all other kids in
   ;; the same electronic box and the atmosphere
   "ATM_COMMON_MODE_BOX":begin
      ;; atmosphere
      w1 = where( kidpar.type eq 1, nw1)
      nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                       off_source[w1,*], kidpar[w1], atm_cm

      ;; box modes
      nk_get_one_mode_per_box, param, info, toi, flag, off_source, kidpar, common_mode_per_box, acq_box_out

      ;; decorrelate kids
      templates = dblarr(2,nsn)
      templates[0,*] = atm_cm
      w1 = where( kidpar.type eq 1, nw1)
      for i=0, nw1-1 do begin
         ikid = w1[i]
         wbox = (where( strupcase(acq_box_out) eq strupcase( kidpar[ikid].acqbox), nwbox))[0]
         if nwbox eq 0 then begin
            nk_error, info, "No electronic box in acq_box_out matches kidpar[ikid].acqbox"
            return
         endif
         templates[1,*] = common_mode_per_box[wbox,*]
         junk = toi[ikid,*]
         nk_subtract_templates_3, param, info, junk, flag[ikid,*], off_source[ikid,*], $
                                  kidpar[ikid], templates, out_temp
         toi[ikid,*] = junk
         out_temp_data.toi[ikid] = reform(out_temp)
      endfor
   end

   ;; common_mode_one_block and atmosphere
   "ATM_COMMON_MODE_ONE_BLOCK":begin
      ;; atmosphere
      w1 = where( kidpar.type eq 1, nw1)
      nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                       off_source[w1,*], kidpar[w1], atm_cm

      ;; subtract atmosphere
      templates = dblarr(1,nsn)
      templates[0,*] = atm_cm
      for i=0, nw1-1 do begin
         ikid = w1[i]
         junk = toi[ikid,*]
         nk_subtract_templates_3, param, info, junk, flag[ikid,*], off_source[ikid,*], $
                                  kidpar[ikid], templates, out_temp
         toi[ikid,*] = junk
      endfor
      
      ;; Now do "common_mode_one_block"
      ;; LP begin: define new kid_corr_block_1 variable
      if keyword_set(kid_corr_block) then kid_corr_block_1 = kid_corr_block else $
         nk_get_corr_block_3, param, info, toi, flag, off_source, kidpar, kid_corr_block_1
      nk_decor_common_mode_one_block, param, info, toi, flag, off_source, kidpar, $
                                      toi_out, common_mode, elevation, kid_corr_block_1;, w8_source=w8_source
      ;; LP end
      out_temp_data.toi = common_mode
      ;; EA and LP: add the line below
      toi = toi_out
      
   end

   ;; common_mode_one_block and atmosphere and iterate on the
   ;; separation of atmosphere and electronic noise
   "ATM_COMMON_MODE_ONE_BLOCK_ITER":begin
      toi_copy = toi

      ;; 1st estim of atmosphere
      w1 = where( kidpar.type eq 1, nw1)
      nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                       off_source[w1,*], kidpar[w1], atm_cm

      ;; subtract atmosphere
      templates = dblarr(1,nsn)
      templates[0,*] = atm_cm
      for i=0, nw1-1 do begin
         ikid = w1[i]
         junk = toi[ikid,*]
         nk_subtract_templates_3, param, info, junk, flag[ikid,*], off_source[ikid,*], $
                                  kidpar[ikid], templates, out_temp
         toi[ikid,*] = junk
      endfor

      ;; box modes as proxies to elec noise
      nk_get_one_mode_per_box, param, info, toi, flag, off_source, kidpar, common_mode_per_box, acq_box_out

      ;; Subtract only the elec noise from kid timelines to improve
      ;; the atmosphere estimate
      toi = toi_copy
      templates = dblarr(2,nsn)
      templates[0,*] = atm_cm
      w1 = where( kidpar.type eq 1, nw1)
      for i=0, nw1-1 do begin
         ikid = w1[i]
         wbox = (where( strupcase(acq_box_out) eq strupcase( kidpar[ikid].acqbox), nwbox))[0]
         if nwbox eq 0 then begin
            nk_error, info, "No electronic box in acq_box_out matches kidpar[ikid].acqbox"
            return
         endif
         templates[1,*] = common_mode_per_box[wbox,*]

         wsample = where( off_source[ikid,*] eq 1 and finite(toi[ikid,*]) eq 1, nwsample)
         if nwsample lt param.nsample_min_per_subscan then begin
            ;; do not project this subscan for this kid
            flag[ikid,*] = 2L^7
         endif else begin     
            ;; Regress the templates and the data off source
            ;; test on do_i and keywords to avoid a duplication of the timeline and
            ;; save time and memory...
            coeff = regress( templates[*,wsample], reform( toi[ikid,wsample]), $
                             CHISQ= chi, CONST= const, CORRELATION= corr, $
                             /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)
            ;; subtract only the electronic noise
            toi[ikid,*] -= coeff[1]*templates[1,*]
         endelse
      endfor

      ;; 2nd estimate of atmosphere
      w1 = where( kidpar.type eq 1, nw1)
      nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                       off_source[w1,*], kidpar[w1], atm_cm
      ;; subtract
      templates = dblarr(1,nsn)
      templates[0,*] = atm_cm
      for i=0, nw1-1 do begin
         ikid = w1[i]
         junk = toi[ikid,*]
         nk_subtract_templates_3, param, info, junk, flag[ikid,*], off_source[ikid,*], $
                                  kidpar[ikid], templates, out_temp
         toi[ikid,*] = junk
      endfor

      ;; Determine blocks of correlated kids
      ;; LP begin
      if keyword_set(kid_corr_block) then kid_corr_block_1 = kid_corr_block else $
         nk_get_corr_block_3, param, info, toi, flag, off_source, kidpar, kid_corr_block_1

      ;; Subtract atmosphere and block mode at the same time
      nk_decor_common_mode_one_block, param, info, toi, flag, off_source, kidpar, $
                                      toi_out, common_mode, elevation, kid_corr_block_1, $
                                      extra_mode=atm_cm
      ;; LP end
      out_temp_data.toi = common_mode
      ;; EA and LP: add the line below
      toi = toi_out
   end
   
;;=============================================================================================================
;;=============================================================================================================
   "TEST_NP2":begin

      case strupcase(param.new_method) of
         
         "NEW_DECOR_ATM_AND_ALL_BOXES": nk_decor_atm_and_all_boxes, param, info, kidpar, toi, flag, off_source, elevation, $
            toi_out, out_temp, snr_toi=snr_toi, subscan=subscan
         
         "NEW_DECOR_ATM_AND_BOXES_PER_ARRAY": nk_decor_atm_and_boxes_per_array, param, info, kidpar, toi, flag, off_source, elevation, $
            toi_out, out_temp, snr_toi=snr_toi
         
         "NEW_DECOR_ATM_AND_SUBBANDS_PER_ARRAY": nk_decor_atm_and_subbands_per_array, param, info, kidpar, toi, flag, off_source, elevation, $
            toi_out, out_temp, snr_toi=snr_toi
         
         "NEW_DECOR_ATM_AND_SUBBANDS_PER_BOX": nk_decor_atm_and_subbands_per_box, param, info, kidpar, toi, flag, off_source, elevation, $
            toi_out, out_temp, snr_toi=snr_toi
         
         "NEW_DECOR_KID_RING": nk_decor_kid_ring, param, info, kidpar, toi, flag, off_source, elevation, $
                                                  toi_out, out_temp, snr_toi=snr_toi
         
         "NEW_DECOR_CM_AND_TRIGO": nk_decor_cm_and_trigo, param, info, kidpar, toi, flag, off_source, elevation, $
            toi_out, out_temp, dra, ddec, zm_toi, snr_toi=snr_toi
         
         "NEW_DECOR_TRIGO": nk_decor_trigo, param, info, kidpar, toi, flag, off_source, elevation, $
                                            toi_out, out_temp, dra, ddec, zm_toi, snr_toi=snr_toi
         
         "NEW_DECOR_IMCM": nk_imcm_decorr, param, info, kidpar, toi, flag, off_source, elevation, $
                                           toi_out, out_temp, snr_toi=snr_toi, out_coeffs=out_coeffs, $
                                           w8_hfnoise=w8_hfnoise

         "MASK_IMCM": begin
             nk_mask_imcm, param, info, kidpar, toi, flag, off_source, elevation, $
                           toi_out, out_temp, snr_toi=snr_toi, out_coeffs=out_coeffs, $
                           w8_hfnoise=w8_hfnoise
            
            ;; nk_imcm_decorr_1, param, info, kidpar, toi, flag, off_source, elevation, $
            ;;                   toi_out, out_temp, snr_toi=snr_toi, out_coeffs=out_coeffs, $
            ;;                   w8_hfnoise=w8_hfnoise


            ;nk_mask_imcm_cm1b, param, info, kidpar, toi, flag, off_source, elevation, $
            ;                   toi_out, out_temp
            
         end
         
         "MDC": nk_mdc, param, info, kidpar, toi, flag, off_source, elevation, $
                        toi_out, out_temp, snr_toi=snr_toi, out_coeffs=out_coeffs
         
         "EIGENVEC": nk_eigenvec, param, info, kidpar, toi, flag, off_source, toi_out, out_temp
         "EIGENVEC_BLOCK": nk_eigenvec_block, param, info, kidpar, toi, flag, off_source, toi_out, out_temp
         
         "NEW_DECOR_ATMB_PER_ARRAY": nk_decor_atmb_per_array, param, $
            info, kidpar, toi, flag, off_source, elevation, $
            toi_out, out_temp, snr_toi=snr_toi, $
            subscan = subscan, subtoi = subtoi ; FXD attempts
         else: begin
            print, ""
            message, /info, "param.new_method = "+param.new_method+" not found"
            print, ""
            stop
         end
      endcase

      toi = toi_out
      out_temp_data.toi = out_temp
   end

;;=============================================================================================================
;;=============================================================================================================

   
   ELSE: begin
      nk_error, info, "Unrecognized decorelation method: "+param.decor_method
      return
   end
endcase

end
