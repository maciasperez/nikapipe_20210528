
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_nasmyth2draddec
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_nasmyth2draddec, param, info, data, kidpar
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
;        - data.dra, data.ddec
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug, 2nd, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-
;===============================================================================================

pro nk_nasmyth2draddec, param, info, data, kidpar, ofs_az, ofs_el
  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nkids = n_elements(kidpar)

nk_nasmyth2dazdel, param, info, data, kidpar, daz, del, daz1, del1

cos_para = cos(data.paral)##( dblarr(nkids)+1)
sin_para = sin(data.paral)##( dblarr(nkids)+1)

;; dx = -daz + ofs_az##( dblarr(nkids)+1)
;; dy = -del + ofs_el##( dblarr(nkids)+1)

;;data.dra  =  cos_para*dx + sin_para*dy
;;data.ddec = -sin_para*dx + cos_para*dy

;; ;; change paral sign (dec. 2018)
;; data.dra  = cos_para*dx - sin_para*dy
;; data.ddec = sin_para*dx + cos_para*dy

dx = daz + ofs_az##( dblarr(nkids)+1)
dy = del + ofs_el##( dblarr(nkids)+1)
data.dra  = -cos_para*dx + sin_para*dy
data.ddec =  sin_para*dx + cos_para*dy

add_warning, "Changed signs and rotation in nk_nasmyth2draddec"
if param.cpu_time then nk_show_cpu_time, param, "nk_nasmyth2draddec"


end
