;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_log
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_error, info, message
; 
; PURPOSE: 
;        records comments during data processing in a logfile
; 
; INPUT: 
;        - info: an information structure to be filled
;        - message: the message to record
; 
; OUTPUT: 
;        - info: updated with the message
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - NP, March 13t, 2020

pro nk_log, info, message
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_log'
   return
endif

junk = scope_traceback()
nj   = n_elements(junk)
;; the last element of junk is "nk_log"
j = (nj-2)>0
routine = file_basename(junk[j])

openw, lu, info.logfile, /append, /get_lun
printf, lu, strtrim(routine,2)+": "+message
close, lu
free_lun, lu

end
