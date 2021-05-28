;+
; 
; SOFTWARE: 
;        NIKA pipeline
;
; NAME:
; nk_nan_and_zero_flag
; 
; PURPOSE: 
;        Sets data.flag to 2L^7 when samples have NaN or zero valued
; 
; INPUT: 
;        - param: the parameter structure
;        - info: the information structure
;        - data
;        - kidpar
; 
; OUTPUT: 
;        - data.flag is modified
; 
; KEYWORDS:
;        NONE
; 
; MODIFICATION HISTORY: 
;        - 13/03/2014: creation from nika_pipe_getdata.pro 
;        (Nicolas Ponthieu - nicolas.ponthieu@obs.ujf-grenoble.fr)
;        - Nov 12, 2014: FXD and NP
;-
;====================================================================================================

pro nk_nan_and_zero_flag, param, info, data, kidpar

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; nkids = n_elements(data[0].toi)
;; for ikid=0,nkids-1 do begin
;;    l = where(finite(data[*].toi[ikid]) eq 0, nl)
;;    ;;if nl gt 0 then data[l].flag[ikid] += 2l^18
;; 
;;    ;; Set flag to 7, according to documentation, so tell that the sample value
;;    ;; was not correctly computed (whatever the reason)
;;    if nl gt 0 then data[l].flag[ikid] += 2L^7
;; endfor 

;; To avoid loops
tags = tag_names(data)
wi = where( strupcase(tags) eq "I", nwi)
;;if tag_exist(data,"I") then begin
if nwi ne 0 then begin
 nan_flag = long( finite(data.toi) eq 0 or data.i eq 0 or data.q eq 0) ; to initialize good samples to 0
endif else begin
   nan_flag = long( finite(data.toi) eq 0) ; to initialize good samples to 0
endelse
w = where( nan_flag eq 1, nw)   ; i.e. finite = 0 or data.i=0 or data.q=0
if nw ne 0 then begin
   nan_flag[w] = 2L^7
   data.flag += long(nan_flag)
endif

if param.cpu_time then nk_show_cpu_time, param, "nk_nan_and_zero_flag"

end
