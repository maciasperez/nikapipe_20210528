;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_cpu_time
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_cpu_time, param
; 
; PURPOSE: 
;        Determines in which routine it is called and get systime info
;to monitor computation speed.
; 
; INPUT: 
;        - param
; 
; OUTPUT: 
;        - param.cpu_t0 is modified
; 
; KEYWORDS:
;        - get: to obtain systime info
;
; SIDE EFFECT:
;       - creates param.cpu_time_summary_file and param.cpu_date_file
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - NP, Nov. 2015
;-

pro nk_cpu_time, param, get = get

if param.cpu_time eq 0 then return


if keyword_set(get) then begin
   param.cpu_t0 =  systime(0,  /sec)
endif else begin

   junk = scope_traceback()
   nj   = n_elements(junk)
   j = (nj-2)>0
   routine = file_basename(junk[j])
   nk_show_cpu_time, param, routine
endelse

end
