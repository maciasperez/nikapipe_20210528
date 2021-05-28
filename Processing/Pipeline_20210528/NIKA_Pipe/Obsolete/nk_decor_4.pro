;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_decor_4
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_handle, param, info, data, kidpar
; 
; PURPOSE: 
;        Decorrelates kids, filters...
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 09th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_decor_4, param, info, data, kidpar, out_temp_data=out_temp_data, $
                input_cm_1mm=input_cm_1mm, input_cm_2mm=input_cm_2mm


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_decor, param, info, data, kidpar"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

loadct, 39, /silent

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

nk_list_kids, kidpar, lambda=1, valid=w1mm, nvalid=nw1mm
nk_list_kids, kidpar, lambda=2, valid=w2mm, nvalid=nw2mm

do_patch = 0
if strupcase( strtrim(!nika.run,2)) eq "CRYO" then begin
   do_patch = 1
endif else begin
   if long(!nika.run) le 5 then do_patch = 1
endelse
if do_patch then begin
   w1 = where( kidpar.type eq 1, nw1)
   for i=0, nw1-1 do begin
      ikid = w1[i]
      power_spec, data.toi[ikid] - my_baseline( data.toi[ikid]), !nika.f_sampling, pw, freq
      wf = where( freq gt 4.d0)
      kidpar[ikid].noise = avg(pw[wf]) ; Jy/Beam/sqrt(Hz) since data is in Jy/Beam
   endfor
endif

;; Discard the noisiest kids from the common mode estimation
if param.lab eq 0 then begin
   if nw1mm ne 0 then begin
      noise_avg = avg( kidpar[w1mm].noise)
      sigma = stddev(  kidpar[w1mm].noise)
      w = where( kidpar[w1mm].noise le (noise_avg + 3*sigma), nw)
      if nw eq 0 then begin
         nk_error, info, "no 1mm kid with a noise closer to the average than 3 sigma."
         return
      endif
      w1mm = w1mm[w]
      nw1mm = n_elements(w1mm)
   endif

   if nw2mm ne 0 then begin
      noise_avg = avg( kidpar[w2mm].noise)
      sigma = stddev(  kidpar[w2mm].noise)
      w = where( kidpar[w2mm].noise le (noise_avg + 3*sigma), nw)
      if nw eq 0 then begin
         nk_error, info, "no 2mm kid with a noise closer to the average than 3 sigma."
         return
      endif
      w2mm = w2mm[w]
      nw2mm = n_elements(w2mm)
   endif
endif

;; Discard kids that are too uncorrelated to the other ones
if param.flag_uncorr_kid ne 0 then begin
   for i = 1, param.iterate_uncorr_kid do nk_flag_uncorr_kids, param, info, data, kidpar
   nk_list_kids, kidpar, lambda=1, valid=w1mm, nvalid=nw1mm
   nk_list_kids, kidpar, lambda=2, valid=w2mm, nvalid=nw2mm
endif

;; Determine the blocks of maximally correlated kids on the entire scan once for all
if strupcase(param.decor_method) eq "COMMON_MODE_ONE_BLOCK" and $
   param.corr_block_per_subscan eq 0 then nk_get_corr_block, param, info, data, kidpar, kid_corr_block

;;-----------------------------------------------------------------
;; Decorrelates either per subscan or on the entire scan
if strupcase(param.decor_per_subscan) eq 1 then begin

;; wind, 1, 1, /free, /large
;; my_multiplot, 1, 1, pp, pp1, ntot=max(data.subscan)-min(data.subscan)+1, /full, /rev
;; p = 0

   if info.polar ne 0 then begin
      out_temp_data = create_struct( "toi", data[0].toi, "toi_q", data[0].toi_q, "toi_u", data[0].toi_u)
   endif else begin
      out_temp_data = create_struct( "toi", data[0].toi)
   endelse
   out_temp_data = replicate( out_temp_data, n_elements(data))

   for i=min(data.subscan), max(data.subscan) do begin
       wsample = where( data.subscan eq i, nwsample)
