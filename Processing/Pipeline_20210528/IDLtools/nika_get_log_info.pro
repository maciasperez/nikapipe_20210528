
;; Computes a few generic useful informations about the scan to put in the
;; logbook

pro nika_get_log_info, scan_num, day, data, log_info, kidpar=kidpar


nres = 100 ; should be large enough :-)
if defined( data) then nsn = n_elements( data)

; opacity
tau1 = -1
tau2 = -1
if keyword_set(kidpar) then begin
   w11 = where( kidpar.type eq 1 and kidpar.array eq 1, nw11)
   w12 = where( kidpar.type eq 1 and kidpar.array eq 2, nw12)
   if nw11 ne 0 then tau1 = kidpar[w11[0]].tau_skydip
   if nw12 ne 0 then tau2 = kidpar[w12[0]].tau_skydip
endif

fmts = "(F5.2)"
if defined( data) then $
   melev = string(data[nsn/2].el*!radeg , format=fmts) else $
      melev = 0.

log_info = {scan_num:strtrim(scan_num, 2), $
            ut:0.d0, $
            day:day, $
            source:'source', $
            scan_type:'', $
            mean_elevation: melev, $
            tau_1mm: string(tau1, format=fmts), $
            tau_2mm: string(tau2, format=fmts), $
            atmo_ampli_1mm: num2string(), $
            slope_1mm: num2string(), $
            atmo_ampli_2mm: num2string(), $
            slope_2mm: num2string(), $
            result_name:strarr(nres), $
            result_value:dblarr(nres)+!values.d_nan, $
            comments:''}

end
