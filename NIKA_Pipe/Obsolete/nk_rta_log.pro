
;+
;
; SOFTWARE: Real time analysis
;
; NAME: 
; nk_rta_log
;
; CATEGORY: general, RTA
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Keeps record of main results for the logbook
; 
; INPUT:
;      - param, info, data, kidpar
; 
; OUTPUT:
;      param.plot_dir+"/log_info.save"
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Sept. 25th, 2014: NP
;-
;================================================================================================

pro nk_rta_log, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_rta_log, param, info, data, kidpar"
   return
endif

nk_get_log_info, param, info, data, log_info

p=0
log_info.source    = param.source
log_info.scan_type = info.obs_type
log_info.result_name[ p] = "flux 1mm"
log_info.result_value[p] = num2string( info.result_flux_I_1mm)
p++
if info.polar ne 0 then begin
   log_info.result_name[ p] = "flux Q 1mm"
   log_info.result_value[p] = num2string( info.result_flux_Q_1mm)
   p++
   log_info.result_name[ p] = "flux U 1mm"
   log_info.result_value[p] = num2string( info.result_flux_U_1mm)
   p++
endif
log_info.result_name[ p] = "flux 2mm"
log_info.result_value[p] = num2string( info.result_flux_I_2mm)
if info.polar ne 0 then begin
   p++
   log_info.result_name[ p] = "flux Q 2mm"
   log_info.result_value[p] = num2string( info.result_flux_Q_2mm)
   p++
   log_info.result_name[ p] = "flux U 2mm"
   log_info.result_value[p] = num2string( info.result_flux_U_2mm)
   p++
endif

save, file=param.plot_dir+"/log_info.save", log_info

spawn, "mv "+param.plot_dir+"/maps_"+param.scan+".png "+param.plot_dir+"/plot_"+param.scan+".png"
nk_logbook_sub, param.scan_num, param.day
nk_logbook, param.day

end