;; Keep the slew for now, it should be masked by the source mask
;; discard slew too if it's not cut out by nk_cut_scans
;;       ;; nk_where_flag for the syntax
;;       powerOfTwo = 2L^8
;;       wsample = where( data.subscan eq i and (long(data.flag[0]) and powerOfTwo) ne powerOfTwo, nwsample)

      if nwsample lt param.nsample_min_per_subscan then begin
         message, /info, "Less than "+strtrim(param.nsample_min_per_subscan,2)+$
                  " samples in subscan "+strtrim( long(i),2)+" => do not project."
         if nwsample ne 0 then nk_add_flag, data, 8, wsample=wsample
      endif else begin

         data1 = data[wsample]
         if keyword_set(input_cm_1mm) then input_cm_1mm_1 = input_cm_1mm[*,wsample]
         if keyword_set(input_cm_2mm) then input_cm_2mm_1 = input_cm_2mm[*,wsample]
         
         ;; loadct, 39
         ;; ikid = 79 ; 190             ; 37 ; 190
         ;; plot, data1.toi[ikid], /xs, position=pp1[p,*], /noerase, yra=minmax(data.toi[ikid]), /ys
         ;; ww = where( data1.off_source[ikid] eq 1, nww)
         ;; if nww ne 0 then oplot, ww, data1[ww].toi[ikid], psym=1, col=150

         if strupcase(param.decor_method) eq "COMMON_MODE_ONE_BLOCK" then begin
            nk_decor_sub_corr_block_2, param, info, data1, kidpar, $
                                       kid_corr_block=kid_corr_block, out_temp_data=out_temp_data1

            out_temp_data[wsample].toi = out_temp_data1.toi
         endif else if strupcase(param.decor_method) eq "DUAL_BAND" then begin
            goto, dualband
         endif else begin
            nk_decor_sub, param, info, data1, kidpar, $
                          sample_index=wsample, w1mm=w1mm, w2mm=w2mm, out_temp_data=out_temp_data1, $
                          input_cm_1mm=input_cm_1mm_1, input_cm_2mm=input_cm_2mm_1
            out_temp_data[wsample].toi = out_temp_data1.toi

            if info.polar ne 0 then begin
               data[wsample].toi_q = data1.toi_q
               data[wsample].toi_u = data1.toi_u
               out_temp_data[wsample].toi_q = out_temp_data1.toi_q
               out_temp_data[wsample].toi_u = out_temp_data1.toi_u
            endif
         endelse

         ;; oplot, out_temp_data1.toi[ikid], col=250
         ;; p++

         data[wsample].toi = data1.toi
      endelse
   endfor

endif else begin
   ;; decorrelate on the entire scan
   if strupcase(param.decor_method) eq "COMMON_MODE_ONE_BLOCK" then begin
      nk_decor_sub_corr_block_2, param, info, data, kidpar, kid_corr_block=kid_corr_block, out_temp_data=out_temp_data
   endif else begin
      nk_decor_sub, param, info, data, kidpar, w1mm=w1mm, w2mm=w2mm, out_temp_data=out_temp_data, $
                    input_cm_1mm=input_cm_1mm, input_cm_2mm=input_cm_2mm
   endelse

endelse
;;stop

;; nk_list_kids, kidpar, lambda=1, valid=w1mm, nval=nw1mm
;; wind, 1, 1, /free, /large
;; my_multiplot, 1, 1, pp, pp1, ntot=nw1mm, /full, /rev
;; loadct, 39
;; for i=0, nw1mm-1 do begin &$
;;    !p.charsize=1e-10 &$
;;    !x.charsize=1e-10 &$
;;    !y.charsize=1e-10 &$
;;    plot, data.toi[w1mm[i]], /xs, position=pp1[i,*], /noerase, yra=minmax(data.toi[w1mm]), /ys &$
;;    legendastro, strtrim(w1mm[i],2), textcol=250, box=0, charsize=1 &$
;; endfor
;; stop

dualband:

if strupcase(param.decor_method) eq "DUAL_BAND" then begin
   for i=0, param.n_decor_freq_bands-1 do begin
      junk = execute( "freqmin  = param.decor_freq_low"+strtrim(i,2))
      junk = execute( "freqhigh = param.decor_freq_high"+strtrim(i,2))
      nk_band_freq_decor, param, info, data, kidpar, freqmin, freqhigh, out_temp_data=out_temp_data1
   endfor
   out_temp_data.toi = out_temp_data1.toi
endif

if param.cpu_time then nk_show_cpu_time, param, "nk_decor_4"

end
