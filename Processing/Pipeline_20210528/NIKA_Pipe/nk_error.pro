;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_error
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_error, routine, info, error_message
; 
; PURPOSE: 
;        Exit smoothly from a subroutine in case of crash
; 
; INPUT: 
;        - routine: name of the routine in which nk_error is called
;        - info: an information structure to be filled
; 
; OUTPUT: 
;        - info: updated with the status and error message
; 
; KEYWORDS:
;        - status: 1 by default (0 means everything's fine => no need to
;                  break). This keyword is present in case the user wants to define more
;                  specific status in the future.
;                  1: fatal error
;                  2: warning only
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 08th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)

pro nk_error, info, error_message, status=status, silent=silent
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_error'
   return
endif

if not keyword_set(status) then status=1

junk = scope_traceback()
nj   = n_elements(junk)

;; the last element of junk is "nk_error"
j = (nj-2)>0
routine = file_basename(junk[j])

info.status        = status
info.routine       = routine
if not keyword_set(silent) then begin
   if status eq 1 then begin
      info.error_message = "scan "+info.scan+": FATAL: "+error_message
   endif else begin
      info.error_message = "scan "+info.scan+": WARNING: "+error_message
   endelse
endif
get_lun, lu
openw,  lu, info.error_report_file, /append
printf, lu, strtrim(info.scan,2)+", "+strtrim(info.routine,2)+": "+strtrim( error_message, 2)
close,  lu
free_lun, lu

;stop
if not keyword_set(silent) then begin
   print, ""
;   print, "-------------------------------------------------------------------------------------"
   print, routine
   message, /info, info.error_message
endif

end
