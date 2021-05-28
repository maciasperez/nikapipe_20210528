
pro nk_param2list_detector, param, info, list_detector=list_detector

if n_params() lt 1 then begin
   message, /info, "calling sequence:"
   print, "nk_param2list_detector, param, info, list_detector"
   return
endif

;; check requests consistency
t = 0
if param.one_mm_only eq 1 then t++
if param.two_mm_only eq 1 then t++

if t gt 1 then begin
   message, /info, "You have requested inconsistent lists of detectors, "
   message, /info, "through parameters such as param.one_mm_only, param.two_mm_only."
   message, /info, "Please check the following parameters and re-launch."
   print, "param.one_mm_only: ", param.one_mm_only
   print, "param.two_mm_only: ", param.two_mm_only
   nk_error, info, "incompatible requests on list_detector"
   return
endif

;; Input kidpar or input list_detector
if strlen( param.file_kidpar) ne 0 and (not keyword_set(list_detector)) then begin
   if not param.silent then message, /info, "Input kidpar = "+strtrim( param.file_kidpar,2)
   if file_test( param.file_kidpar) ne 1 then begin
      nk_error, info, 'This requested param.file_kidpar does not exist: '+ strtrim(param.file_kidpar,2)
      return
   endif
   kidpar_a = mrdfits( param.file_kidpar, 1, /silent)
   
   if param.rta eq 1 then begin
      ;; wread = where( kidpar_a.rta eq 1, nwread)
      ;; Change this because .rta is not updated at the end of the geometry
      ;; reduction: LP+NP, March 22nd, 2016
      wread = where( kidpar_a.rta eq 1 and kidpar_a.type eq 1, nwread)
   endif else begin
      wread = where( kidpar_a.type ne 0, nwread)
   endelse
   
   if nwread eq 0 then begin
      txt = 'No kid can be read from the current kidpar.'
      nk_error, info, txt
      message, /info, txt
      return
   endif
   
   if tag_exist( kidpar_a, "raw_num") then begin
      list_detector = long( kidpar_a[wread].raw_num)
   endif else begin
      ;; run5
      list_detector = long( kidpar_a[wread].numdet)
   endelse
endif else begin
   if not keyword_set(read_type) then read_type = 12
endelse

;; Here, either list_detector was provided as input keyword or
;; initialized from param.file_kidpar
if long(!nika.run) le 12 then begin
   if param.one_mm_only eq 1 then list_detector = lindgen(400)       ; read_array = 1
   if param.two_mm_only eq 1 then list_detector = lindgen(400) + 400 ; read_array = 2
endif

;; Obsolete with new acquisition
;;    ;; default, keep all list_detector
;;    if param.one_mm_only eq 1 then begin
;;       w = where( list_detector ge 1600, nw)
;;       if nw eq 0 then begin
;;          txt = "No 1mm kid found while param.one_mm_only set to 1"
;;          nk_error, info, txt
;;          return
;;       endif else begin
;;          list_detector = list_detector[w]
;;       endelse
;;    endif
;;    
;;    if param.two_mm_only eq 1 then begin
;;       w = where( list_detector ge 0 and list_detector lt 1600, nw)
;;       if nw eq 0 then begin
;;          txt = "No 1mm kid found while param.one_mm_only set to 1"
;;          nk_error, info, txt
;;          return
;;       endif else begin
;;          list_detector = list_detector[w]
;;       endelse
;;    endif

;;endelse
  
end
     
