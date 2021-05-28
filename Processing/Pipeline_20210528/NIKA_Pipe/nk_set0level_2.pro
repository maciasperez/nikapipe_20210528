;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
;   nk_set0level_2
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_set0level_2, param, info, data, kidpar
; 
; PURPOSE: 
;        Subtract the mean of each kid outside the source to ensure that each
;subscan has a correct background zero level.
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
;        - Nov. 26th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;        - June 26th,2015: back to version before June ,16th (revision
;          7568), we subtract an average per kid    

pro nk_set0level_2, param, info, data, kidpar
;-
  
if n_params() lt 1 then begin
   dl_unix, 'nk_set0level_2'
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

if param.set_zero_level_full_scan eq 1 then begin
   if param.log then nk_log, info, "set zero level per KID on the entire scan"
   nsn = n_elements(data)
   wscan = lindgen(nsn)
   nk_set0level_sub, param, info, data, kidpar, wscan
endif

if param.set_zero_level_per_subscan eq 1 then begin
   for isubscan=min(data.subscan), max(data.subscan) do begin
      info.CURRENT_SUBSCAN_NUM = isubscan
      if param.log then nk_log, info, "set zero level per KID on subscan "+strtrim(isubscan,2)
      wsubscan = where( data.subscan eq isubscan, nwsubscan)
      if nwsubscan gt 1 then begin
         nk_set0level_sub, param, info, data, kidpar, wsubscan
      endif
   endfor
endif

; Do the checking here rather than in the subroutine
nsn = n_elements(data)
wscan = lindgen(nsn)
nk_set0level_check, param, info, data, kidpar, wscan

if param.cpu_time then nk_show_cpu_time, param

end
