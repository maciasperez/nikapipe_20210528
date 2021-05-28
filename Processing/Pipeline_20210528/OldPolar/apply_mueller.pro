
;; by default, pol_matrix is assumed to in Mueller formalism. If it's in
;; Jones formalism, set /jones to convert it into Mueller form.

pro apply_mueller, stokes_in, alpha_rad, pol_matrix, stokes_out, jones=jones

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "apply_mueller, stokes_in, alpha_rad, pol_matrix, stokes_out, jones=jones"
   return
endif

if keyword_set(jones) then begin
   jones2mueller, pol_matrix, mueller
endif else begin
   mueller = pol_matrix
endelse

;; Limit to I, Q, U, discard V
if n_elements(mueller[*,0]) eq 4 then begin
   mueller = mueller[0:2,0:2]
endif

cos2alpha = cos(2.d0*alpha_rad)
sin2alpha = sin(2.d0*alpha_rad)

;; Need to apply the rotation to stokes_in before applying mueller if
;; stokes_in is not dblarr(1,3)
stokes = stokes_in ; init
stokes[*,1] =  cos2alpha*stokes_in[*,1] + sin2alpha*stokes_in[*,2]
stokes[*,2] = -sin2alpha*stokes_in[*,1] + cos2alpha*stokes_in[*,2]

stokes = mueller##stokes

;; Apply to incoming signal
stokes_out = stokes
stokes_out[*,1] = cos2alpha*stokes[*,1] - sin2alpha*stokes[*,2]
stokes_out[*,2] = sin2alpha*stokes[*,1] + cos2alpha*stokes[*,2]

end
