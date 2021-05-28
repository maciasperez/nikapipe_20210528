
pro apply_mueller, stokes_in, alpha_rad, hwp_matrix, stokes_out, jones=jones

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "apply_mueller, stokes_in, alpha_rad, hwp_matrix, stokes_out, jones=jones"
   return
endif

if keyword_set(jones) then begin
   jones2mueller, hwp_matrix, hwp_mueller
endif else begin
   hwp_mueller = hwp_matrix
endelse

;; Limit to I, Q, U, discard V
if n_elements(hwp_mueller[*,0]) eq 4 then begin
   hwp_mueller = hwp_mueller[0:2,0:2]
endif

cos2alpha = cos(2.d0*alpha_rad)
sin2alpha = sin(2.d0*alpha_rad)

;; Need to apply the rotation to stokes_in before applying hwp_mueller if
;; stokes_in is not dblarr(1,3)
stokes = stokes_in ; init
stokes[*,1] =  cos2alpha*stokes_in[*,1] + sin2alpha*stokes_in[*,2]
stokes[*,2] = -sin2alpha*stokes_in[*,1] + cos2alpha*stokes_in[*,2]

stokes = hwp_mueller##stokes

;; Apply to incoming signal
stokes_out = stokes
stokes_out[*,1] = cos2alpha*stokes[*,1] - sin2alpha*stokes[*,2]
stokes_out[*,2] = sin2alpha*stokes[*,1] + cos2alpha*stokes[*,2]

end
