;+
;
; SOFTWARE: NIKA pipeline (realtime analysis)
;
; NAME: 
; nk_get_log_info
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_get_log_info, param, info, data, log_info
; 
; PURPOSE: 
;        Extract relevant information for the logbook
; 
; INPUT: 
;        - param, info, data
; 
; OUTPUT: 
;        - log_info: a structure that will be saved to disk and
;          further used by nk_logbook_sub and nk_logbook.pro
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Jan 13th, 2016: NP, ported nika_get_log_info
;-


pro nk_get_log_info, param, info, data, log_info

nres = 100 ; should be large enough :-)
if defined( data) then nsn = n_elements( data)

; opacity
tau1 = -1
tau2 = -1

fmts = "(F5.2)"
if defined( data) then begin
   melev = string(data[nsn/2].el*!radeg , format=fmts)
endif else begin
   melev = 0.
endelse


if tag_exist( info, 'ATMO_AMPLI_1MM') then begin
   ATMO_AMPLI_1MM = info.ATMO_AMPLI_1MM
   ATMO_SLOPE_1MM = info.ATMO_SLOPE_1MM
   ATMO_AMPLI_2MM = info.ATMO_AMPLI_2MM
   ATMO_SLOPE_2MM = info.ATMO_SLOPE_2MM
endif else begin
   ATMO_AMPLI_1MM = info.result_ATMO_AMPLI_1MM
   ATMO_SLOPE_1MM = info.result_ATMO_SLOPE_1MM
   ATMO_AMPLI_2MM = info.result_ATMO_AMPLI_2MM
   ATMO_SLOPE_2MM = info.result_ATMO_SLOPE_2MM
endelse

log_info = {scan_num:strtrim(param.scan_num, 2), $
            ut:'', $
            day:param.day, $
            source:param.source, $
            scan_type:'', $
            mean_elevation: melev, $
            tau225:strtrim( string(info.tau225,form='(F4.2)'),2), $
            tau_1mm: string(info.result_tau_1mm, format=fmts), $
            tau_2mm: string(info.result_tau_2mm, format=fmts), $
            atmo_ampli_1mm: num2string(ATMO_AMPLI_1MM), $
            slope_1mm: num2string(ATMO_SLOPE_1MM), $
            atmo_ampli_2mm: num2string(ATMO_AMPLI_2MM), $
            slope_2mm: num2string(ATMO_SLOPE_2MM), $
            result_name:strarr(nres), $
            result_value:dblarr(nres)+!values.d_nan, $
            comments:'', $
            az:0., $
            el:0.}

end
