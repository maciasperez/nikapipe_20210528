
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
;    nk_angleiq_didq
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         r = nk_angleiq_didq(data)
; 
; PURPOSE: 
;        Compute the angle between I,Q vector and dI,dQ vector
;        Define it between -pi and +pi
;        data is the usual structure coming out of read_nika_brute
; 
; INPUT: 
;        - data: the nika data structure
; 
; OUTPUT: 
;        - data.df_tone is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 18 Nov. 2014: FXD: major change to remain compatible between Run8-
;          and Run9+, introduced !nika.sign_angle
;-
;===============================================================================================

function nk_angleiq_didq, data

if n_params() ne 1 then begin
  message, /info, 'Call is : '
  print, 'angle = nk_angleiq_didq( read_struct_data ) ; containing .i, .q, .di, .dq '
  return, -1
endif
; Assumes Run9+ convention by default
if tag_exist( !nika, 'sign_angle') then $
   sign =!nika.sign_angle else sign = +1 

if sign lt 0 then begin  ; tested on Run8 (cannot give saturation for 1mm?)
   anglout = -sign* ( (atan( data.q, data.i) - atan( data.dq, data.di) + $
                      4.*!dpi) mod (2.*!dpi) - 1.5*!dpi) 
endif else begin
   anglout = -sign*( atan( data.q, data.i) - atan( data.dq, data.di) $
                  - (sign* !dpi/2))
endelse 

case strupcase(!nika.acq_version) of
   "V1": begin
      ;; make it between -pi, +pi by adding 2pi or not
      u = where( anglout gt !dpi, nu)
      if nu gt 0 then anglout[u] = anglout[u] - 2.*!dpi
      u = where( anglout lt -!dpi, nu)
      if nu gt 0 then anglout[u] = anglout[u] + 2.*!dpi
   end

   "V2": anglout *= (-1.d0)
   
;;;   "V3": anglout -= !dpi  ; does not work
   "V3": begin  ; FXD this works for V3
      anglout -= !dpi
;; make it between -pi, +pi by adding 2pi or not
      u = where( anglout gt !dpi, nu)
      if nu gt 0 then anglout[u] = anglout[u] - 2.*!dpi
      u = where( anglout lt -!dpi, nu)
      if nu gt 0 then anglout[u] = anglout[u] + 2.*!dpi
   end

   "ISA": begin
      ;; make it between -pi, +pi by adding 2pi or not
      u = where( anglout gt !dpi, nu)
      if nu gt 0 then anglout[u] = anglout[u] - 2.*!dpi
      u = where( anglout lt -!dpi, nu)
      if nu gt 0 then anglout[u] = anglout[u] + 2.*!dpi
   end

   else: begin
      message, /info, "No case defined for !nika.acq_version = "+strupcase(!nika.acq_version)
      stop
   end
endcase

return, anglout


end


