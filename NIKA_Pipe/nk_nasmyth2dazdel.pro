;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_nasmyth2dazdel
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
;        - Aug, 2nd, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-
;===============================================================================================

pro nk_nasmyth2dazdel, param, info, data, kidpar, daz, del, daz1, del1
  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nkids = n_elements( kidpar)

;; Compute offsets w.r.t. pointing center
alpha = alpha_nasmyth( data.el)

;dx = kidpar.nas_x - kidpar.nas_center_x + param.fpc_dx
;dy = kidpar.nas_y - kidpar.nas_center_y + param.fpc_dy

dx = -(kidpar.nas_x - kidpar.nas_center_x + param.fpc_dx)
dy = -(kidpar.nas_y - kidpar.nas_center_y + param.fpc_dy)

if param.new_rot_center eq 1 then begin
;;    dx = kidpar.nas_x - info.nasmyth_offset_x
;;    dy = kidpar.nas_y - info.nasmyth_offset_y

   if !nika.run ge 11 then begin
      xc0 = kidpar.nas_center_x - kidpar.nas_x_offset_ref
      yc0 = kidpar.nas_center_y - kidpar.nas_y_offset_ref
   endif else begin
      ;; Leave old formula
      xc0 = kidpar.nas_center_x - info.nasmyth_offset_x
      yc0 = kidpar.nas_center_y - info.nasmyth_offset_y
   endelse

   dx = kidpar.nas_x - (xc0 + info.nasmyth_offset_x)
   dy = kidpar.nas_y - (yc0 + info.nasmyth_offset_y)
endif

daz   = cos(alpha)##dx - sin(alpha)##dy
del   = sin(alpha)##dx + cos(alpha)##dy

;; Add pointing corrections if any
daz += param.fpc_az
del += param.fpc_el


if param.cpu_time then nk_show_cpu_time, param

end
