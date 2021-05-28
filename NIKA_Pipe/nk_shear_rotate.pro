pro nk_shear_rotate, beam, theta_deg, beam_theta

s = size(beam)

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_shear_rotate, beam, theta_deg, beam_theta"
   return
endif
  
if abs(theta_deg) le 45.d0 then begin
   nk_shear_rotate_sub, beam, s[1], s[2], theta_deg, beam_theta
endif else begin

   sgn = sign(theta_deg)
   ntheta = long( abs(theta_deg)/45.d0)
   rest = theta_deg - ntheta*sgn*45.d0
   
   junk = beam
   for i=0, ntheta-1 do begin
      nk_shear_rotate_sub, junk, s[1], s[2], sgn*45.d0, beam_theta
      junk = beam_theta
   endfor
   
   nk_shear_rotate_sub, junk, s[1], s[2], rest, beam_theta
endelse

end
