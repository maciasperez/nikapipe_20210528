
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_draddec2dglondglat
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_draddec2dglondglat, param, info, data, kidpar
; 
; PURPOSE: 
;        Converts KID's pointing offsets from radec to galactic offsets
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the nika data structure
;        - kidpar: the kids strucutre
; 
; OUTPUT: 
;        - data.dra, data.ddec
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Dec. 8th, 2017: NP
;-
;===============================================================================================

pro nk_draddec2dglondglat, param, info, data, kidpar, ofs_az, ofs_el
  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_draddec2dglondglat, param, info, data, kidpar, ofs_az, ofs_el"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; Derive offsets in RaDec
nk_nasmyth2azel,   param, info, data, kidpar, ofs_az, ofs_el
nk_dazdel2draddec, param, info, data, kidpar

;; Convert the source coordinates from Gal to RADEc
euler, info.longobj, info.latobj, ra_center, dec_center, 2

;; Compute absolute galactic coordinates
;; Mind the "-" sign in front of data.dra because our internal
;; convention in the pipeline for RA is opposite to the true RA.
euler, ra_center  + data.dra/3600.d0/cos(dec_center*!dtor), $
       dec_center + data.ddec/3600.d0, glon, glat, 1

;; Compute offsets in galactic coordinates
;; and change the sign of RA
data.dra  =  (glon-info.longobj)*3600.d0
data.ddec =  (glat-info.latobj) *3600.d0

;plot, data.dra[0], data.ddec[0], /iso
;stop

if param.cpu_time then nk_show_cpu_time, param

end
