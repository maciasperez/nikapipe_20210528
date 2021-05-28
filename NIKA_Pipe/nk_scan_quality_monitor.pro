;+
;
; SOFTWARE: 
;        NIKA pipeline, atmosphere monitoring
;
; NAME: 
;        nk_scan_quality_monitor
;
; CATEGORY: 
;
; CALLING SEQUENCE:
;         nk_scan_quality_monitor, param, info, data, kidpar, out_temp_data
; 
; PURPOSE: 
;        Monitors the atmosphere and tries to asses
;        the scan quality a priori.
; 
; INPUT:
;        param, info, data, kidpar
;       
; OUTPUT: 
;        - info is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - March 8th, 2018: NP, extracted from nk_scan_reduce.pro and
;          slightly upgraded.
;-

pro nk_scan_quality_monitor, param, info, data, kidpar, out_temp_data

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_scan_quality_monitor, param, info, data, kidpar, out_temp_data"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

if param.do_meas_atmo ne 0 then begin
   nsn = n_elements(data)
   common_mode = dblarr(2,nsn)
   nk_list_kids, kidpar, lambda=1, valid=w1mm, nval=nw1mm
   nk_list_kids, kidpar, lambda=2, valid=w2mm, nval=nw2mm
   if nw1mm ne 0 then common_mode[0,*] = out_temp_data.toi[w1mm[0]]
   if nw2mm ne 0 then common_mode[1,*] = out_temp_data.toi[w2mm[0]]
   nk_measure_atmo, param, info, data, kidpar, common_mode
endif

if param.give_scan_quality eq 1 then begin
   for iarray=1, 3 do begin
      w = where( kidpar.type eq 1 and kidpar.numdet eq !nika.ref_det[iarray-1], nw)
      if nw ne 0 then begin
         if defined(out_temp_data) then begin
            power_spec, out_temp_data.toi[w], !nika.f_sampling, pw_raw, freq
         endif else begin
            power_spec, data.toi[w], !nika.f_sampling, pw_raw, freq
         endelse
         power_spec, data.toi[w], !nika.f_sampling, pw

         ;; wl = where( freq le param.scan_quality_freq, compl=wh)
         ;; We must also set a lower bound to the frequency band over
         ;; which we integrate, otherwise, long duration have more low
         ;; frequency content and this might bias what we want to
         ;; measure here. Very low frequencies are not hard to
         ;; decorrelate, it's sky noise that matters.
         wl = where( freq ge param.scan_quality_low_freq and $
                     freq le param.scan_quality_freq, compl=wh, nwl, ncompl=nwh)
         if nwl ne 0 and nwh ne 0 then begin
            junk = execute( "info.result_atm_quality_"+strtrim(iarray,2)+" = total( pw_raw[wl]^2)/total( pw_raw[wh]^2)")
            junk = execute( "info.result_scan_quality_"+strtrim(iarray,2)+" = total( pw[wl]^2)/total( pw[wh]^2)")
         endif
      endif
   endfor
endif

if param.cpu_time then nk_show_cpu_time, param
end
