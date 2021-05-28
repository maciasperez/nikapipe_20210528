;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_fake_lissajous_subscans
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_fake_lissajous_subscans, param, info, data, kidpar
; 
; PURPOSE: 
;        Decorrelates kids, filters...
;        This is the core of nk_decor.pro that only dispatches per_subscan or not
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data.subscan is modified
; 
; KEYWORDS:
;        - None
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 9th, 2015: generate fake subscan index when the azimuth
;          changes direction
;-

pro nk_fake_lissajous_subscans, param, info, data, kidpar


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_decor, param, info, data, kidpar, sample_index=sample_index, w1mm=w1mm, w2mm=w2mm"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nsn = n_elements(data)

;; v_az = deriv( data.ofs_az)
;; i=0
;; v_sign_current = sign(v_az[i])
;; data.subscan = 1 ; init
;; while i le (nsn-1) do begin
;;    s = sign(v_az[i])
;;    if s ne v_sign_current and s ne 0 then begin
;;    data[i:*].subscan += 1
;;    v_sign_current = s
;;    endif
;;    i++
;; endwhile

index = dindgen(nsn)
;;nsubscans = 10 ; 5 ; 10 ; place holder
tsubscan = 30. ; sec, place holder
nsubscans = long( nsn/!nika.f_sampling/tsubscan)
nsn_per_subscan = long( nsn/nsubscans)
data.subscan = 1 + long(index/nsn_per_subscan)



end
