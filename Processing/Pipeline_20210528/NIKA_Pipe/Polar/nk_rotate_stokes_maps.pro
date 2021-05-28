;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_rotate_map
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_rotate_stokes_maps, map_i_in, map_q_in, map_u_in, $
;                                angle_deg, map_i_out, map_q_out, map_u_out
; 
; PURPOSE: 
;        Rotate Stokes maps by angle_deg anti-clockwise
; 
; INPUT: 
;        - map_i_in, map_q_in, map_u_in, angle_deg
; 
; OUTPUT: 
;        - map_i_out, map_q_out, map_u_out
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Dec. 9th, 2018: NP, AA, AR, Ph. A, AM, HH
;-

pro nk_rotate_stokes_maps, map_i_in, map_q_in, map_u_in, $
                           angle_deg, map_i_out, map_q_out, map_u_out 


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_rotate_stokes_maps, map_i_in, map_q_in, map_u_in, $"
   print, "                       angle_deg, map_i_out, map_q_out, map_u_out"
   return
endif
;;;
angle_map = angle_deg - 76.2 + 90. ; correcting offset introduced in nk_elparal2alpha (PhA & HA)

;;;
s = size( map_i_in)
nk_larkin, map_i_in, angle_map, map_i_out
nk_larkin, map_q_in, angle_map, q_map
nk_larkin, map_u_in, angle_map, u_map

;; rotation of axes for QU convention, not image => opposite sign
map_q_out = q_map*cos(2*angle_deg*!dtor) - u_map*sin(2*angle_deg*!dtor)
map_u_out = q_map*sin(2*angle_deg*!dtor) + u_map*cos(2*angle_deg*!dtor)

  
end
