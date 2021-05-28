
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_dazdel2draddec
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_dazdel2draddec, param, info, data, kidpar
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

pro nk_dazdel2draddec, param, info, data, kidpar
  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nkids = n_elements(kidpar)

;; No improvement on the computation time using rebin or restricting
;; to valid kids (even worse in the latter case). NP Dec. 8th, 2016
cos_para = cos(data.paral)##( dblarr(nkids)+1)
sin_para = sin(data.paral)##( dblarr(nkids)+1)

;; This routine is called after nk_nasmyth2azel that puts az,el into
;; data.dra and data.ddec
;; dra       =  cos_para*data.dra + sin_para*data.ddec
;; data.ddec = -sin_para*data.dra + cos_para*data.ddec

;; After we've changed the convention on the parallactic angle (dec. 2018)
dra       = -cos_para*data.dra + sin_para*data.ddec
data.ddec =  sin_para*data.dra + cos_para*data.ddec
data.dra  = dra

if param.cpu_time then nk_show_cpu_time, param


end
