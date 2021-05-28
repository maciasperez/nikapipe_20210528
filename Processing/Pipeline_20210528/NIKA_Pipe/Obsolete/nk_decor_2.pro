;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_decor_2
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

pro nk_decor_2, param, info, data, kidpar, out_temp_data=out_temp_data

on_error, 2

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
   w1mm = w1mm[w]
endif

if nw2mm ne 0 then begin
   noise_avg = avg( kidpar[w2mm].noise)
   sigma = stddev(  kidpar[w2mm].noise)
   w = where( kidpar[w2mm].noise le (noise_avg + 3*sigma), nw)
   w2mm = w2mm[w]
endif

;;-----------------------------------------------------------------
;; Decorrelate, filters... either per subscan or on the entire scan
if strupcase(param.decor_per_subscan) eq "YES" then begin

   if info.polar ne 0 then begin
      ;;out_temp_data = {toi:data.toi*0.d0, toi_q:data.toi_q, toi_u:data.toi_u}
      out_temp_data = create_struct( "toi", data[0].toi, "toi_q", data[0].toi_q, "toi_u", data[0].toi_u)
   endif else begin
      ;;out_temp_data = {toi:data.toi*0.d0}
      out_temp_data = create_struct( "toi", data[0].toi)
   endelse
   out_temp_data = replicate( out_temp_data, n_elements(data))

   for i=min(data.subscan), max(data.subscan) do begin
      wsample = where( data.subscan eq i, nwsample)
      if nwsample lt param.nsample_min_per_subscan then begin
         ;; do not project
         message, /info, "Less than "+strtrim(param.nsample_min_per_subscan,2)+" samples in subscan "+strtrim( long(i),2)+" => do not project."
         if nwsample ne 0 then nk_add_flag, data, 8, wsample
      endif else begin
         ;print, "subscan, nwsample: ", i, nwsample
         data1 = data[wsample]
         nk_decor_sub_2, param, info, data1, kidpar, $
                       sample_index=wsample, w1mm=w1mm, w2mm=w2mm, out_temp_data=out_temp_data1
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
   nk_decor_sub_2, param, info, data, kidpar, w1mm=w1mm, w2mm=w2mm, out_temp_data=out_temp_data

endelse


;;------------------------------------------------------------------
;; Monitor the atmosphere via the common mode if requested
if param.do_meas_atmo ne 0 then begin
   if defined(common_mode) eq 0 then begin
      nk_error, info, "common_mode has not been computed", status=2
      return
   endif
   nk_measure_atmo, param, info, data, kidpar, common_mode
endif

if param.cpu_time then nk_show_cpu_time, param, "nk_decor"

end
