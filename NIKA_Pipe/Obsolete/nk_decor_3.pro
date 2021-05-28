;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_decor_3
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
;        - April 09th, 2014: nk_decor.pro : creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;        - Dec. 18th, 2014: nk_decor_3 to compute the kid correlation matrix
;          once for all and use it in nk_decor_sub_3.
;-

pro nk_decor_3, param, info, data, kidpar, out_temp_data=out_temp_data

on_error, 2

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_decor_3, param, info, data, kidpar, out_temp_data=out_temp_data"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

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

;; Discard kids that are too uncorrelated to the other ones
if param.flag_uncorr_kid ne 0 then begin
   nk_flag_uncorr_kids, param, info, data, kidpar
   nk_list_kids, kidpar, lambda=1, valid=w1mm, nvalid=nw1mm
   nk_list_kids, kidpar, lambda=2, valid=w2mm, nvalid=nw2mm
endif

;; If required, computes the kid-kid correlation matrix
if strupcase( strtrim(param.decor_method,2)) eq "COMMON_MODE_ONE_BLOCK" then begin
   nsn    = n_elements( data)
   indice = dindgen(nsn)
   nkids  = n_elements(kidpar)

   mcorr = correlate( data.toi)
   wnan  = where(finite(mcorr) ne 1, nwnan)
   if nwnan ne 0 then mcorr[wnan] = -1

   ;; init blocks of correlated kids to -1
   kid_corr_block   = intarr(nkids,nkids) - 1

   atm_x_calib      = dblarr(nkids,2)
   atm_x_calib[*,1] = 1.d0
   
   for lambda=1, 2 do begin

      if lambda eq 1 then begin
         w1  =  w1mm
         nw1 = nw1mm
      endif else begin
         w1  =  w2mm
         nw1 = nw2mm
      endelse
      
      if nw1 ne 0 then begin
         ;; Cross-calibration
         atm_x_calib[w1,*] = nika_pipe_atmxcalib(data.toi[w1], 1-data.off_source[w1])

         ;; Derive block of maximally correlated kids and compute the relevant
         ;; common mode
         for i=0, nw1-1 do begin
            ikid = w1[i]

            ;; Search for best set of KIDs to be used for deccorelation
            corr = reform(mcorr[ikid,*])

            ;; Do not use discarded kids nor kids from the other matrix
            wbad = where(kidpar.type ne 1 or kidpar.array ne kidpar[ikid].array, nwbad)
            if nwbad ne 0 then corr[wbad] = -1

            ;; Sort by order of maximum correlation
            s_corr = corr[reverse(sort(corr))]
     
            ;; First block with the requested min number of KIDs
            block = where(corr gt s_corr[param.n_corr_block_min+1] and corr ne 1, nblock)

            ;; Then add KIDs and if they are correlated enough  
            sd_block   = stddev(corr[block])
            mean_block = mean(corr[block])
            iter = 1 ; 2
            test = 'ok'
            while test eq 'ok' and (param.n_corr_block_min+iter) lt nw1-2 do begin
               if s_corr[param.n_corr_block_min+iter] lt mean_block-param.nsigma_corr_block*sd_block $
               then test = 'pas_ok' $
               else block = where(corr gt s_corr[param.n_corr_block_min+iter] and corr ne 1, nblock)
               iter += 1
            endwhile
     
            kid_corr_block[ikid,0:nblock-1] = block
         endfor
      endif
   endfor
endif

;;-----------------------------------------------------------------
;; Decorrelates, filters... either per subscan or on the entire scan
if strupcase(param.decor_per_subscan) eq "YES" then begin
   
   if info.polar ne 0 then begin
      out_temp_data = create_struct( "toi", data[0].toi, "toi_q", data[0].toi_q, "toi_u", data[0].toi_u)
   endif else begin
      out_temp_data = create_struct( "toi", data[0].toi)
   endelse
   out_temp_data = replicate( out_temp_data, n_elements(data))
   
;;;;;;;;;;;;;;;
;message, /info, "fix me:"
;   stop
   for i=min(data.subscan), max(data.subscan) do begin
;for i=param.subscan_test, param.subscan_test do begin
;stop
;;;;;;;;;;;
      wsample = where( data.subscan eq i, nwsample)
      if nwsample lt param.nsample_min_per_subscan then begin
         ;; do not project
         message, /info, "Less than "+strtrim(param.nsample_min_per_subscan,2)+$
                  " samples in subscan "+strtrim( long(i),2)+" => do not project."
         if nwsample ne 0 then nk_add_flag, data, 8, wsample
      endif else begin
         
         data1 = data[wsample]
         nk_decor_sub_3, param, info, data1, kidpar, $
                         sample_index=wsample, w1mm=w1mm, w2mm=w2mm, $
                         out_temp_data=out_temp_data1, $
                         kid_corr_block=kid_corr_block
         nk_filter, param, info, data1, kidpar
         
         data[wsample].toi = data1.toi
         out_temp_data[wsample].toi = out_temp_data1.toi
         if info.polar ne 0 then begin
            data[wsample].toi_q = data1.toi_q
            data[wsample].toi_u = data1.toi_u
            out_temp_data[wsample].toi_q = out_temp_data1.toi_q
            out_temp_data[wsample].toi_u = out_temp_data1.toi_u
         endif
      endelse
   endfor

endif else begin
   nk_decor_sub_3, param, info, data, kidpar, w1mm=w1mm, w2mm=w2mm, $
                   out_temp_data=out_temp_data, $
                   kid_corr_block=kid_corr_block
   nk_filter, param, info, data, kidpar
endelse

if param.cpu_time then nk_show_cpu_time, param, "nk_decor"

end
