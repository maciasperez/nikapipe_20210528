
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
;nk_nasmyth2azel
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_nasmyth2azel, param, info, data, kidpar
; 
; PURPOSE: 
;        Computes kids individual pointing in (az,el)
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the nika data structure
;        - kidpar: the kids strucutre
; 
; OUTPUT: 
;        - data.dra, data.ddec (named dra and ddec, but will contain az, el)
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug, 2nd, 2014: creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr)
;        - Aug. 13th, 2015: Added ofs_az and ofs_el to replace data.ofs_az and
;          data.ofs_el that must be left unchanged for further call.
;-
;===============================================================================================

pro nk_nasmyth2azel, param, info, data, kidpar, ofs_az, ofs_el
  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nkids = n_elements( kidpar)

nk_nasmyth2dazdel, param, info, data, kidpar, daz, del, daz1, del1

;; ;; ?!?
;; w1 = where( kidpar.type eq 1, nw1)
;; data.elev_offset = reform(del[w1[0],*])

;; Add the pointing center coordinates
;; Sept. 23rd, 2014
;; data.dra  = daz - ofs_az##( dblarr(nkids)+1)
;; data.ddec = del - ofs_el##( dblarr(nkids)+1)
;; if info.polar eq 2 then begin
;; ;;   data.dra1  = daz1 - ofs_az##( dblarr(nkids)+1)
;; ;;   data.ddec1 = del1 - ofs_el##( dblarr(nkids)+1)
;; endif

; ;; Change the sign convention of offsets
; ;; NP, Oct. 26th, 2015
; data.dra  = -daz + ofs_az##( dblarr(nkids)+1)
; data.ddec = -del + ofs_el##( dblarr(nkids)+1)

;; dec. 2018
data.dra  = daz + ofs_az##( dblarr(nkids)+1)
data.ddec = del + ofs_el##( dblarr(nkids)+1)

if param.cpu_time then nk_show_cpu_time, param

end
